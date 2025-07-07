import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final redTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xffee3124),
    primary: Color(0xffee3124),
    onPrimary: Colors.white,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
  fontFamily: GoogleFonts.poppins().fontFamily,
);
