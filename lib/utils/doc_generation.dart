import 'dart:convert';
import 'dart:io';

class DocGenerator {
  final String configFilePath;
  final String outputFile;

  DocGenerator({
    this.configFilePath = "config.json",
    this.outputFile = "README.md",
  });

  /// Main entry function
  Future<void> generateDocs(String path) async {
    FileSystemEntity? entity = _getFileSystemEntity(path);
    if (entity == null) return;

    int choice = _getUserApiChoice();
    if (choice == 0) return;

    List<File> dartFiles = _getDartFiles(entity);
    if (dartFiles.isEmpty) {
      print("⚠️ No Dart files found.");
      return;
    }
    String apiKey = _getApiKey(choice);

    if (apiKey.isEmpty) {
      print("❌ Error: API key not found.");
      return;
    }
    
    List<String> documentation = [];
    for (File file in dartFiles) {
      print("📂 Processing: ${file.path}");
      String content = file.readAsStringSync();
      String doc = await _generateDocumentation(content, choice);
      documentation.add("## ${file.path}\n\n$doc\n");
    }

    _saveAsMarkdown(documentation.join("\n---\n"));
    print("📜 Documentation updated in `$outputFile`!");
  }

  /// Get all Dart files from a directory recursively
  List<File> _getDartFiles(FileSystemEntity entity) {
    if (entity is File && entity.path.endsWith(".dart")) {
      return [entity];
    } else if (entity is Directory) {
      return entity
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith(".dart"))
          .toList();
    }
    print("⚠️ Not a valid Dart file or folder.");
    return [];
  }

  /// Generate documentation using the selected AI API
  Future<String> _generateDocumentation(String codeSnippet, int choice) async {
    String prompt = '''
      Generate simple and clear documentation for the following methods and functions. 
      Use this code:\n\n$codeSnippet
      Format:\n\n
      **Method Name:** 
      **Parameters:** 
      **Logic Details:** Explain the main logic in simple terms.
    ''';

    String apiKey = _getApiKey(choice);
    String url = _getApiUrl(choice, apiKey);
    if (apiKey.isEmpty) {
      return "Error: API key not found.";
    } else if (url.isEmpty) {
      return "Error: Invalid API choice.";
    }

    print("🤖 Generating documentation...");

    final requestBody = choice == 2
        ? jsonEncode({
            "model": "gpt-4",
            "messages": [
              {"role": "system", "content": "You are a helpful assistant."},
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.7
          })
        : jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ]
          });

    try {
      final response = await _sendHttpRequest(url, requestBody, choice, apiKey);
      return _extractResponse(response, choice);
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Save generated documentation, ensuring new content appears at the top
  void _saveAsMarkdown(String newContent) {
    File file = File(outputFile);
    String oldContent = file.existsSync() ? file.readAsStringSync() : "";

    // Ensure title is added only once
    String title = "# AI-Generated Documentation\n\n";
    if (!oldContent.startsWith(title)) {
      oldContent = "$title$oldContent";
    }

    String updatedContent =
        "$title$newContent\n\n---\n$oldContent".replaceFirst(title, title);
    file.writeAsStringSync(updatedContent, mode: FileMode.write);
  }

  /// Reads API key from config.json
  String _getApiKey(int choice) {
    File configFile = File(configFilePath);
    if (!configFile.existsSync()) {
      print("❌ Error: `$configFilePath` not found! Please create one.");
      exit(1);
    }

    try {
      Map<String, dynamic> config = jsonDecode(configFile.readAsStringSync());
      String key = choice == 1
          ? "geminiApiKey"
          : choice == 2
              ? "openAiApiKey"
              : "deepSeekApiKey";

      return config[key] ?? "";
    } catch (e) {
      print(
          "❌ Error: Failed to read `$configFilePath`. Ensure it's valid JSON.");
      exit(1);
    }
  }

  /// Get API URL based on user choice
  String _getApiUrl(int choice, String apiKey) {
    if (choice == 1) {
      return "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";
    } else if (choice == 2) {
      return "https://api.openai.com/v1/chat/completions";
    } else if (choice == 3) {
      return "https://api.deepseek.com/v1/completions";
    }
    return "";
  }

  /// Send HTTP request
  Future<String> _sendHttpRequest(
      String url, String requestBody, int choice, String apiKey) async {
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.postUrl(Uri.parse(url));
    request.headers.set("Content-Type", "application/json");
    if (choice == 2 || choice == 3) {
      request.headers.set("Authorization", "Bearer $apiKey");
    }
    request.add(utf8.encode(requestBody));

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();
    client.close();
    return responseBody;
  }

  /// Extract response from API
  String _extractResponse(String responseBody, int choice) {
    final jsonResponse = jsonDecode(responseBody);
    if (choice == 1) {
      return jsonResponse["candidates"]?[0]["content"]["parts"]?[0]["text"] ??
          "Error: No content.";
    } else if (choice == 2) {
      return jsonResponse["choices"]?[0]["message"]["content"] ??
          "Error: No content.";
    } else if (choice == 3) {
      return jsonResponse["choices"]?[0]["text"] ?? "Error: No content.";
    }
    return "Error: Invalid response.";
  }

  /// Get file or folder entity
  FileSystemEntity? _getFileSystemEntity(String path) {
    FileSystemEntityType type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      print("❌ File or folder not found!");
      return null;
    }
    return type == FileSystemEntityType.file ? File(path) : Directory(path);
  }

  /// Ask the user which API to use
  int _getUserApiChoice() {
    print("Select an AI API for documentation generation:");
    print("1. Gemini (Google)");
    print("2. OpenAI (GPT-4)");
    print("3. DeepSeek");
    stdout.write("Enter your choice (1/2/3): ");
    String? input = stdin.readLineSync();

    if (["1", "2", "3"].contains(input)) return int.parse(input!);
    print("❌ Invalid choice! Please enter 1, 2, or 3.");
    return 0;
  }
}
