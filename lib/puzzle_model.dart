import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/difficulty_bar.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

int currentWorld = 1;

int timeElapsed = 0;

int anzHintsGot = 0;

int selectedWallpaper = 0;

IconData currencyIcon = Icons.star_border;
Color currencyColor = Colors.amber;

Color primaryColor = Colors.black;

Color getPrimaryColor(int index) {
  // Define colors for the 5 new solid-colored wallpapers
  Color? color = Colors.white;
  if (index == 2 || index == 4) return Colors.black;

  return color;
}

Color getBackgroundColor(int index) {
  // Define colors for the 5 new solid-colored wallpapers
  Color? color = Colors.blueGrey[800];
  if (index >= 0 && index < 5) {
    switch (index) {
      case 0:
        color = Colors.blueGrey[800];
        break;
      case 1:
        color = const Color(0xff1c1c1e);
        break;
      case 2:
        color = const Color(0xffb0e0e6);
        break;
      case 3:
        color = const Color(0xff483d8b);
        break;
      case 4:
        color = const Color(0xffe0d9c9);
        break;
      default:
        color = Colors.blueGrey[800];
    }
  }

  return color ?? Colors.blue;
}

bool noAds = false;

final List<String> languages = ['English', 'Deutsch', 'Español'];
final List<String> locales = ['en', 'de', 'es'];

int selectedLanguage = -1;

bool vibration = false;

bool animations = false;

bool sounds = false;

TutorialStep currentTutorialStep = TutorialStep.step1;

List<int> boughtWallpapers = [0];

List<World> worlds = [
  World(
      id: 1,
      maxLevel: 1,
      anzahlLevels: 0,
      name: "Anfänger",
      colors: const [
        Color(0xff48cae4),
        Color(0xff0077b6),
        Color.fromARGB(255, 0, 37, 89),
      ],
      unlocked: true),
  World(
      id: 2,
      maxLevel: 0,
      anzahlLevels: 25,
      name: "Lehrling",
      colors: const [
        Color(0xff9CDBA6),
        Color(0xff50B498),
        Color(0xff468585),
      ],
      unlocked: false),
  World(
      id: 3,
      maxLevel: 0,
      anzahlLevels: 25,
      name: "Schüler",
      colors: const [
        Color(0xffdb222a),
        Color(0xff7c2e41),
        Color(0xff053c5e),
      ],
      unlocked: false),
  World(
      id: 4,
      maxLevel: 0,
      anzahlLevels: 25,
      name: "Gelehrter",
      colors: const [
        Color(0xff720455),
        Color(0xff3C0753),
        Color(0xff030637),
      ],
      unlocked: false),
  World(
      id: 5,
      maxLevel: 0,
      anzahlLevels: 25,
      name: "Mystiker",
      colors: const [
        Color(0xffFFBB5C),
        Color(0xffd25E3E),
        Color(0xffE93D2F),
      ],
      unlocked: false),
  World(
      id: 6,
      maxLevel: 0,
      anzahlLevels: 25,
      name: "Prophet",
      colors: const [
        Color(0xffFFBB5C),
        Color(0xffd25E3E),
        Color(0xffE93D2F),
      ],
      unlocked: false),
  // Weitere Welten hier hinzufügen...
];

class PuzzleModel with ChangeNotifier {
  int size;
  int _moves;
  int _maxMoves;
  int _elapsedTime;
  int _targetColorNumber;
  int moveWhereError = -1;
  int _CrystalsEarned;
  double countClicks = 0;

  final List<List<dynamic>> _undoStack = []; // Stack für Undo-Funktion
  List<List<int>> _grid;
  List<List<int>> _savedGrid;
  List<List<int>> _lastCorrectGrid;
  List<List<int>> clicks;
  List<List<int>> savedClicks;

  bool gotHint = false;

  final Map<int, Color> _colorMapping;
  final Map<int, int> _numberMapping = {1: 2, 2: 3, 3: 1};
  final Map<int, int> _numberMappingReversed = {2: 1, 3: 2, 1: 3};
  final Random _random = Random();
  int? _hintX;
  int? _hintY;

