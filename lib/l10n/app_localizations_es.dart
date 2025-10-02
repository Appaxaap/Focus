// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get language => 'Idioma';

  @override
  String get englishUs => 'Inglés (EE.UU.)';

  @override
  String get englishUk => 'Inglés (Reino Unido)';

  @override
  String get spanish => 'Español';

  @override
  String get german => 'Alemán';

  @override
  String get russian => 'Ruso';

  @override
  String get appName => 'Focus';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get customizeExperience => 'Personaliza tu experiencia con Focus';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String tasksCompletedToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count tareas completadas hoy!',
      one: '¡1 tarea completada hoy!',
      zero: 'Aún no hay tareas',
    );
    return '$_temp0 🎉';
  }

  @override
  String get showCompletedTasks => 'Mostrar tareas completadas';

  @override
  String get displayFinishedTasks => 'Mostrar tareas finalizadas';

  @override
  String get clearCompletedTasks => 'Borrar tareas completadas';

  @override
  String removeFinishedTasks(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminar $count tareas finalizadas',
      one: 'Eliminar 1 tarea finalizada',
    );
    return '$_temp0';
  }

  @override
  String get nothingToClear => 'Nada que borrar';

  @override
  String get completeSomeTasks => 'Completa algunas tareas primero';

  @override
  String get taskCompleted => 'Tarea completada';

  @override
  String get taskDeleted => 'Tarea eliminada';

  @override
  String get madeWithLove => 'Hecho con 💙 por Basim Basheer';

  @override
  String get privacyMessage => '🔒 Todos tus datos permanecen en tu dispositivo — sin nube, sin seguimiento.';
}
