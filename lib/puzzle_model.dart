import 'dart:async';
import 'dart:math';
import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/difficulty_bar.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

int currentWorld = 1;

  List<World> worlds = [
  World(
    id: 1,
    maxLevel: 1,
    colors: const [
      Color(0xff48cae4),
      Color(0xff0077b6),
      Color.fromARGB(255, 0, 37, 89),
      
    ],
  ),
  World(
    id: 1,
    maxLevel: 0,
    colors: const [
      Color(0xff9CDBA6),
      Color(0xff50B498),
      Color(0xff468585),
    ],
  ),
  World(
    id: 3,
    maxLevel: 0,
    colors: const [
      Color(0xffdb222a),
      Color(0xff7c2e41),
      Color(0xff053c5e),
    ],
  ),
  World(
    id: 4,
    maxLevel: 0,
    colors: const [
      Color(0xff48cae4),
      Color(0xff0077b6),
      Color(0xff000814),
    ],
  ),
  World(
    id: 5,
    maxLevel: 0,
    colors: const [
      Color(0xff48cae4),
      Color(0xff0077b6),
      Color(0xff000814),
    ],
  ),
  // Weitere Welten hier hinzufügen...
];

class PuzzleModel with ChangeNotifier {
  int size;
  int _moves;
  int _maxMoves;
  int _elapsedTime;
  int _targetColorNumber;
  int moveWhereError = -1;
  int _coinsEarned;
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
      _lastCorrectGrid = List.generate(size, (_) => List.generate(size, (_) => 1)),
      clicks = List.generate(level, (_) => []),
      savedClicks = List.generate(level, (_) => []),
      _coinsEarned = 10,
      _targetColorNumber = 1,
      _colorMapping = {
        1: worlds[currentWorld - 1].colors[0],
        2: worlds[currentWorld - 1].colors[1],
        3: worlds[currentWorld - 1].colors[2],
      }
      
      {
    initializeProgress().then((_) {
      var sizeAndMoves = getSizeAndMaxMoves(selectedLevel);
      size = sizeAndMoves['size'] ?? 1;  // Sicherstellen, dass die Größe richtig gesetzt wird
      _maxMoves = sizeAndMoves['maxMoves'] ?? 1;

      _initializeGrid(); // Initialisiere das Grid mit den richtigen Werten
    });
    
      
}

  // Getters
  List<List<int>> get grid => _grid;
  List<List<int>> get savedGrid => _savedGrid;
  int get moves => _moves;
  List<List<dynamic>> get undoStack => _undoStack;
  int get targetColorNumber => _targetColorNumber;
  int get maxMoves => _maxMoves;
  int get elapsedTime => _elapsedTime;
  Color get targetColor => _colorMapping[_targetColorNumber] ?? Colors.transparent;
  int? get hintX => _hintX;
  int? get hintY => _hintY;
  int get coinsEarned => _coinsEarned;

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
  void addWorld(int id, int maxLevel, List<Color> colors) {
    worlds.add(World(id: id, maxLevel: maxLevel, colors: colors));
    notifyListeners();
  }

  Future<int> loadWorldProgress(int worldId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('world_$worldId') ?? 0; // 0 ist der Standardwert, wenn nichts gespeichert wurde
}


Future<void> saveWorldProgress(int worldId, int level) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('world_$worldId', level);
}


  void updateWorldLevel(int worldId, int newLevel) {
  var world = worlds.firstWhere((w) => w.id == worldId);
  if (newLevel > world.maxLevel) {
    world.maxLevel = newLevel;
    saveWorldProgress(worldId, newLevel); // Speichere den neuen Fortschritt
    notifyListeners();
  }
}