  PuzzleModel({
    required this.size,
    required int level,
    required Map<int, Color> colorMapping,
  })  : _maxMoves = level,
        _moves = 0,
        _elapsedTime = 0,
        _grid = List.generate(size, (_) => List.generate(size, (_) => 1)),
        _savedGrid = List.generate(size, (_) => List.generate(size, (_) => 1)),
        _lastCorrectGrid =
            List.generate(size, (_) => List.generate(size, (_) => 1)),
        clicks = List.generate(level, (_) => []),
        savedClicks = List.generate(level, (_) => []),
        _CrystalsEarned = 10,
        _targetColorNumber = 1,
        _colorMapping = {
          1: worlds[currentWorld - 1].colors[0],
          2: worlds[currentWorld - 1].colors[1],
          3: worlds[currentWorld - 1].colors[2],
        } {
    initializeProgress();
  }

  // Getters
  List<List<int>> get grid => _grid;
  List<List<int>> get savedGrid => _savedGrid;
  int get moves => _moves;
  List<List<dynamic>> get undoStack => _undoStack;
  int get targetColorNumber => _targetColorNumber;
  int get maxMoves => _maxMoves;
  int get elapsedTime => _elapsedTime;
  Color get targetColor =>
      _colorMapping[_targetColorNumber] ?? Colors.transparent;
  int? get hintX => _hintX;
  int? get hintY => _hintY;
  int get CrystalsEarned => _CrystalsEarned;

  // Setters
  set grid(List<List<int>> newGrid) {
    _grid = newGrid.map((row) => List<int>.from(row)).toList();
    notifyListeners();
    _checkCompletion();
  }

  set colorMapping(Map<int, Color> newColorMap) {
    _colorMapping.addAll(newColorMap);
    notifyListeners();
  }

  // Methods
  void addWorld(int id, int maxLevel, List<Color> colors, bool unlocked,
      int anzahlLevels, String name) {
    worlds.add(World(
        id: id,
        maxLevel: maxLevel,
        name: name,
        colors: colors,
        unlocked: unlocked,
        anzahlLevels: anzahlLevels));
    notifyListeners();
  }

  Future<int> loadWorldProgress(int worldId) async {
    final prefs = await SharedPreferences.getInstance();
    //return 100;
    return prefs.getInt('world_$worldId') ??
        0; // 0 ist der Standardwert, wenn nichts gespeichert wurde
  }

  int getCurrencyAmount() {
    int currencyAmount = 0;
    for (int i = 1; i <= worlds.length; i++) {
      int temp = (getMaxLevelForWorld(i) == -2
          ? worlds[i - 1].anzahlLevels
          : getMaxLevelForWorld(i) == 0
              ? 0
              : getMaxLevelForWorld(i) - 1);
      currencyAmount += temp;
    }

    return currencyAmount;
  }

  int getCurrencyAmountForWorld(int worldID) {
    int currencyAmount = getMaxLevelForWorld(worldID);
    return currencyAmount == -2
        ? worlds[worldID - 1].anzahlLevels
        : currencyAmount - 1;
  }

  int getNeededCurrencyAmount(int world) {
    // int nCurrencyAmount = 0;
    // for (int i = 0; i < world; i++) {
    //   nCurrencyAmount += worlds[i].anzahlLevels;
    // }
    // return nCurrencyAmount;
    return world * 10;
  }

  Future<bool> loadWorldUnlocked(int worldId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('world_${worldId}_unlocked') ??
        false; // 0 ist der Standardwert, wenn nichts gespeichert wurde
  }

  Future<void> saveWorldUnlocked(int worldId, bool unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('world_${worldId}_unlocked', unlocked);
  }

  Future<void> saveWorldProgress(int worldId, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('world_$worldId', level);
  }

  Future<void> saveSelectedWallpaper(int selectedWallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wallpaper', selectedWallpaper);
  }

