import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Klasse zur Verwaltung der World-Daten
class WorldManager {
  static const String _worldsKey = 'worlds';

  // Lädt die Liste der Welten aus den SharedPreferences
  static Future<List<World>> loadWorlds() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? worldsJson = prefs.getStringList(_worldsKey);
      if (worldsJson == null) return []; // Leere Liste zurückgeben, wenn nichts gespeichert ist
      return worldsJson.map((worldJson) => World.fromJson(jsonDecode(worldJson))).toList();
    } catch (e) {
      print('Error loading worlds: $e');
      return []; // Leere Liste bei Fehler zurückgeben
    }
  }

  // Speichert die Liste der Welten in den SharedPreferences
  static Future<void> saveWorlds(List<World> worlds) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> worldsJson = worlds.map((world) => jsonEncode(world.toJson())).toList();
      await prefs.setStringList(_worldsKey, worldsJson);
    } catch (e) {
      print('Error saving worlds: $e');
    }
  }

  // Fügt eine neue Welt hinzu und speichert die aktualisierte Liste
  static Future<void> addWorld(World world) async {
    try {
      List<World> worlds = await loadWorlds();
      worlds.add(world);
      await saveWorlds(worlds);
    } catch (e) {
      print('Error adding world: $e');
    }
  }

  // Entfernt eine Welt anhand der ID und speichert die aktualisierte Liste
  static Future<void> removeWorld(int id) async {
    try {
      List<World> worlds = await loadWorlds();
      worlds.removeWhere((world) => world.id == id);
      await saveWorlds(worlds);
    } catch (e) {
      print('Error removing world: $e');
    }
  }
}

// Provider zur Verwaltung der World-Daten und zur Benachrichtigung der UI
class WorldProvider extends ChangeNotifier {
  List<World> _worlds = [];

  List<World> get worlds => _worlds;

  // Lädt die Welten und benachrichtigt die UI
  Future<void> loadWorlds() async {
    _worlds = await WorldManager.loadWorlds();
    notifyListeners();
  }

  // Speichert die Welten und benachrichtigt die UI
  Future<void> saveWorlds(List<World> worlds) async {
    _worlds = worlds;
    await WorldManager.saveWorlds(_worlds);
    notifyListeners();
  }

  // Fügt eine neue Welt hinzu und benachrichtigt die UI
  Future<void> addWorld(World world) async {
    _worlds.add(world);
    await WorldManager.saveWorlds(_worlds);
    notifyListeners();
  }

  // Entfernt eine Welt anhand der ID und benachrichtigt die UI
  Future<void> removeWorld(int id) async {
    _worlds.removeWhere((world) => world.id == id);
    await WorldManager.saveWorlds(_worlds);
    notifyListeners();
  }

  // Aktualisiert das maximale Level einer Welt und benachrichtigt die UI
  void updateWorldLevel(int worldId, int newLevel) {
    var world = _worlds.firstWhere((w) => w.id == worldId, orElse: () => World(id: -1, maxLevel: -1, colors: []));
    if (world.id != -1 && newLevel > world.maxLevel) {
      world.maxLevel = newLevel;
      notifyListeners();
      saveWorlds(_worlds); // Speichern der geänderten Liste
    }
  }

  // Gibt das maximale Level einer bestimmten Welt zurück
  int getMaxLevelForWorld(int worldId) {
    var world = _worlds.firstWhere(
      (w) => w.id == worldId,
      orElse: () => World(id: -1, maxLevel: -1, colors: []),
    );

    // Überprüfen, ob die Welt existiert
    if (world.id == -1) {
      // Rückgabewert im Fehlerfall, z.B. 0, oder andere Fehlerbehandlung
      return 0;
    }

    return world.maxLevel;
  }
}

// Die World-Klasse zur Darstellung der Weltdaten
class World {
  int id;
  int maxLevel;
  List<Color> colors;

  World({
    required this.id,
    required this.maxLevel,
    required this.colors,
  });

  // Konvertiert ein World-Objekt in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maxLevel': maxLevel,
      'colors': colors.map((color) => color.value).toList(),
    };
  }

  // Erstellt ein World-Objekt aus JSON
  factory World.fromJson(Map<String, dynamic> json) {
    return World(
      id: json['id'],
      maxLevel: json['maxLevel'],
      colors: (json['colors'] as List).map((color) => Color(color)).toList(),
    );
  }
}
