import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double inputsButtons = 12.0;
  static const double cards = 16.0;
  static const double large = 16.0;

  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius inputButtonRadius = BorderRadius.all(
    Radius.circular(inputsButtons),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(cards),
  );
  static const BorderRadius largeRadius = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(999.0),
  );
}
