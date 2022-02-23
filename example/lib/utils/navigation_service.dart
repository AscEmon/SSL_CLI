import 'package:flutter/material.dart';

extension Navigation on Widget {
  static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Holds the information about parent context
  /// For example when navigation from Screen A to Screen B
  /// we can access context of Screen A from Screen B to check if it
  /// came from Screen A. So we can trigger different logic depending on
  /// which screen we navigated from.
    

  //it will navigate you to one screen to another
  Future push(context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => this),
    );
  }
   

  //it will pop all the screen  and take you to the new screen
  //E:g : when you will goto the login to home page then you will use this 
  Future pushAndRemoveUntil(context) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => this),
      (route) => false,
    );
  }



  //It will replace the screen with current screen 
  //E:g :  screen A 
  //  GestureDetector(
        // onTap: (){
        //   ScreenB().pushReplacement
        // },
  // it means screen B replace in screen A .
  //if you pressed back then you will not find screen A. it remove from stack

  Future pushReplacement(context, {String? routeName}) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: (BuildContext context) => this),
    );
  }

  //it will pop all the screen and take you to the first screen of the stack
  //that means you will go to the Home page
  Future pushAndRemoveSpecificScreen(context) {
    return Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => this),
        (route) => route.isFirst);
  }

  // when you remove previous x count of  route
  //from stack then please use this way
  //E.g : if you remove 3 route from stack then pass the argument to 3
  static popUntil(context, int removeProviousPage) {
    int screenPop = 0;
    return Navigator.of(context)
        .popUntil((_) => screenPop++ >= removeProviousPage);
  }

  //Remove single page from stack
  static void pop(context) {
    return Navigator.pop(context);
  }
}
