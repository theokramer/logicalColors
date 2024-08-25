import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PuzzleModel with ChangeNotifier {
  final int size;
  List<List<int>> _grid;
  List<List<int>> _savedGrid;
  List<List<int>> _lastCorrectGrid;
  int _moves;
  int _maxMoves;
  Timer? _timer;
  int _elapsedTime;
  int resetPosition = 0; 

  List<List<int>> clicks;
  List<List<int>> savedClicks;

  final Map<int, Color> _colorMapping = {
    1: Colors.red,
    2: Colors.green,
    3: Colors.blue,
  };

  final Map<int, int> _numberMapping = {
    1: 2,
    2: 3,
    3: 1,
  };

  final Map<int, int> _numberMappingReversed = {
    2: 1,
    3: 2,
    1: 3,
  };

  final Random _random = Random();
  int _targetColorNumber;

List<List<List<int>>> _undoStack = [];


  PuzzleModel({this.size = 3, int maxMoves = 5})
      : _maxMoves = maxMoves,
        _moves = 0,
        _elapsedTime = 0,
        _grid = List.generate(size, (i) => List.generate(size, (j) => 1)),
        _savedGrid = List.generate(size, (i) => List.generate(size, (j) => 1)),
        _lastCorrectGrid = List.generate(size, (i) => List.generate(size, (j) => 1)),
        clicks = List.generate(maxMoves, (_) => []),
        savedClicks = List.generate(maxMoves, (_) => []),
        _targetColorNumber = 1 { // Default target color number
    _initializeGrid();
    _startTimer();
  }

  List<List<int>> get grid => _grid;
  List<List<int>> get savedGrid => _savedGrid;
List<List<List<int>>> get undoStack => _undoStack;
  int get moves => _moves;
  int get targetColorNumber => _targetColorNumber;
  int get maxMoves => _maxMoves;
  int get elapsedTime => _elapsedTime;
  Color get targetColor => _colorMapping[_targetColorNumber] ?? Colors.transparent;
    set grid(List<List<int>> newGrid) {
    _grid = newGrid.map((row) => List<int>.from(row)).toList(); // Deep copy
    notifyListeners();
  }

  int moveWhereError = -1;

  int? _hintX;
  int? _hintY;

  int? get hintX => _hintX;
  int? get hintY => _hintY;

  // Method to set hint coordinates
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

  bool getHint() {
    bool resetOccurred = false;

    if (moveWhereError != -1) {
      _moves = moveWhereError - 1;
      grid = _lastCorrectGrid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
      moveWhereError = -1;
      resetOccurred = true;
    } else {
      if (moves < maxMoves - 1) {
        var hint = clicks.isNotEmpty ? clicks[0] : null;
        if (hint != null) {
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

  void _initializeGrid() {
    _targetColorNumber = _random.nextInt(3) + 1; // Target color number to achieve
    setTargetColor(_targetColorNumber);

    // Initialize the grid with the target color
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _grid[i][j] = _targetColorNumber;
      }
    }

    // Create random moves and store them in the clicks list
    for (int i = 0; i < _maxMoves; i++) {
      var x = _randomPositionNumber();
      var y = _randomPositionNumber();
      clickTile(x, y, true);
      clicks[i] = [x, y];
      savedClicks[i] = [x, y];  // Deep copy the individual list
    }

    // Save the current state of the grid
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        _savedGrid[i][j] = _grid[i][j];
      }
    }
  }

  void clickTile(int x, int y, bool reversed) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    if (_moves >= _maxMoves) return;

if(!reversed) {
      _undoStack.add(_grid.map((row) => List<int>.from(row)).toList()); // Save current state to undo stack
}

    int currentColorNumber = _grid[x][y];
    int newColorNumber = currentColorNumber;
    if (reversed) {
      newColorNumber = _numberMappingReversed[currentColorNumber] ?? currentColorNumber;
    } else {
      newColorNumber = _numberMapping[currentColorNumber] ?? currentColorNumber;
    }
    bool found = false;
    
    if (!reversed) {
      _moves++;
      // Remove the clicked tile from the clicks list
      for (int i = 0; i < clicks.length; i++) {
        if (clicks[i][0] == x && clicks[i][1] == y) {
          found = true;
          clicks.removeAt(i);
          break; // Exit the loop after removing the first matching element
        }
      }
      if (!found && moveWhereError == -1) {
        moveWhereError = moves;
        _lastCorrectGrid = grid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
      }
    }
    _changeColor(x, y, newColorNumber, reversed);

    clearHint(); // Clear hint after clicking

    notifyListeners();
  }

  void _changeColor(int x, int y, int newColorNumber, bool reversed) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;

    int currentColorNumber = _grid[x][y];
    if (currentColorNumber == newColorNumber) return;

    _grid[x][y] = newColorNumber;

    _updateAdjacentTile(x - 1, y, reversed); // Up
    _updateAdjacentTile(x + 1, y, reversed); // Down
    _updateAdjacentTile(x, y - 1, reversed); // Left
    _updateAdjacentTile(x, y + 1, reversed); // Right
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

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedTime++;
      notifyListeners();
    });
  }

  void resetGame() {
    _initializeGrid();
    _moves = 0;
    _elapsedTime = 0;
    moveWhereError = -1;
    _timer?.cancel();
    _startTimer();
    notifyListeners();
  }

  // Revert to the last state from the undo stack
  void undo() {
    if (_undoStack.isNotEmpty) {
      _grid = _undoStack.removeLast();
      _moves--;
      notifyListeners();
    }
  }
}
