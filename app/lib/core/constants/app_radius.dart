import 'package:flutter/material.dart';

abstract final class AppRadius {
  // Raw values
  static const double smValue = 8;
  static const double mdValue = 12;
  static const double lgValue = 16;
  static const double xlValue = 24;

  // BorderRadius
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius circular = BorderRadius.all(Radius.circular(999));

  // Top-only (for bottom sheets, modal headers)
  static const BorderRadius topMd = BorderRadius.only(
    topLeft: Radius.circular(mdValue),
    topRight: Radius.circular(mdValue),
  );
  static const BorderRadius topLg = BorderRadius.only(
    topLeft: Radius.circular(lgValue),
    topRight: Radius.circular(lgValue),
  );
  static const BorderRadius topXl = BorderRadius.only(
    topLeft: Radius.circular(xlValue),
    topRight: Radius.circular(xlValue),
  );

  // RoundedRectangleBorder helpers (for Material widgets)
  static RoundedRectangleBorder get shapeSm => const RoundedRectangleBorder(borderRadius: sm);
  static RoundedRectangleBorder get shapeMd => const RoundedRectangleBorder(borderRadius: md);
  static RoundedRectangleBorder get shapeLg => const RoundedRectangleBorder(borderRadius: lg);
  static RoundedRectangleBorder get shapeXl => const RoundedRectangleBorder(borderRadius: xl);
}
