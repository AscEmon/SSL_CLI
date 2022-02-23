import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_test/utils/styles/styles.dart';

class KTextStyle {
  static TextStyle headLine3 = GoogleFonts.quicksand(
    fontSize: 42.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle headLine4 = GoogleFonts.quicksand(
    fontSize: 32.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle buttonText({fontWeight = FontWeight.normal}) => GoogleFonts.quicksand(
        fontSize:27.sp,
        fontWeight: fontWeight,
      );

  /// Normal Texts
  static TextStyle bodyText1() => GoogleFonts.quicksand(
        fontSize: 27.sp,
        fontWeight: FontWeight.normal,
      );

  static TextStyle bodyText2() => GoogleFonts.quicksand(
        fontSize: 24.sp,
        fontWeight: FontWeight.w500,
      );

  static TextStyle bodyText3() => GoogleFonts.quicksand(
        fontSize: 22.sp,
        fontWeight: FontWeight.normal,
      );

  /// Subtitles
  static TextStyle subtitle1 =const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  static TextStyle subtitle2 =const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
}
