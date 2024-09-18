import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_manager.dart'; // Importiere CoinManager

class CoinManager {
  static const String _CrystalsKey = 'Crystals';

  // Laden der Crystals von SharedPreferences
  static Future<int> loadCrystals() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_CrystalsKey) ??
          10; // Standardwert 0, falls nicht gespeichert
    } catch (e) {
      print('Error loading Crystals: $e');
      return 0; // Standardwert bei Fehler
    }
  }

  static Future<void> saveCrystals(int Crystals) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_CrystalsKey, Crystals);
    } catch (e) {
      print('Error saving Crystals: $e');
    }
  }

  static Future<void> addCrystals(int amount) async {
    try {
      int currentCrystals = await loadCrystals();
      await saveCrystals(currentCrystals + amount);
    } catch (e) {
      print('Error adding Crystals: $e');
    }
  }

  static Future<void> subtractCrystals(int amount) async {
    try {
      int currentCrystals = await loadCrystals();
      await saveCrystals(
          (currentCrystals - amount).clamp(0, double.infinity).toInt());
    } catch (e) {
      print('Error subtracting Crystals: $e');
    }
  }
}

class CoinProvider extends ChangeNotifier {
  int _Crystals = 0;

  int get Crystals => _Crystals;

  // Laden der Crystals
  Future<void> loadCrystals() async {
    _Crystals = await CoinManager.loadCrystals();
    notifyListeners();
  }

  // Speichern der Crystals
  Future<void> saveCrystals(int Crystals) async {
    _Crystals = Crystals;
    await CoinManager.saveCrystals(Crystals);
    notifyListeners();
  }

  // Crystals hinzufügen
  Future<void> addCrystals(int amount) async {
    _Crystals += amount;
    await CoinManager.saveCrystals(_Crystals);
    notifyListeners();
  }

  // Crystals abziehen
  Future<void> subtractCrystals(int amount) async {
    _Crystals = (_Crystals - amount).clamp(0, double.infinity).toInt();
    await CoinManager.saveCrystals(_Crystals);
    notifyListeners();
  }
}
