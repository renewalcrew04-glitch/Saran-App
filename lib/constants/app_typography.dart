import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const body = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AppColors.black,
    fontWeight: FontWeight.w500,
  );

  static const title = TextStyle(
    fontSize: 16,
    color: AppColors.black,
    fontWeight: FontWeight.w800,
  );

  static const small = TextStyle(
    fontSize: 12,
    color: AppColors.greyText,
    fontWeight: FontWeight.w500,
  );
}
