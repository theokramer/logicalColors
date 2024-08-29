import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_manager.dart'; // Importiere CoinManager


class CoinManager {
  static const String _coinsKey = 'coins';

  // Laden der Coins von SharedPreferences
  static Future<int> loadCoins() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinsKey) ?? 0; // Standardwert 0, falls nicht gespeichert
  } catch (e) {
    print('Error loading coins: $e');
    return 0; // Standardwert bei Fehler
  }
}

static Future<void> saveCoins(int coins) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, coins);
  } catch (e) {
    print('Error saving coins: $e');
  }
}

static Future<void> addCoins(int amount) async {
  try {
    int currentCoins = await loadCoins();
    await saveCoins(currentCoins + amount);
  } catch (e) {
    print('Error adding coins: $e');
  }
}

static Future<void> subtractCoins(int amount) async {
  try {
    int currentCoins = await loadCoins();
    await saveCoins((currentCoins - amount).clamp(0, double.infinity).toInt());
  } catch (e) {
    print('Error subtracting coins: $e');
  }
}

}


class CoinProvider extends ChangeNotifier {
  int _coins = 0;

  int get coins => _coins;

  // Laden der Coins
  Future<void> loadCoins() async {
    _coins = await CoinManager.loadCoins();
    notifyListeners();
  }

  // Speichern der Coins
  Future<void> saveCoins(int coins) async {
    _coins = coins;
    await CoinManager.saveCoins(coins);
    notifyListeners();
  }

  // Coins hinzufügen
  Future<void> addCoins(int amount) async {
    _coins += amount;
    await CoinManager.saveCoins(_coins);
    notifyListeners();
  }

  // Coins abziehen
  Future<void> subtractCoins(int amount) async {
    _coins = (_coins - amount).clamp(0, double.infinity).toInt();
    await CoinManager.saveCoins(_coins);
    notifyListeners();
  }
}