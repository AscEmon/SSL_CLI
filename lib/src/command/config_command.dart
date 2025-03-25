import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:ssl_cli/src/command/i_command.dart';
import 'package:ssl_cli/utils/color_extension.dart';

class ConfigCommand implements ICommand {
  final bool isOverride;

  ConfigCommand({this.isOverride = false});

  @override
  void execute() {
    try {
      final defaultConfigPath =
          path.join(Directory.current.path, 'config.json');
      final defaultConfigFile = File(defaultConfigPath);

      if (!defaultConfigFile.existsSync()) {
        print('❌ No config.json file found in the current directory.'.red);
        return;
      }

      // Create a backup of the existing config file
      final backupPath =
          path.join(Directory.current.path, 'config.json.backup');
      defaultConfigFile.copySync(backupPath);

      // Create new config.json with default values
      final Map<String, dynamic> defaultConfig = {
        'botToken': '',
        'chatId': '',
        'telegram_chat_id': ''
      };

      final Map<String, dynamic> aiConfig = {
        'geminiApiKey': '',
        'openAiApiKey': '',
        'deepSeekApiKey': '',
        'geminiModelName': ''
      };

      if (isOverride) {
        // Read existing config if it exists
        final existingConfig = Map<String, dynamic>.from(
            json.decode(defaultConfigFile.readAsStringSync()));
        
        // Preserve existing values
        if (existingConfig.containsKey('telegram_chat_id')) {
          existingConfig['chatId'] = existingConfig['telegram_chat_id'];
        }
        
        // Merge existing config with new AI config
        existingConfig.addAll(aiConfig);
        
        // Remove old keys
        existingConfig.remove('telegram_chat_id');
        defaultConfigFile.writeAsStringSync(
            JsonEncoder.withIndent('  ').convert(existingConfig));
        print('✅ Successfully added AI configuration to existing config.json.'
            .green);
        print(
            '📝 A backup of your previous config has been saved as config.json.backup'
                .yellow);
        return;
      }

      // For regular config command, create new config with default values
      final newConfig = {...defaultConfig, ...aiConfig};

      defaultConfigFile
          .writeAsStringSync(JsonEncoder.withIndent('  ').convert(newConfig));
      print('✅ Successfully created new config.json with all configurations.'
          .green);
      print(
          '📝 A backup of your previous config has been saved as config.json.backup'
              .yellow);
    } catch (e) {
      print('❌ Error modifying config.json: $e'.red);
    }
  }
}
