import 'dart:io';

import 'package:ssl_cli/utils/extension.dart';
import 'enum.dart';

class SetupFlavor {
  void appBuildGradleEditFunc() {
    try {
      final filePath = "${Directory.current.path}/android/app/build.gradle";
      final file = File(filePath);
      List<String> lines = file.readAsLinesSync();

      final int applyFormIndex = lines.indexWhere(
          (line) => line.contains('id "dev.flutter.flutter-gradle-plugin"'));

      if (applyFormIndex != -1) {
        final additionalCode = '''
def dartEnvironmentVariables = [
    APP_FLAVOR: project.hasProperty('mode')
];

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

def renamePath = { outputFileName ->
  gradle.projectsEvaluated {
    tasks.whenObjectAdded { task ->
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

        lines.insert(applyFormIndex + 2, additionalCode);
        file.writeAsStringSync(lines.join('\n'));

        int index = lines.indexWhere(
            (line) => line.contains('signingConfig') && line.contains('debug'));

        if (index != -1) {
          final additionalCode = '''
            android.applicationVariants.all { variant ->
                variant.outputs.all {
                    if(appFlavor() != null){
                         def appName = variant.getMergedFlavor().applicationId
                         int lastIndex = appName.lastIndexOf('.')
                         def modifiedAppName = lastIndex != -1 ? appName.substring(lastIndex + 1) : appName
                         outputFileName = "\${modifiedAppName}_\${appFlavor()}\${flutter.versionName}(\${flutter.versionCode}).apk"
                         renamePath(outputFileName)
                    }
                }
            }
        ''';

          lines.insert(index + 1, additionalCode);
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
