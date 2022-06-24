#### `ssl_cli` is a simple command line tool to generate folder and file structure for your Flutter apps. 

#### To use it, you should do the following things:


##### 1. Firstly, you should create a flutter project

    flutter create <project_name>

After that,Go to root of this project and open your terminal.
 
##### 2. Now, you should activate dart cli to run it globally and set your path in your respected system:

    dart pub global activate ssl_cli
 
 After successful activation, you can use it.
 N:B: If you are the first time user of this cli then you should set your path in your system. If already set up in your path then you can skip this process
  1.For windows user set the path in your system variables
  2.For Mac user set the path in your  ~/.zshrc file
  3.For linux user set the path in your  ~/.bashrc file

##### 3. Ensure that, you are in the your Flutter root project directory, because it will generate Asset and other localization folders and files under the root project folder. Then write a simple command to generate:
    
    ssl_cli create <project_name>

##### 4. As we generate localization using this cli thats why we need some configuration.

### Write now we are dependent some packages thats why we need to add this packages in our pubspec.yaml file. Please enusre that use latest version of this packages
  google_fonts: 
  intl: 
  dio: 
  shared_preferences: 

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
  N:B: Remember it will only generate when we restart our application
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
    

