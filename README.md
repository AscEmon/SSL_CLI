#### `ssl_cli` is a simple command line tool to generate folder and file structure for your Flutter apps.

#### To use it, you should do the following things:

##### 1. Firstly, you should create a flutter project

    flutter create <project_name>

After that,Go to root of this project and open your terminal.

##### 2. Now, you should activate dart cli to run it globally and set your path in your respected system:

    dart pub global activate ssl_cli

After successful activation, you can use it.

> #### If you are the first time user of this cli then you should set your path in your system. If already set up in your path then you can skip this process
>
> - For windows user set the path in your system variables
> - For Mac user set the path in your ~/.zshrc file
> - For linux user set the path in your ~/.bashrc file

##### 3. Ensure that, you are in the your Flutter root project directory, because it will generate Asset and other localization folders and files under the root project folder. Then write a simple command to generate:

    ssl_cli create <project_name>


##### 4. As we generate localization using this cli thats why we need some configuration.

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


  #It will be generate automatically localized file when we added new text in arb file.
  #N:B: Remember it will only generate when we restart our application
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

### Now, You can easily create repository based module using this below command. Please remember create this command from root of the project.

    ssl_cli module <module_name>

### Now, You can easily create repository based module using this below command. Please remember create this command from root of the project.

    ssl_cli module <module_name>


## 🌟 New Addition 🌟
### You can effortlessly generate **_k_assets.dart_** file containing all your asset paths using this command. Please remember create this command from root of the project.

    ssl_cli generate k_assets.dart


> **_NOTE :_**  Ensure to re run this command whenever new assets are added. This updates the **_k_assets.dart_** file with the latest asset paths.
