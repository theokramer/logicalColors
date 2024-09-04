import 'package:color_puzzle/level_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'custom_info_button.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:color_puzzle/coin_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    final coinProvider = Provider.of<CoinProvider>(context);
    bool isWorldUnlocked = puzzle.isWorldUnlocked(currentWorld);

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              _buildTopRow(context, coinProvider, currentWorld,
                  puzzle.getMaxLevelForWorld(currentWorld)),
              const SizedBox(height: 20),
              _buildTitleText(),
              const Spacer(),
              _buildActionButton(
                  context, isWorldUnlocked, coinProvider, puzzle),
              const SizedBox(height: 30),
              _buildBottomRow(),
              const SizedBox(height: 30),
            ],
          ),
          _buildSwipeGestureDetector(),
          _buildNavigationArrows(),
        ],
      ),
    );
  }

  Widget _buildTopRow(
    BuildContext context,
    CoinProvider coinProvider,
    int worldIndex,
    int maxLevel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIconButton(
                icon: Icons.shopping_cart,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ShopScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildIconButton(
                icon: Icons.grid_view,
                onPressed: () {
                  if (worlds[worldIndex].unlocked) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LevelSelectionScreen(
                          worldIndex: worldIndex,
                          currentLevel: maxLevel,
                        ),
                      ),
                    );
                  }

                  // Handle grid view navigation
                },
              ),
            ],
          ),
          Row(
            children: [
              Consumer<CoinProvider>(
                builder: (context, coinProvider, child) {
                  return CustomInfoButton(
                    value: '${coinProvider.coins}',
                    targetColor: -1,
                    movesLeft: -1,
                    iconPath: 'images/coins.png',
                    backgroundColor: Colors.black45,
                    textColor: Colors.white,
                    isLarge: 2,
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildIconButton(
                icon: Icons.settings,
                onPressed: () {
                  // Handle settings navigation
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText() {
    return Text(
      'World $currentWorld',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: worlds[currentWorld - 1].colors[1],
        fontSize: 42,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isWorldUnlocked,
      CoinProvider coinProvider, PuzzleModel puzzle) {
    return Center(
      child: isWorldUnlocked
          ? _buildPlayButton(context, currentWorld - 1)
          : _buildUnlockButton(
              context, (currentWorld - 1), coinProvider, puzzle),
    );
  }

  Widget _buildPlayButton(BuildContext context, int thisWorld) {
    final puzzle = Provider.of<PuzzleModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        ),
        onPressed: () {
          int maxLevel = puzzle.getMaxLevelForWorld(thisWorld + 1);
          selectedLevel = maxLevel;
          Navigator.of(context).push(
            FadePageRoute(
              page: ChangeNotifierProvider(
                create: (_) => PuzzleModel(
                  size: puzzle.getSizeAndMaxMoves(maxLevel)["size"] ?? 2,
                  level: puzzle.getSizeAndMaxMoves(maxLevel)["maxMoves"] ?? 2,
                  colorMapping: {
                    1: worlds[thisWorld].colors[0],
                    2: worlds[thisWorld].colors[1],
                    3: worlds[thisWorld].colors[2],
                  },
                ),
                child: const PuzzleScreen(),
              ),
            ),
          );
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 36),
            SizedBox(width: 8),
            Text(
              'PLAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockButton(BuildContext context, int currentWorldIndex,
      CoinProvider coinProvider, PuzzleModel puzzle) {
    //int unlockCost = (currentWorldIndex + 1) * (currentWorldIndex + 1) * 400;
    return ElevatedButton(
      onPressed: () async {
        //if (coinProvider.coins >= unlockCost) {
        //await coinProvider.subtractCoins(unlockCost);
        puzzle.unlockWorld(currentWorldIndex);
        puzzle.saveWorldUnlocked(currentWorldIndex, true);
        puzzle.updateWorldLevel(currentWorldIndex, 1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('World ${worlds[currentWorldIndex].id} unlocked!'),
          ),
        );
        // } else {
        /*Navigator.of(context).push(
            FadePageRoute(
              page: const ShopScreen(),
            ),
          );
        }*/
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Unlock',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIconButton(
            icon: Icons.map,
            onPressed: () {
              // Handle map navigation
            },
          ),
          _buildIconButton(
            icon: Icons.star,
            onPressed: () {
              // Handle star navigation
            },
          ),
          _buildIconButton(
            icon: Icons.calendar_today,
            onPressed: () {
              // Handle calendar navigation
            },
          ),
          _buildIconButton(
            icon: Icons.palette,
            onPressed: () {
              // Handle palette navigation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeGestureDetector() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          setState(() {
            if (details.primaryVelocity! < 0) {
              // Swipe Left
              if (currentWorld < worlds.length) {
                currentWorld++;
              }
            } else if (details.primaryVelocity! > 0) {
              // Swipe Right
              if (currentWorld > 1) {
                currentWorld--;
              }
            }
          });
        }
      },
    );
  }

  Widget _buildNavigationArrows() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentWorld > 1) _buildNavigationArrow(Icons.arrow_back, -1),
              const Spacer(),
              if (currentWorld < worlds.length)
                _buildNavigationArrow(Icons.arrow_forward, 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationArrow(IconData icon, int direction) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (direction == -1 && currentWorld > 1) {
            currentWorld--;
          } else if (direction == 1 && currentWorld < worlds.length) {
            currentWorld++;
          }
        });
      },
      child: Icon(
        icon,
        size: 36,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 28),
      color: Colors.black87,
      onPressed: onPressed,
    );
  }
}