Future<void> initializeProgress() async {
  for (var world in worlds) {
    world.maxLevel = await loadWorldProgress(world.id);
  }
  if(worlds.lastIndexWhere((world) => world.maxLevel != 0) != -1) {
selectedLevel = worlds[worlds.lastIndexWhere((world) => world.maxLevel != 0)].maxLevel; 
  print(selectedLevel); 
  } else {
    selectedLevel = 1;
  }
  
  _initializeGrid();
}



  int getMaxLevelForWorld(int worldId) {
  // Use `orElse` to handle the case when no element matches the condition
  var world = worlds.firstWhere((w) => w.id == worldId, orElse: () => World(id: -1, maxLevel: -1, colors: []));
  
  // Check if the world is null, and handle it appropriately
  if (world == null) {
    // Return a default max level, e.g., 0, or handle the error as needed
    return 0; // or handle the error according to your app's logic
  }

  return world.maxLevel;
}


  Map<String, int> getSizeAndMaxMoves(int level) {
    getMaxLevelForWorld(currentWorld);
    int s = currentWorld == 1 ? 1 : 2; // Grid-Size
    int m = 1; // MaxMoves
    int startLevel = 1; // Startlevel für die aktuelle Grid-Size

    if (currentWorld == 1 && level < 13) {
      switch (level) {
        case 1:
          s = 1; m = 1;
          break;
        case 2:
        case 3:
          s = 2; m = 1;
          break;
        case 4:
        case 5:
        case 6:
          s = 2; m = 2;
          break;
        case 7:
        case 8:
          s = 2; m = 3;
          break;
        case 9:
          s = 3; m = 1;
          break;
        case 10:
          s = 3; m = 2;
          break;
        case 11:
          s = 3; m = 3;
          break;
        case 12:
          s = 3; m = 4;
          break;
        default:
          s = 2; m = 3;
          break;
      }
      return {"size": s, "maxMoves": m};
    }

    while (level < 50) {
      if (currentWorld == 1) {
        int levelsForCurrentSize = ((s) * (s)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log(level - startLevel + 1) / log(1.9))).ceil();
          int maxMovesForCurrentSize = (s * 1.8).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      } else {
        int levelsForCurrentSize = ((s + 0.6) * (s + 0.6)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log(level - startLevel + 1) / log(2.07))).floor();
          int maxMovesForCurrentSize = (s * 5).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      }
    }

    if (level >= 50) {
      s = 5;
      m = currentWorld == 1 ? 7 : 6;
      int tempLvl = level - 1;
      int set = 0;
      while (tempLvl > 50) {
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

  void refreshGrid(int newLevel, int newSize) {
    _maxMoves = newLevel;
    _moves = 0;
    _elapsedTime = 0;
    _grid = List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    _savedGrid = List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    _lastCorrectGrid = List.generate(newSize, (_) => List.generate(newSize, (_) => 1));
    clicks = List.generate(newLevel, (_) => []);
    savedClicks = List.generate(newLevel, (_) => []);
    _targetColorNumber = 1;
    _undoStack.clear();
    moveWhereError = -1;
    _initializeGrid();
        initializeProgress(); // Lade den Fortschritt
  }
  

  Future<void> addCoins(int amount) async {
    await CoinManager.addCoins(amount);
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

  



  Future<void> subtractCoins(int amount) async {
    await CoinManager.subtractCoins(amount);
    if (await CoinManager.loadCoins() < 0) await CoinManager.saveCoins(0);
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

  int calculateCoinsEarned(int maxMoves, int size, int selectedLevel) {
  double difficulty = calculateDifficulty(maxMoves, size) * 5;

  // Skaliere die Schwierigkeit stärker für höhere Belohnungen
  num difficultyWeight = difficulty > 1 ? pow(difficulty, 2.3) : difficulty;

  // Dynamische Anpassung der Coins-Belohnung basierend auf Level und Schwierigkeit
  double baseCoins = difficultyWeight * 1; // Grundwert pro Schwierigkeit
  double levelFactor = log(selectedLevel + 1); // sorgt für geringeren Einfluss bei kleinen Levels

  // Endberechnung der Coins mit minimalen und maximalen Grenzen
  int coinsEarned = (baseCoins + levelFactor).clamp(1, 1000).ceil(); // z.B. Mindestwert 1, Maximalwert 1000

  return coinsEarned;
}


    void _initializeGrid() {
    _targetColorNumber = _random.nextInt(3) + 1; // Target color number to achieve
    setTargetColor(_targetColorNumber);
    if(worlds[currentWorld-1].maxLevel <= selectedLevel) {
      _coinsEarned = calculateCoinsEarned(maxMoves, size, selectedLevel);
    //_coinsEarned = ((calculateDifficulty(maxMoves, size) * 100 + (selectedLevel * 0.3)) * 0.5).ceil();
    } else {
      _coinsEarned = 5;
    }
    // Initialize the grid with the target color
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _grid[i][j] = _targetColorNumber;
      }
    }
    
    List<Click> positions = [];

    // Create random moves and store them in the clicks list
    for (int i = 0; i < _maxMoves; i++) {
      var x = _randomPositionNumber();
      var y = _randomPositionNumber();
      int count = 0;
      bool works = false;
      while(works == false) {
        count = 0;
        for(int i = 0; i < positions.length; i++) {
          if(positions[i].x == x && positions[i].y == y) {
              count++;
          }
        }
        if(count < 2) {
          works = true;
        } else {
          x = _randomPositionNumber();
          y = _randomPositionNumber();
        }
      }
      positions.add(Click(x: x, y: y));


      clickTile(x, y, true, false);
      clicks[i] = [x, y];
      savedClicks[i] = [x, y];  // Deep copy the individual list
      if(tutorialActive && currentTutorialStep != TutorialStep.step3 && currentTutorialStep != TutorialStep.completed && currentTutorialStep != TutorialStep.none) {
      setHint(x, y);
    }
    }

    // Save the current state of the grid
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _savedGrid[i][j] = _grid[i][j];
      }
    }
    
  }


  Future<bool> getHint() async {
    bool resetOccurred = false;

    if (moveWhereError != -1) {
      _moves = moveWhereError;
      grid = _lastCorrectGrid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
      moveWhereError = -1;
      resetOccurred = true;
      undoStack.clear();
    } else {
      if (moves < maxMoves) {
        
        if(!gotHint) {
          if(await HintsManager.loadHints() > 0) {
            gotHint = true;
            HintsManager.subtractHints(1);
                      var hint = clicks[0];
        setHint(hint[0], hint[1]); // Set hint coordinates
          } else {
            if(await CoinManager.loadCoins() >= 50) {
            gotHint = true;
          subtractCoins(50);
          
          var hint = clicks[0];
        setHint(hint[0], hint[1]); // Set hint coordinates
        } 
          }
          
        } else {
          
                    var hint = clicks[0];
        setHint(hint[0], hint[1]); // Set hint coordinates
        }
        
        
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
      int newColorNumber = _numberMapping[currentColorNumber] ?? currentColorNumber;
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
    newColorNumber = _numberMappingReversed[currentColorNumber] ?? currentColorNumber;
  } else {
    newColorNumber = _numberMapping[currentColorNumber] ?? currentColorNumber;
  }

  bool found = false;

  if (!reversed && !oneTile) {
    
    
    
    // Save the removed hint for undo functionality
    List<int>? removedHint;

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
    _undoStack.add([x, y, currentColorNumber, removedHint]);

    if (!found && moveWhereError == -1) {
      moveWhereError = moves;
      _lastCorrectGrid = grid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
    } else {
      gotHint = false;
    }
    
    _moves++;
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
  //int oldColorNumber = lastAction[2];
  List<int>? removedHint = lastAction.length > 3 ? lastAction[3] : null;

  // Reverse the move
  _moves--;
  clickTile(x, y, true, false);
  

  // If there was a removed hint, reinsert it back to the clicks list
  if (removedHint != null) {
    clicks.insert(0, removedHint);
  }

  notifyListeners();
}


  void _changeColor(int x, int y, int newColorNumber, bool reversed, bool oneTile) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;

    int currentColorNumber = _grid[x][y];
    if (currentColorNumber == newColorNumber) return;

    _grid[x][y] = newColorNumber;
  if (!oneTile) {
    if (currentWorld == 1) {
                _updateAdjacentTile(x - 1, y, reversed); // Up
    _updateAdjacentTile(x + 1, y, reversed); // Down
    _updateAdjacentTile(x, y - 1, reversed); // Left
    _updateAdjacentTile(x, y + 1, reversed); // Right
    } else  if(currentWorld == 3) {
        _updateAdjacentTile(x - 1, y - 1, reversed); // Up
    _updateAdjacentTile(x + 1, y + 1, reversed); // Down
    _updateAdjacentTile(x + 1, y - 1, reversed); // Left
    _updateAdjacentTile(x - 1, y + 1, reversed); // Right
    } else {
      _updateAdjacentTile(x - 2, y, reversed); // Up
    _updateAdjacentTile(x + 2, y, reversed); // Down
    _updateAdjacentTile(x , y - 2, reversed); // Left
    _updateAdjacentTile(x, y + 2, reversed); // Right
    }
        
  }

  }

  void _updateAdjacentTile(int x, int y, bool reversed) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;

    int currentColorNumber = _grid[x][y];
    int newColorNumber;
    if (reversed) {
      newColorNumber = _numberMappingReversed[currentColorNumber] ?? currentColorNumber;
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
  int maxLevel;
  List<Color> colors;

  World({
    required this.id,
    required this.maxLevel,
    required this.colors,
  });
}

class Click {
  final int x;
final int y;

Click({
  required this.x,
  required this.y,
});
}