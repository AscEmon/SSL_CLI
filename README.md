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


### Now, You can easily create repository based module using this below command. Please remember create this command from root of the project.

    ssl_cli module <module_name>
### You can effortlessly generate Bloc Pattern Architecture and Bloc Pattern Module using this CLI.

### You can effortlessly generate **_k_assets.dart_** file containing all your asset paths using this command. Please remember create this command from root of the project.

    ssl_cli generate k_assets.dart


> **_NOTE :_**  Ensure to re run this command whenever new assets are added. This updates the **_k_assets.dart_** file with the latest asset paths.

### Effortlessly build APK with flavorType without adding any third-party packages. The generated APK will have a modified name like app_name_flavorType_versionName_versionCode.

    ssl_cli build apk --flavorType 

> **_NOTE :_**  available flavorType is --DEV, --LIVE, --LOCAL , --STAGE



### If you want to set up flavor with Dart Define in your existing project, simply use the following command: 

    ssl_cli setup --flavor

> **_NOTE :_**  This setup will work whether your project structure is built with ssl_cli or without ssl_cli. Don't hesitate; use this command to modify your APK name and save time.

### Now, most importantly, you can easily send your APK to Telegram automatically after building it. Just add --t. If you include this flag, the APK will be automatically sent to the Telegram group.

    ssl_cli build apk --flavorType --t



> **_NOTE :_** Please add your Telegram chat ID and botToken to the config.json file. If you don't have them, follow these steps:

1. Go to Telegram and search for BotFather. Type /start, and it will prompt you for some information. After providing the information, it will give you a botToken. Copy the token and paste it into the config.json file.

2. If you want to share your APK automatically, add your bot to the group as an admin and enable all necessary permissions.

3. After adding the bot to the group as admin, send a dummy message in that group and hit the following link in the browser:
 
 https://api.telegram.org/bot<yourBotToken>/getUpdates
 
 You will get the group chat ID. Copy the ID and paste it into the config.json file.

4. All setup is done. Now you can easily send your APK to Telegram using just a single command.  



## 🌟 New Addition 🌟

You can create effortless documentation using AI for your project using this command.

    ssl_cli generate <filepath or folderpath> 