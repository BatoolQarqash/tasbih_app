import 'package:flutter/material.dart';
import '../models/achievement.dart';

const List<AchievementDef> achievementsData = [
  AchievementDef(
    id: AchievementId.total100,
    titleAr: 'أول مئة',
    descriptionAr: 'أتممت 100 تسبيحة إجمالاً',
    icon: Icons.looks_one_outlined,
  ),
  AchievementDef(
    id: AchievementId.total1000,
    titleAr: 'ألف تسبيحة',
    descriptionAr: 'أتممت 1,000 تسبيحة إجمالاً',
    icon: Icons.star_border,
  ),
  AchievementDef(
    id: AchievementId.total10000,
    titleAr: 'عشرة آلاف',
    descriptionAr: 'أتممت 10,000 تسبيحة إجمالاً',
    icon: Icons.stars,
  ),
  AchievementDef(
    id: AchievementId.total100000,
    titleAr: 'مئة ألف',
    descriptionAr: 'أتممت 100,000 تسبيحة إجمالاً',
    icon: Icons.workspace_premium,
  ),
  AchievementDef(
    id: AchievementId.streak3,
    titleAr: 'استمرارية 3 أيام',
    descriptionAr: 'حافظت على الذكر 3 أيام متتالية',
    icon: Icons.local_fire_department_outlined,
  ),
  AchievementDef(
    id: AchievementId.streak7,
    titleAr: 'استمرارية أسبوع',
    descriptionAr: 'حافظت على الذكر 7 أيام متتالية',
    icon: Icons.local_fire_department,
  ),
  AchievementDef(
    id: AchievementId.streak30,
    titleAr: 'استمرارية شهر',
    descriptionAr: 'حافظت على الذكر 30 يوماً متتالياً',
    icon: Icons.whatshot_outlined,
  ),
  AchievementDef(
    id: AchievementId.streak100,
    titleAr: 'استمرارية 100 يوم',
    descriptionAr: 'حافظت على الذكر 100 يوم متتالٍ',
    icon: Icons.whatshot,
  ),
  AchievementDef(
    id: AchievementId.firstMorningAdhkar,
    titleAr: 'أول أذكار صباح',
    descriptionAr: 'أتممت جلسة أذكار الصباح كاملة لأول مرة',
    icon: Icons.wb_sunny_outlined,
  ),
  AchievementDef(
    id: AchievementId.firstEveningAdhkar,
    titleAr: 'أول أذكار مساء',
    descriptionAr: 'أتممت جلسة أذكار المساء كاملة لأول مرة',
    icon: Icons.nights_stay_outlined,
  ),
];
