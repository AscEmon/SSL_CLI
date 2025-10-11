import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';
import 'enum.dart';

class SetupFlavor {
  void appBuildGradleEditFunc() {
    try {
      // Check for both Groovy and Kotlin DSL build files
      final groovyPath = "${Directory.current.path}/android/app/build.gradle";
      final kotlinPath =
          "${Directory.current.path}/android/app/build.gradle.kts";

      File? file;
      bool isKotlinDsl = false;

      if (File(kotlinPath).existsSync()) {
        file = File(kotlinPath);
        isKotlinDsl = true;
      } else if (File(groovyPath).existsSync()) {
        file = File(groovyPath);
        isKotlinDsl = false;
      } else {
        'Error: Neither build.gradle nor build.gradle.kts found.'
            .printWithColor(status: PrintType.error);
        return;
      }

      List<String> lines = file.readAsLinesSync();

      // Find the plugin declaration line
      final int applyFormIndex = isKotlinDsl
          ? lines.indexWhere((line) =>
              line.contains('id("dev.flutter.flutter-gradle-plugin")'))
          : lines.indexWhere((line) =>
              line.contains('id "dev.flutter.flutter-gradle-plugin"'));

      if (applyFormIndex != -1) {
        // Different code for Kotlin DSL vs Groovy
        final additionalCode = isKotlinDsl ? '''

import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

// Load key.properties for signing configuration
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Dart environment variables setup
val dartEnvironmentVariables = mutableMapOf<String, String>()

if (project.hasProperty("dart-defines")) {
    val dartDefines = project.property("dart-defines") as String
    dartDefines.split(",").forEach { entry ->
        val pair = String(Base64.getDecoder().decode(entry)).split("=")
        if (pair.size == 2) {
            dartEnvironmentVariables[pair[0]] = pair[1]
            if (pair[0] == "mode") {
                project.extra["APP_FLAVOR"] = pair[1]
            }
        }
    }
}

fun getAppFlavor(): String {
    return if (project.extra.has("APP_FLAVOR")) {
        "\${project.extra["APP_FLAVOR"]}_"
    } else {
        ""
    }
}
''' : '''

// Load key.properties for signing configuration
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

def dartEnvironmentVariables = [
    APP_FLAVOR: project.hasProperty('mode')
]

if (project.hasProperty('dart-defines')) {
    dartEnvironmentVariables = dartEnvironmentVariables +
        project.property('dart-defines')
            .split(',')
            .collectEntries { entry ->
                def pair = new String(entry.decodeBase64(), 'UTF-8').split('=')
                if (pair.first() == 'mode') {
                  project.ext.APP_FLAVOR = pair.last()
                }
                [(pair.first()): pair.last()]
            }
}

def appFlavor() {
  if (project.hasProperty('APP_FLAVOR')) {
    return "\${project.ext.APP_FLAVOR}_"
  }
}
''';

        // Insert after the plugins block (after closing brace)
        int insertIndex = applyFormIndex;
        // Find the closing brace of plugins block
        for (int i = applyFormIndex; i < lines.length; i++) {
          if (lines[i].trim() == '}') {
            insertIndex = i;
            break;
          }
        }

        lines.insert(insertIndex + 1, additionalCode);
        file.writeAsStringSync(lines.join('\n'));

        // Reload lines after first modification
        lines = file.readAsLinesSync();

        // Find defaultConfig closing brace to add signingConfigs
        int defaultConfigEnd = -1;
        
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('defaultConfig')) {
            int braceCount = 0;
            for (int j = i; j < lines.length; j++) {
              if (lines[j].contains('{')) braceCount++;
              if (lines[j].contains('}')) {
                braceCount--;
                if (braceCount == 0) {
                  defaultConfigEnd = j;
                  break;
                }
              }
            }
            break;
          }
        }
        
        if (defaultConfigEnd != -1) {
          final signingConfigCode = isKotlinDsl ? '''

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
''' : '''

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
''';
          
          lines.insert(defaultConfigEnd + 1, signingConfigCode);
          file.writeAsStringSync(lines.join('\n'));
          lines = file.readAsLinesSync();
        }

        // Find and replace signingConfig line in buildTypes
        int signingConfigIndex = isKotlinDsl
            ? lines.indexWhere((line) =>
                line.contains('signingConfig') &&
                line.contains('=') &&
                line.contains('debug'))
            : lines.indexWhere((line) =>
                line.contains('signingConfig') && line.contains('debug'));

        if (signingConfigIndex != -1) {
          final newSigningConfig = isKotlinDsl
              ? '''            // Use release signing config if key.properties exists, otherwise use debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }'''
              : '''            // Use release signing config if key.properties exists, otherwise use debug
            signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug''';
          
          lines[signingConfigIndex] = newSigningConfig;
          file.writeAsStringSync(lines.join('\n'));
          lines = file.readAsLinesSync();
        }

        // Find buildTypes closing brace to add APK renaming logic
        int buildTypesEnd = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('buildTypes')) {
            int braceCount = 0;
            for (int j = i; j < lines.length; j++) {
              if (lines[j].contains('{')) braceCount++;
              if (lines[j].contains('}')) {
                braceCount--;
                if (braceCount == 0) {
                  buildTypesEnd = j;
                  break;
                }
              }
            }
            break;
          }
        }

        if (buildTypesEnd != -1) {
          final apkRenameCode = isKotlinDsl ? '''
}

// Copy and rename APK based on flavor after build
gradle.buildFinished {
    val flavor = getAppFlavor()
    if (flavor.isNotEmpty()) {
        val flutterApkDir = File("\${project.buildDir}/outputs/flutter-apk")
        val apkOutputDir = File("\${project.buildDir}/outputs/apk")
        
        listOf(flutterApkDir, apkOutputDir).forEach { dir ->
            if (dir.exists()) {
                dir.walk().forEach { file ->
                    if (file.isFile && file.extension == "apk" && !file.name.contains("_\${flavor}")) {
                        val appName = android.namespace?.substringAfterLast(".") ?: "app"
                        val versionName = android.defaultConfig.versionName ?: "1.0.0"
                        val versionCode = android.defaultConfig.versionCode ?: 1
                        val newName = "\${appName}_\${flavor}\${versionName}(\${versionCode}).apk"
                        val newFile = File(file.parent, newName)
                        file.copyTo(newFile, overwrite = true)
                    }
                }
            }
        }
    }
}''' : '''
}

    android.applicationVariants.all { variant ->
        variant.outputs.all {
            if(appFlavor() != null){
                 def appName = variant.getMergedFlavor().applicationId
                 int lastIndex = appName.lastIndexOf('.')
                 def modifiedAppName = lastIndex != -1 ? appName.substring(lastIndex + 1) : appName
                 outputFileName = "\${modifiedAppName}_\${appFlavor()}\${versionName}(\${versionCode}).apk"
                 renamePath(outputFileName)
            }
        }
    }
''';

          lines[buildTypesEnd] = apkRenameCode;
          file.writeAsStringSync(lines.join('\n'));
          'ssl_cli build setup successfully.'
              .printWithColor(status: PrintType.success);
        } else {
          'Error: buildTypes block not found in the specified file.'
              .printWithColor(status: PrintType.error);
        }
      } else {
        'Error: Flutter Gradle Plugin declaration not found.'
            .printWithColor(status: PrintType.error);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void createConfigFile() async {
    try {
      final file = await File("${Directory.current.path}/config.json").create();

      final writer = file.openWrite();
      writer.write('''
{
    "telegram_chat_id": "",
    "botToken": ""
}

''');
      writer.close();
    } catch (_) {
      stderr.write('creating config.json failed!');
      exit(2);
    }
  }

  void mainEdit() {
    final file = File("${Directory.current.path}/lib/main.dart");
    bool isSSLCLIProject = true;
    String setupProjectSnippet = '';
    List<String> lines = file.readAsLinesSync();

    int initServicesIndex = lines.indexOf("initServices() async {");
    if (initServicesIndex == -1) {
      isSSLCLIProject = false;
      initServicesIndex = lines.indexOf("void main() {");
    }

    String codeSnippet1 = 'AppUrlExtention.setUrl(UrlLink.isDev);';
    final codeSnippet2 = '''
  const mode = String.fromEnvironment('mode', defaultValue: 'DEV');
  AppUrlExtention.setUrl(
    mode == "DEV" ? UrlLink.isDev : UrlLink.isLive,
  );
  ''';
    final codeSnippet3 = '''
  const mode = String.fromEnvironment('mode', defaultValue: 'DEV');
  if(mode == "LIVE"){
    // set your production based url
  } else if (mode == "DEV") {
     // set your development based url
  }
  ''';

    setupProjectSnippet = isSSLCLIProject ? codeSnippet2 : codeSnippet3;

    int index1 = lines.indexWhere((line) => line.trim() == codeSnippet1.trim());
    int index2 = lines.join('\n').contains(setupProjectSnippet.trim()) ? 1 : -1;

    if (index1 != -1) {
      lines[index1] = setupProjectSnippet;
      file.writeAsStringSync(lines.join('\n'));
    } else {
      if (index2 == -1) {
        final int index = lines
            .indexWhere((line) => line.trim() == 'final flavorCode = \'\'\'');

        if (index != -1) {
          lines.replaceRange(
              index + 1, index + 7, setupProjectSnippet.split('\n'));
        } else {
          lines.insert(initServicesIndex + 1, setupProjectSnippet);
        }

        file.writeAsStringSync(lines.join('\n'));
      }
    }
  }
}
