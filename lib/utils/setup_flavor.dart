import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';

import 'enum.dart';

class SetupFlavor {
  void appBuildGradleEditFunc() {
    String filePath = "${Directory.current.path}/android/app/build.gradle";
    try {
      // Read the content of the file
      final file = File(filePath);
      List<String> lines = file.readAsLinesSync();

      final int applyFormIndex = lines.indexOf(
          "def localPropertiesFile = rootProject.file('local.properties')");

      // Check if the line is found
      if (applyFormIndex != -1) {
        // Define the Groovy code to be added before the 'android {'
        final additionalCode = '''
def dartEnvironmentVariables = [
    APP_FLAVOR: ''
];

if (project.hasProperty('dart-defines')) {

    dartEnvironmentVariables = dartEnvironmentVariables + 
    project.property('dart-defines')
            .split(',')
            .collectEntries { entry ->
                def pair = new String(entry.decodeBase64(), 'UTF-8').split('=')
                if (pair.first() == 'mode') {
                    switch (pair.last()) {
                         case 'DEV':
                            project.ext.APP_FLAVOR = "DEV"
                            break
                         case 'LIVE':
                            project.ext.APP_FLAVOR = "LIVE"
                            break
                         case 'STAGE':
                            project.ext.APP_FLAVOR = "STAGE"
                            break
                         case 'LOCAL':
                            project.ext.APP_FLAVOR = "LOCAL"
                            break
                    }
                }
                [(pair.first()): pair.last()]
            }

}
def renamePath = { outputFileName ->
 gradle.projectsEvaluated {
     // Rename flutter-apk directory after projects are configured
     tasks.whenObjectAdded{ task ->
     task.doLast {
           def flutterApkDir = new File("\${project.buildDir}/outputs/flutter-apk/app-release.apk")
           if (flutterApkDir.exists()) {
             flutterApkDir.renameTo(new File("\${project.buildDir}/outputs/flutter-apk/\$outputFileName"))
            }
      
         }
     }
  }
}

def appFlavor() {
  if (project.hasProperty('APP_FLAVOR')) {
    return "\${project.ext.APP_FLAVOR}_"
  } 
}
''';

        // Insert the additional code at the beginning of the file
        lines.insert(applyFormIndex + 1, additionalCode);
        file.writeAsStringSync(lines.join('\n'));

        // Find the index of the line that contains 'signingConfig' and 'debug'
        int index = lines.indexWhere(
            (line) => line.contains('signingConfig') && line.contains('debug'));

        // Check if the line is found
        if (index != -1) {
          // Define the code to be added after the specified line
          final additionalCode = '''
            android.applicationVariants.all { variant ->
                variant.outputs.all {
                    if(appFlavor() != null){
                         def appName = variant.getMergedFlavor().applicationId
                         int lastIndex = appName.lastIndexOf('.')
                         def modifiedAppName = lastIndex != -1 ? appName.substring(lastIndex + 1) : appName
                         outputFileName = "\${modifiedAppName}_\${appFlavor()}\${flutterVersionName}(\${flutterVersionCode}).apk"
                         renamePath(outputFileName)
                        
                    }
                }
            }
        ''';

          // Insert the additional code after the specified line
          lines.insert(index + 1, additionalCode);

          // Write the modified content back to the file
          file.writeAsStringSync(lines.join('\n'));
          'ssl_cli build setup successfully.'
              .printWithColor(status: PrintType.success);
        } else {
          'Error: Line pattern not found in the specified file.'
              .printWithColor(status: PrintType.error);
        }
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
    // Read the content of the file
    List<String> lines = file.readAsLinesSync();
    int initServicesIndex = lines.indexOf("initServices() async {");
    if (initServicesIndex == -1) {
      isSSLCLIProject = false;
      initServicesIndex = lines.indexOf("void main() {");
    }

    // Dart code to check for existence
    String codeSnippet1 = 'AppUrlExtention.setUrl(UrlLink.isDev);';
    final codeSnippet2 = '''
  const mode = String.fromEnvironment('mode', defaultValue: 'DEV');
  // Please setup your url based on this configuration
  AppUrlExtention.setUrl(
    mode == "DEV" ? UrlLink.isDev : UrlLink.isLive,
  );
  ''';
    final codeSnippet3 = '''
  const mode = String.fromEnvironment('mode', defaultValue: 'DEV');
  // Please setup your url based on this configuration
  if(mode == "LIVE"){
    // set your production based url
  }else if (mode=="DEV"){
     // set your development based url
  }
  ''';
    if (isSSLCLIProject == false) {
      setupProjectSnippet = codeSnippet3;
    } else {
      setupProjectSnippet = codeSnippet2;
    }

    // Check if the code snippets already exist
    int index1 = lines.indexWhere((line) => line.trim() == codeSnippet1.trim());
    int index2 = lines.join('\n').contains(setupProjectSnippet.trim()) ? 1 : -1;

    if (index1 != -1) {
      // Replace the existing code snippet 1
      lines[index1] = setupProjectSnippet;

      // Write the updated content back to the file
      file.writeAsStringSync(lines.join('\n'));
    } else {
      if (index2 == -1) {
        // Check if code snippet 2 is not present
        final int index = lines
            .indexWhere((line) => line.trim() == 'final flavorCode = \'\'\'');

        if (index != -1) {
          // Replace the existing code snippet 2
          lines.replaceRange(
              index + 1, index + 7, setupProjectSnippet.split('\n'));
        } else {
          // Add the code snippet 2 at the end
          lines.insert(initServicesIndex + 1, setupProjectSnippet);
        }

        // Write the updated content back to the file
        file.writeAsStringSync(lines.join('\n'));
      }
    }
  }
}
