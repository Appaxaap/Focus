// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get language => 'Sprache';

  @override
  String get englishUs => 'Englisch (USA)';

  @override
  String get englishUk => 'Englisch (GB)';

  @override
  String get spanish => 'Spanisch';

  @override
  String get german => 'Deutsch';

  @override
  String get russian => 'Russisch';

  @override
  String get appName => 'Focus';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get customizeExperience => 'Passe deine Focus-Erfahrung an';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String tasksCompletedToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben heute erledigt!',
      one: '1 Aufgabe heute erledigt!',
      zero: 'Noch keine Aufgaben',
    );
    return '$_temp0 🎉';
  }

  @override
  String get showCompletedTasks => 'Erledigte Aufgaben anzeigen';

  @override
  String get displayFinishedTasks => 'Abgeschlossene Aufgaben anzeigen';

  @override
  String get clearCompletedTasks => 'Erledigte Aufgaben löschen';

  @override
  String removeFinishedTasks(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erledigte Aufgaben entfernen',
      one: '1 erledigte Aufgabe entfernen',
    );
    return '$_temp0';
  }

  @override
  String get nothingToClear => 'Nichts zu löschen';

  @override
  String get completeSomeTasks => 'Erledige zuerst einige Aufgaben';

  @override
  String get taskCompleted => 'Aufgabe erledigt';

  @override
  String get taskDeleted => 'Aufgabe gelöscht';

  @override
  String get madeWithLove => 'Mit 💙 erstellt von Basim Basheer';

  @override
  String get privacyMessage => '🔒 Alle deine Daten bleiben auf deinem Gerät — keine Cloud, kein Tracking.';
}
