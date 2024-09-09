import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Klasse zur Verwaltung von Hints
class HintsManager {
  static const String _hintsKey = 'hints';

  static Future<int> loadHints() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_hintsKey) ??
          5; // Standardwert 0, falls nicht gespeichert
    } catch (e) {
      print('Error loading hints: $e');
      return 0; // Standardwert bei Fehler
    }
  }

  static Future<void> saveHints(int hints) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hintsKey, hints);
    } catch (e) {
      print('Error saving hints: $e');
    }
  }

  static Future<void> addHints(int amount) async {
    try {
      int currentHints = await loadHints();
      await saveHints(currentHints + amount);
    } catch (e) {
      print('Error adding hints: $e');
    }
  }

  static Future<void> subtractHints(int amount) async {
    try {
      int currentHints = await loadHints();
      await saveHints(
          (currentHints - amount).clamp(0, double.infinity).toInt());
    } catch (e) {
      print('Error subtracting hints: $e');
    }
  }
}

// Klasse zur Verwaltung von Rems
class RemsManager {
  static const String _remsKey = 'rems';

  static Future<int> loadRems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_remsKey) ??
          5; // Standardwert 0, falls nicht gespeichert
    } catch (e) {
      print('Error loading rems: $e');
      return 0; // Standardwert bei Fehler
    }
  }

  static Future<void> saveRems(int rems) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_remsKey, rems);
    } catch (e) {
      print('Error saving rems: $e');
    }
  }

  static Future<void> addRems(int amount) async {
    try {
      int currentRems = await loadRems();
      await saveRems(currentRems + amount);
    } catch (e) {
      print('Error adding rems: $e');
    }
  }

  static Future<void> subtractRems(int amount) async {
    try {
      int currentRems = await loadRems();
      await saveRems((currentRems - amount).clamp(0, double.infinity).toInt());
    } catch (e) {
      print('Error subtracting rems: $e');
    }
  }
}

// Provider für Hints
class HintsProvider extends ChangeNotifier {
  int _hints = 5;

  int get hints => _hints;

  // Laden der Hints
  Future<void> loadHints() async {
    _hints = await HintsManager.loadHints();
    notifyListeners();
  }

  // Speichern der Hints
  Future<void> saveHints(int hints) async {
    _hints = hints;
    await HintsManager.saveHints(hints);
    notifyListeners();
  }

  // Hints hinzufügen
  Future<void> addHints(int amount) async {
    _hints += amount;
    await HintsManager.saveHints(_hints);
    notifyListeners();
  }

  // Hints abziehen
  Future<void> subtractHints(int amount) async {
    _hints = (_hints - amount).clamp(0, double.infinity).toInt();
    await HintsManager.saveHints(_hints);
    notifyListeners();
  }
}

// Provider für Rems
class RemsProvider extends ChangeNotifier {
  int _rems = 5;

  int get rems => _rems;

  // Laden der Rems
  Future<void> loadRems() async {
    _rems = await RemsManager.loadRems();
    notifyListeners();
  }

  // Speichern der Rems
  Future<void> saveRems(int rems) async {
    _rems = rems;
    await RemsManager.saveRems(rems);
    notifyListeners();
  }

  // Rems hinzufügen
  Future<void> addRems(int amount) async {
    _rems += amount;
    await RemsManager.saveRems(_rems);
    notifyListeners();
  }

  // Rems abziehen
  Future<void> subtractRems(int amount) async {
    _rems = (_rems - amount).clamp(0, double.infinity).toInt();
    await RemsManager.saveRems(_rems);
    notifyListeners();
  }
}
