#### `ssl_cli` is a simple command line tool to generate folder and file structure for your Flutter apps. 

#### To use it, you should do the followings:

##### 1. Firstly, you should activate dart cli to run it globally and set your path in your respected system:

    dart pub global activate ssl_cli
 
 After successful activation, you can use it.

##### 2. Ensure that, you are in the your Flutter root project directory, because it will generate Asset and other localization folders and files under the root project folder. Then write a simple command to generate:
    
    ssl_cli create <project_name>


### As we generate localization using this cli thats why we need some configuration.


### Add this below code in pubspec.yaml

```
dependencies:
  flutter:
    sdk: flutter

  #this line is added for localization 
  flutter_localizations:
    sdk: flutter
```


   
```
flutter:


  #it will be generate automatically localized file when we added new text in arb file. 
  #Remember it will only generate when we restart our application
  generate: true
  uses-material-design: true

```

### For iOS localization is required to add this below code in dict tag in info.plist

```
 <key>CFBundleLocalizations</key>
 	<array>
 		<string>en</string>
 		<string>sv</string>
 	</array>
```


### For the generation of the **_k_assets.dart_** file, containing all your asset paths, use this command.

    ssl_cli generate k_assets.dart


> **_NOTE :_**  Ensure to re run this command whenever new assets are added. This updates the **_k_assets.dart_** file with the latest asset paths.
    

