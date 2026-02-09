import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const BoxShadow card = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 8,
    color: Colors.black12,
  );

  static const BoxShadow elevated = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 16,
    color: Color(0x29000000), // ~16% black
  );

  static const BoxShadow subtle = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 4,
    color: Color(0x0F000000), // ~6% black
  );

  static const List<BoxShadow> cardShadow = [card];
  static const List<BoxShadow> elevatedShadow = [elevated];
  static const List<BoxShadow> subtleShadow = [subtle];

  static const List<BoxShadow> none = [];
}
