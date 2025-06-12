import 'package:flutter/material.dart';

const List<Color> colorList = [
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
  Colors.purple,
  Colors.deepPurple,
  Colors.orange,
  Colors.pink,
  Colors.pinkAccent,
];

class AppTheme {
  final int selectedColor;
  final bool isDarkmode;

  AppTheme({
    this.selectedColor = 0,
    this.isDarkmode = true, 
  }): assert(
    selectedColor >= 0 || selectedColor < colorList.length,
    'Selected color must be greater than 0 and less than maximum'
  );

  ThemeData getTheme() => ThemeData(
    useMaterial3: true,
    brightness: isDarkmode? Brightness.dark : Brightness.light,
    colorSchemeSeed: colorList[selectedColor],
    appBarTheme: const AppBarTheme(
      centerTitle: true,
    ),
  );

  AppTheme copyWith(
    int? selectedColor,
    bool? isDarkmode, 
  ) => AppTheme(
    selectedColor: selectedColor ?? this.selectedColor,
    isDarkmode: isDarkmode ?? this.isDarkmode,
  );

}