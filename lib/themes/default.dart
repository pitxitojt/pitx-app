import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final defaultTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xff1d439b),
    primary: Color(0xff1d439b),
    onPrimary: Colors.white,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
  fontFamily: GoogleFonts.poppins().fontFamily,
);
