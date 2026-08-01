import 'package:flutter/material.dart';

enum AchievementId {
  total100,
  total1000,
  total10000,
  total100000,
  streak3,
  streak7,
  streak30,
  streak100,
  firstMorningAdhkar,
  firstEveningAdhkar,
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.icon,
  });

  final AchievementId id;
  final String titleAr;
  final String descriptionAr;
  final IconData icon;
}
