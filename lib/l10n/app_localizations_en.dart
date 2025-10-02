// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get englishUs => 'English (US)';

  @override
  String get englishUk => 'English (UK)';

  @override
  String get spanish => 'Spanish';

  @override
  String get german => 'German';

  @override
  String get russian => 'Russian';

  @override
  String get appName => 'Focus';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get customizeExperience => 'Customize your Focus experience';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String tasksCompletedToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks completed today!',
      one: '1 task completed today!',
      zero: 'No tasks yet',
    );
    return '$_temp0 🎉';
  }

  @override
  String get showCompletedTasks => 'Show Completed Tasks';

  @override
  String get displayFinishedTasks => 'Display finished tasks';

  @override
  String get clearCompletedTasks => 'Clear Completed Tasks';

  @override
  String removeFinishedTasks(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count finished tasks',
      one: 'Remove 1 finished task',
    );
    return '$_temp0';
  }

  @override
  String get nothingToClear => 'Nothing to Clear';

  @override
  String get completeSomeTasks => 'Complete some tasks first';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get madeWithLove => 'Made with 💙 by Basim Basheer';

  @override
  String get privacyMessage => '🔒 All your data stays on your device — no cloud, no tracking.';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb(): super('en_GB');

  @override
  String get appName => 'Focus';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get customizeExperience => 'Customize your Focus experience';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String tasksCompletedToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks completed today!',
      one: '1 task completed today!',
      zero: 'No tasks yet',
    );
    return '$_temp0 🎉';
  }

  @override
  String get showCompletedTasks => 'Show Completed Tasks';

  @override
  String get displayFinishedTasks => 'Display finished tasks';

  @override
  String get clearCompletedTasks => 'Clear Completed Tasks';

  @override
  String removeFinishedTasks(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count finished tasks',
      one: 'Remove 1 finished task',
    );
    return '$_temp0';
  }

  @override
  String get nothingToClear => 'Nothing to Clear';

  @override
  String get completeSomeTasks => 'Complete some tasks first';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get madeWithLove => 'Made with 💙 by Basim Basheer';

  @override
  String get privacyMessage => '🔒 All your data stays on your device — no cloud, no tracking.';
}
