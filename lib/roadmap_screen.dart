import 'package:color_puzzle/main.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_manager.dart'; // Import the coin manager
import 'puzzle_model.dart';

class RoadMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    final result = RoadMapUtils.findHighestUnlockedWorldAndLevel(puzzle);

    // Define the highest unlocked world and level
    int maxWorldIndex = worlds.length - 1;
    int maxLevel = puzzle.getMaxLevelForWorld(maxWorldIndex + 1);
    
    // CoinProvider to handle coins
    final coinProvider = Provider.of<CoinProvider>(context);

    return FutureBuilder<int>(
      future: loadWorldProgress(currentWorld),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          int maxLevel = snapshot.data ?? 1;
          return Scaffold(
            appBar: AppBar(
              title: Text('Road Map', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
            ),
            body: Stack(
              children: [
                ListView.builder(
                  itemCount: worlds.length,
                  itemBuilder: (context, worldIndex) {
                    final world = worlds[worldIndex];
                    bool isWorldUnlocked = puzzle.isWorldUnlocked(worldIndex);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: isWorldUnlocked ? Colors.white : Colors.grey,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          title: Text(
                            'World ${world.id}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isWorldUnlocked ? worlds[worldIndex].colors[1] : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            isWorldUnlocked
                                ? 'Levels 1-${world.maxLevel}'
                                : 'Unlock for ${world.id * 100} coins',
                            style: TextStyle(
                              fontSize: 16,
                              color: isWorldUnlocked ? worlds[worldIndex].colors[1] : Colors.white,
                            ),
                          ),
                          onTap: isWorldUnlocked
                              ? () {
                                  // Navigate to level selection if unlocked
                                  currentWorld = worldIndex + 1;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LevelSelectionScreen(
                                        worldIndex: world.id,
                                        currentLevel: puzzle.getMaxLevelForWorld(world.id),
                                      ),
                                    ),
                                  );
                                }
                              : () async {
                                  // Unlock world if coins are sufficient
                                  if (coinProvider.coins >= (world.id * 100)) {
                                    await coinProvider.subtractCoins(world.id * 100);
                                    puzzle.unlockWorld(worldIndex);
                                    puzzle.saveWorldUnlocked(worldIndex, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('World ${world.id} unlocked!'),
                                      ),
                                    );
                                  } else {
                                    _showInsufficientCoinsDialog(context);
                                  }
                                },
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: ElevatedButton(
                            onPressed: () {
                              int highestWorldIndex = result['highestWorldIndex'] ?? 1;
                              int highestLevelIndex = result['highestLevelIndex'] ?? 1;
                              selectedLevel = highestLevelIndex;
                              Navigator.of(context).pushReplacement(
                                FadePageRoute(
                                  page: ChangeNotifierProvider(
                                    create: (_) => PuzzleModel(
                                      size: puzzle.getSizeAndMaxMoves((highestWorldIndex - 1) + highestLevelIndex)["size"] ?? 2,
                                      level: puzzle.getSizeAndMaxMoves((highestWorldIndex - 1) + highestLevelIndex)["maxMoves"] ?? 2,
                                      colorMapping: {
                                        1: worlds[currentWorld - 1].colors[0],
                                        2: worlds[currentWorld - 1].colors[1],
                                        3: worlds[currentWorld - 1].colors[2],
                                      },
                                    ),
                                    child: PuzzleScreen(),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'World ${(result['highestWorldIndex'] ?? 1) + 1} – Level ${result['highestLevelIndex'] ?? 1}',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: worlds[result['highestWorldIndex'] ?? 1].colors[1],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _showInsufficientCoinsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nicht genügend Münzen'),
          content: Text('Du hast nicht genügend Münzen, um diese Welt freizuschalten.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class RoadMapUtils {
  // Function to find the highest unlocked world index and level index
  static Map<String, int> findHighestUnlockedWorldAndLevel(PuzzleModel puzzle) {
    int highestWorldIndex = -1;
    int highestLevelIndex = -1;

    for (int worldIndex = 0; worldIndex < worlds.length; worldIndex++) {
      final world = worlds[worldIndex];
      bool isWorldUnlocked = puzzle.isWorldUnlocked(worldIndex);

      if (isWorldUnlocked) {
        int currentMaxLevel = puzzle.getMaxLevelForWorld(worldIndex + 1);
        int worldStartLevel = (worldIndex) * 75 + 1;
        int worldEndLevel = (worldIndex + 1) * 75;

        // Update highest world index and highest level index
        if (worldIndex > highestWorldIndex) {
          highestWorldIndex = worldIndex;
          highestLevelIndex = currentMaxLevel;
        } else if (worldIndex == highestWorldIndex) {
          highestLevelIndex = currentMaxLevel;
        }
      }
    }

    return {
      'highestWorldIndex': highestWorldIndex,
      'highestLevelIndex': highestLevelIndex,
    };
  }
}

class LevelSelectionScreen extends StatelessWidget {
  final int worldIndex;
  final int currentLevel;

  LevelSelectionScreen({
    required this.worldIndex,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    int worldStartLevel = (worldIndex - 1) * 75 + 1;
    int worldEndLevel = (worldIndex) * 75;

    return Scaffold(
      appBar: AppBar(
        title: Text('World $worldIndex Levels', style: TextStyle(color: Colors.white),),
        backgroundColor: worlds[worldIndex - 1].colors[1],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: worldEndLevel - worldStartLevel + 1,
        itemBuilder: (context, levelIndex) {
          int levelNumber = levelIndex + 1;
          bool isLevelUnlocked = levelNumber <= currentLevel || levelIndex == 0;

          return GestureDetector(
            onTap: isLevelUnlocked
                ? () {
                    selectedLevel = levelIndex + 1;
                    Navigator.of(context).pushReplacement(
                      FadePageRoute(
                        page: ChangeNotifierProvider(
                          create: (_) => PuzzleModel(
                            size: puzzle.getSizeAndMaxMoves(levelNumber)["size"] ?? 2,
                            level: puzzle.getSizeAndMaxMoves(levelNumber)["maxMoves"] ?? 2,
                            colorMapping: {
    1: worlds[currentWorld - 1].colors[0],
    2: worlds[currentWorld - 1].colors[1] ,
    3: worlds[currentWorld - 1].colors[2],
  }
                          ),
                          child: PuzzleScreen(),
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: isLevelUnlocked ? worlds[worldIndex - 1].colors[1] : Colors.grey,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$levelNumber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}