  Future<int> loadSelectedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wallpaper') ?? 0;
  }

  Future<void> saveTutorialStep(TutorialStep step) async {
    int stepInt = -1;
    switch (step) {
      case TutorialStep.none:
        stepInt = 0;
      case TutorialStep.step1:
        stepInt = 1;
      case TutorialStep.step2:
        stepInt = 2;
      case TutorialStep.step3:
        stepInt = 3;
      case TutorialStep.step4:
        stepInt = 4;
      case TutorialStep.step5:
        stepInt = 5;
      case TutorialStep.completed:
        stepInt = 6;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tutorialStep', stepInt);
  }

  Future<TutorialStep> loadTutorialStep() async {
    final prefs = await SharedPreferences.getInstance();

    int stepInt = prefs.getInt('tutorialStep') ?? -1;
    switch (stepInt) {
      case 0:
        return TutorialStep.none;
      case 1:
        return TutorialStep.step1;
      case 2:
        return TutorialStep.step2;
      case 3:
        return TutorialStep.step3;
      case 4:
        return TutorialStep.step4;
      case 5:
        return TutorialStep.step5;
      case 6:
        return TutorialStep.completed;
    }
    return TutorialStep.step2;
  }

  Future<void> saveBoughtWallpaper(int selectedWallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('w$selectedWallpaper', true);
  }

  Future<bool> loadBoughtWallpaper(int selectedWallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('w$selectedWallpaper') ?? false;
  }

  Future<void> saveHasRestoredPurchases(bool hasRestoredPurchases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasRestoredPurchases', hasRestoredPurchases);
  }

  Future<bool> loadHasRestoredPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasRestoredPurchases') ?? false;
  }

  Future<void> saveSounds(bool sounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sounds', sounds);
  }

  Future<void> saveVibration(bool vibration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', vibration);
  }

  Future<void> saveAnimations(bool animations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations', animations);
  }

  Future<void> saveSelectedLanguage(int language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedLanguage', language);
  }

  Future<void> saveNoAds(bool noAds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noAds', noAds);
  }

  Future<bool> loadNoAds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('noAds') ?? false;
  }

  void updateWorldLevel(int worldId, int newLevel) {
    var world = worlds.firstWhere((w) => w.id == worldId);
    if (newLevel > world.maxLevel &&
        (worlds[currentWorld - 1].maxLevel != -2)) {
      world.maxLevel = newLevel;
      saveWorldProgress(worldId, newLevel); // Speichere den neuen Fortschritt
    }
    if ((worlds[currentWorld - 1].maxLevel == -2)) {
      saveWorldProgress(worldId, -2);
    }
  }

  Future<void> initializeProgress() async {
    for (var world in worlds) {
      world.maxLevel = await loadWorldProgress(world.id);
      world.unlocked = await loadWorldUnlocked(world.id);
      selectedWallpaper = await loadSelectedWallpaper();
      currentTutorialStep = await loadTutorialStep();
      noAds = await loadNoAds();
      for (int i = 0; i < 30; i++) {
        if (await loadBoughtWallpaper(i)) {
          if (!boughtWallpapers.contains(i)) {
            boughtWallpapers.add(i);
          }
        }
      }
    }
    primaryColor = getPrimaryColor(selectedWallpaper);
    _initializeGrid();
  }

  bool isWorldUnlocked(int worldID) {
    if (worldID == 1) {
      return true;
    }
    try {
      return worlds.firstWhere((world) => world.id == worldID).unlocked;
    } catch (e) {
      return false;
    }
  }

  void unlockWorld(int worldID) {
    worlds
        .firstWhere((world) => world.id == worldID,
            orElse: () => World(
                id: -1,
                colors: [],
                name: "",
                maxLevel: 1,
                unlocked: false,
                anzahlLevels: -1))
        .unlocked = true;
  }

  int getMaxLevelForWorld(int worldId) {
    var world = worlds.firstWhere((w) => w.id == worldId,
        orElse: () => World(
            id: -1,
            maxLevel: -1,
            name: "",
            colors: [],
            unlocked: false,
            anzahlLevels: -1));

    return (world.maxLevel > world.anzahlLevels
        ? world.anzahlLevels
        : world.maxLevel);
  }

  void addMoves(int amount) {
    _moves -= 3;
    notifyListeners();
  }

  Map<String, int> getSizeAndMaxMoves(int level) {
    //return {"size": getGridSize(level), "maxMoves": getMaxMoves(level)};
    getMaxLevelForWorld(currentWorld);
    int s = currentWorld == 1
        ? 1
        : currentWorld == 5 || currentWorld == 6
            ? 3
            : 2; // Grid-Size
    int m = 1; // MaxMoves
    int startLevel = 1; // Startlevel für die aktuelle Grid-Size

    if (currentWorld == 1 && level < 19) {
      switch (level) {
        case 1:
          s = 1;
          m = 1;
          break;
        case 2:
        case 3:
          s = 2;
          m = 1;
          break;
        case 4:
        case 5:
        case 6:
          s = 2;
          m = 2;
          break;
        case 7:
        case 8:
          s = 2;
          m = 3;
          break;
        case 9:
          s = 3;
          m = 1;
          break;
        case 10:
          s = 3;
          m = 2;
          break;
        case 11:
          s = 3;
          m = 3;
          break;
        case 12:
          s = 3;
          m = 4;
          break;
        case 13:
          s = 3;
          m = 4;
          break;
        case 14:
          s = 3;
          m = 4;
          break;
        case 15:
          s = 4;
          m = 1;
          break;
        case 16:
          s = 4;
          m = 3;
          break;
        case 17:
          s = 4;
          m = 4;
          break;
        case 18:
          s = 4;
          m = 4;
          break;
        default:
          s = 2;
          m = 3;
          break;
      }
      return {"size": s, "maxMoves": m};
    } else if (currentWorld != 1 && currentWorld < 5 && level < 10) {
      switch (level) {
        case 1:
          s = 2;
          m = 1;
          break;
        case 2:
        case 3:
          s = 2;
          m = 2;
          break;
        case 4:
        case 5:
          s = 2;
          m = 3;
          break;
        case 6:
          s = 3;
          m = 1;
        case 7:
        case 8:
          s = 3;
          m = 2;
          break;
        case 9:
          s = 3;
          m = 3;
          break;
      }
      return {"size": s, "maxMoves": m};
    }

    while (level < 37) {
      if (currentWorld == 1) {
        int levelsForCurrentSize = ((s) * (s)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log((level - startLevel) + 1) / log(1.8))).ceil();
          int maxMovesForCurrentSize = (s * 1.8).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      } else {
        int levelsForCurrentSize = ((s) * (s)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log((level - startLevel) + 1) / log(1.9))).ceil();
          int maxMovesForCurrentSize = (s * 1.8).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      }
    }

    if (level >= 37) {
      s = 5;
      m = currentWorld == 1 ? 7 : 6;
      int tempLvl = level - 1;
      int set = 0;
      while (tempLvl > 37) {
        if (set == 2 || tempLvl >= 65) {
          set = 0;
          if (s > m - 5 && s > 4) {
            s = s - 1;
          } else {
            s = 5;
            m += 1;
          }
        } else {
          set += 1;
        }
        tempLvl -= 1;
      }
    }

    return {"size": s, "maxMoves": m};
  }

  // Berechnet die gridSize basierend auf dem aktuellen Level
  int getGridSize(int level) {
    switch (level) {
      case 1:
        return 1;
      case < 7:
        return 2;
      case < 14:
        return 3;
      case < 25:
        return 4;
      default:
        return 5;
    }
  }

  // Berechnet die maxMoves basierend auf dem aktuellen Level
  int getMaxMoves(int level) {
    int m;
    int s = getGridSize(level);
    m = 1;
    int tempLvl = level - 1;
    int set = 0;
    if (set == 2 || tempLvl >= 65) {
      set = 0;
      if (s > m - 5 && s > 4) {
        s = s - 1;
      } else {
        s = 5;
        m += 1;
      }
    } else {
      set += 1;
    }
    tempLvl -= 1;

    return m;
  }

  void refreshGrid(int newLevel, int newSize) {
    _maxMoves = newLevel;
    _moves = 0;
    _elapsedTime = 0;
    _grid = List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    _savedGrid =
        List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    _lastCorrectGrid =
        List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    clicks = List.generate(newLevel, (_) => []);
    savedClicks = List.generate(newLevel, (_) => []);
    _targetColorNumber = 1;
    _undoStack.clear();
    moveWhereError = -1;
    _initializeGrid();
    initializeProgress(); // Lade den Fortschritt
  }

  Future<void> addCrystals(int amount) async {
    await CoinManager.addCrystals(amount);
    notifyListeners();
  }

  Future<void> addHints(int amount) async {
    await HintsManager.addHints(amount);
    notifyListeners();
  }

  Future<void> addRems(int amount) async {
    await RemsManager.addRems(amount);
    notifyListeners();
  }

  Future<void> removeRems(int amount) async {
    await RemsManager.subtractRems(amount);
    notifyListeners();
  }

  Future<void> subtractCrystals(int amount) async {
    await CoinManager.subtractCrystals(amount);
    if (await CoinManager.loadCrystals() < 0) await CoinManager.saveCrystals(0);
    notifyListeners();
  }

  void setHint(int x, int y) {
    _hintX = x;
    _hintY = y;
    notifyListeners();
  }

  void clearHint() {
    _hintX = null;
    _hintY = null;
    notifyListeners();
  }

  int calculateCrystalsEarned(
      int maxMoves, int size, int selectedLevel, int worldID) {
    double difficulty = calculateDifficulty(maxMoves, size) * 8;

    // Skaliere die Schwierigkeit stärker für höhere Belohnungen
    num difficultyWeight = difficulty > 1 ? pow(difficulty, 2) : difficulty;

    // Dynamische Anpassung der Crystals-Belohnung basierend auf Level und Schwierigkeit
    double baseCrystals = difficultyWeight * 2; // Grundwert pro Schwierigkeit
    double levelFactor =
        log(selectedLevel); // sorgt für geringeren Einfluss bei kleinen Levels

    // Endberechnung der Crystals mit minimalen und maximalen Grenzen
    int CrystalsEarned = ((baseCrystals + levelFactor) * 0.4 + 5)
        .clamp(1, 1000)
        .ceil(); // z.B. Mindestwert 1, Maximalwert 1000

    return CrystalsEarned;
  }

  Future<List<Click>> readJson(int index) async {
    Level level = await readLevel(index);

    // Return the first click from the clicks list, if available
    if (level.clicks != null && level.clicks!.isNotEmpty) {
      return level.clicks!; // Return the first click
    } else {
      return [Click(x: 0, y: 0)]; // Return default click if no clicks found
    }
  }

  Future<String> loadJsonFromAssets(String filePath) async {
    String jsonString = await rootBundle.loadString(filePath);
    return jsonString;
  }

  Future<Level> readLevel(int index) async {
    String fileContent = await loadJsonFromAssets("assets/levels.json");

    // Decoding JSON file content into a Map
    var jsonData = jsonDecode(fileContent);

    // Deserializing into a Level object
    Level level = Level.fromJson(jsonData[index]);
    //Level level = Level();
    // Return the first click from the clicks list, if available
    return level;
  }

  Future<int> readMoves(int index) async {
    Level level = await readLevel(index - 1);
    return level.clicks?.length ?? 0;
  }

  Future<int> readSize(int index) async {
    Level level = await readLevel(index - 1);
    return level.size ?? 0;
  }

  Future<void> _initializeGrid() async {
    _targetColorNumber =
        _random.nextInt(3) + 1; // Target color number to achieve
    setTargetColor(_targetColorNumber);
    if (worlds[currentWorld - 1].maxLevel <= selectedLevel) {
      _CrystalsEarned =
          calculateCrystalsEarned(maxMoves, size, selectedLevel, currentWorld);
      //_CrystalsEarned = ((calculateDifficulty(maxMoves, size) * 100 + (selectedLevel * 0.3)) * 0.5).ceil();
    } else {
      //? Auskommentieren, wenn mehr Crystals in abgeschlossenen Levels gewünscht
      //_CrystalsEarned =
      //calculateCrystalsEarned(maxMoves, size, selectedLevel, currentWorld);
      _CrystalsEarned = 5;
    }
    // Initialize the grid with the target color
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _grid[i][j] = _targetColorNumber;
      }
    }

    List<Click> positions = [];
    if (currentTutorialStep == TutorialStep.completed) {
      if (targetColorNumber != 1) {
        grid[0][0] = targetColorNumber - 1;
      } else {
        grid[0][0] = 3;
      }
      _maxMoves = 0;
    } else {
      if (selectedLevel == -2) {
        selectedLevel = worlds[currentWorld - 1].anzahlLevels;
      }
      List<Click> clicks = await readJson(selectedLevel - 1);
// Create random moves and store them in the clicks list
      for (int i = 0; i < _maxMoves; i++) {
        int x;
        int y;
        if (currentWorld == 1) {
          x = clicks[i].x ?? 0;
          y = clicks[i].y ?? 0;
        } else {
          x = _randomPositionNumber();
          y = _randomPositionNumber();
        }

        int count = 0;
        bool works = false;
        while (works == false) {
          count = 0;
          for (int i = 0; i < positions.length; i++) {
            if (positions[i].x == x && positions[i].y == y) {
              count++;
            }
          }
          if (count < 2) {
            works = true;
          } else {
            x = _randomPositionNumber();
            y = _randomPositionNumber();
          }
        }
        positions.add(Click(x: x, y: y));

        clickTile(x, y, true, false);
        clicks[i] = Click(x: x, y: y);
        savedClicks[i] = [x, y]; // Deep copy the individual list
        if (tutorialActive &&
            currentTutorialStep != TutorialStep.step4 &&
            currentTutorialStep != TutorialStep.step5 &&
            currentTutorialStep != TutorialStep.completed &&
            currentTutorialStep != TutorialStep.none) {
          setHint(x, y);
        }
      }
    }

    //_maxMoves *= 2;
    // Save the current state of the grid
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _savedGrid[i][j] = _grid[i][j];
      }
    }
  }

  // Helper function to get color from name
  Color getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey; // Default color
    }
  }

  Future<bool> getHint() async {
    bool resetOccurred = false;

    if (moveWhereError != -1) {
      _moves = moveWhereError;
      grid = _lastCorrectGrid
          .map((row) => List<int>.from(row))
          .toList(); // Deep copy grid
      moveWhereError = -1;
      resetOccurred = true;
      undoStack.clear();
    }
    if (moves < maxMoves) {
      if (!gotHint) {
        if (await HintsManager.loadHints() > 0 && clicks.isNotEmpty) {
          gotHint = true;
          HintsManager.subtractHints(1);
          var hint = clicks[0];
          setHint(hint[0], hint[1]); // Set hint coordinates
        } else {
          if (await CoinManager.loadCrystals() >= 50) {
            gotHint = true;
            subtractCrystals(50);

            var hint = clicks[0];
            setHint(hint[0], hint[1]); // Set hint coordinates
          }
        }
      } else {
        var hint = clicks[0];
        setHint(hint[0], hint[1]); // Set hint coordinates
      }
    }

    return resetOccurred;
  }

  void setTargetColor(int colorNumber) {
    _targetColorNumber = colorNumber;
    notifyListeners();
  }

  Color? getHintColor(int x, int y) {
    if (clicks.isNotEmpty) {
      int currentColorNumber = _grid[x][y];
      int newColorNumber =
          _numberMapping[currentColorNumber] ?? currentColorNumber;
      return _colorMapping[newColorNumber];
    }
    return null;
  }

  void resetMoves() {
    _moves = 0;
    notifyListeners();
  }

  void clickTile(int x, int y, bool reversed, bool oneTile) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    if (_moves >= _maxMoves && !oneTile) return;

    int currentColorNumber = _grid[x][y];
    int newColorNumber = currentColorNumber;
    if (reversed) {
      newColorNumber =
          _numberMappingReversed[currentColorNumber] ?? currentColorNumber;
    } else {
      newColorNumber = _numberMapping[currentColorNumber] ?? currentColorNumber;
    }

    bool found = false;
    List<int>? removedHint;
    if (!reversed && !oneTile) {
      // Save the removed hint for undo functionality

      // Remove the clicked tile from the clicks list
      for (int i = 0; i < clicks.length; i++) {
        if (clicks[i][0] == x && clicks[i][1] == y) {
          found = true;
          removedHint = clicks[i];
          clicks.removeAt(i);
          break; // Exit the loop after removing the first matching element
        }
      }

      // Save the action to the undo stack with removed hint information
      _undoStack.add([x, y, currentColorNumber, removedHint, false]);

      if (!found && moveWhereError == -1) {
        moveWhereError = moves;
        _lastCorrectGrid =
            grid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
      } else {
        gotHint = false;
      }

      _moves++;
    }
    if (oneTile) {
      _undoStack.add([x, y, currentColorNumber, removedHint, true]);
    }

    _changeColor(x, y, newColorNumber, reversed, oneTile);
    clearHint(); // Clear hint after clicking
    notifyListeners();
  }

  void undoMove() {
    if (_undoStack.isEmpty) return;

    // Extract the last action from the stack
    List<dynamic> lastAction = _undoStack.removeLast();
    int x = lastAction[0];
    int y = lastAction[1];
    bool oneTile = lastAction[4] ?? false;
    //int oldColorNumber = lastAction[2];
    List<int>? removedHint = lastAction.length > 3 ? lastAction[3] : null;

    // Reverse the move
    if (!oneTile) {
      _moves--;
    }

    clickTile(x, y, true, oneTile);

    // If there was a removed hint, reinsert it back to the clicks list
    if (removedHint != null) {
      clicks.insert(0, removedHint);
    }

    notifyListeners();
  }

  void _changeColor(
      int x, int y, int newColorNumber, bool reversed, bool oneTile) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;

    int currentColorNumber = _grid[x][y];
    if (currentColorNumber == newColorNumber) return;
    if ((currentWorld != 2 && currentWorld != 4) || oneTile) {
      _grid[x][y] = newColorNumber;
    }
    if (!oneTile) {
      if (currentWorld == 1 || currentWorld == 2) {
        _updateAdjacentTile(x - 1, y, reversed); // Up
        _updateAdjacentTile(x + 1, y, reversed); // Down
        _updateAdjacentTile(x, y - 1, reversed); // Left
        _updateAdjacentTile(x, y + 1, reversed); // Right
      } else if (currentWorld == 3 || currentWorld == 4) {
        _updateAdjacentTile(x - 1, y - 1, reversed); // Up
        _updateAdjacentTile(x + 1, y + 1, reversed); // Down
        _updateAdjacentTile(x + 1, y - 1, reversed); // Left
        _updateAdjacentTile(x - 1, y + 1, reversed); // Right
      } else if (currentWorld == 5) {
        for (int i = -1; i < 2; i++) {
          for (int j = -1; j < 2; j++) {
            if (i == 0 && j == 0) {
            } else {
              _updateAdjacentTile(x + i, y + j, reversed); // Up
            }
          }
        }
      } else {
        _updateAdjacentTile(x - 2, y, reversed); // Up
        _updateAdjacentTile(x + 2, y, reversed); // Down
        _updateAdjacentTile(x, y - 2, reversed); // Left
        _updateAdjacentTile(x, y + 2, reversed); // Right
      }
    }
  }

  void _updateAdjacentTile(int x, int y, bool reversed) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;

    int currentColorNumber = _grid[x][y];
    int newColorNumber;
    if (reversed) {
      newColorNumber =
          _numberMappingReversed[currentColorNumber] ?? currentColorNumber;
    } else {
      newColorNumber = _numberMapping[currentColorNumber] ?? currentColorNumber;
    }

    _grid[x][y] = newColorNumber;
  }

  int _randomPositionNumber() {
    return _random.nextInt(size);
  }

  bool isGridFilledWithTargetColor() {
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j] != _targetColorNumber) {
          return false;
        }
      }
    }
    return true;
  }

  Color getColor(int colorNumber) {
    return _colorMapping[colorNumber] ?? Colors.transparent;
  }

  void resetGame() {
    _initializeGrid();
    _moves = 0;
    _elapsedTime = 0;
    moveWhereError = -1;
    _undoStack.clear(); // Clear undo stack
    //_timer?.cancel();
    notifyListeners();
  }

  void _checkCompletion() {
    if (isGridFilledWithTargetColor()) {
      // Notify listeners or trigger a completion event
      _onPuzzleCompleted();
    }
  }

  void _onPuzzleCompleted() {
    // This function can be used to notify that the puzzle is completed
    notifyListeners();
  }
}

class World {
  final int id;
  String name;
  int maxLevel;
  int anzahlLevels;
  List<Color> colors;
  bool unlocked;

  World(
      {required this.id,
      required this.name,
      required this.maxLevel,
      required this.anzahlLevels,
      required this.colors,
      required this.unlocked});
}

class Click {
  int? x;
  int? y;

  Click({this.x, this.y});

  Click.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['x'] = x;
    data['y'] = y;
    return data;
  }
}
