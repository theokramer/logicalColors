import 'package:color_puzzle/level_selection.dart';
import 'package:color_puzzle/wallpaper_selection.dart';
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
  int selectedWallpaperIndex = 1; // Default wallpaper selection
  List<List<Color>> colors = [
    [
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey
    ],
    [
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey
    ],
    [
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo
    ],
    [
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo,
      Colors.indigo
    ],
    [
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey
    ],
  ];
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    final coinProvider = Provider.of<CoinProvider>(context);
    bool isWorldUnlocked = puzzle.isWorldUnlocked(currentWorld);

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/w$selectedWallpaper.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopRow(context, coinProvider, currentWorld,
                      puzzle.getMaxLevelForWorld(currentWorld)),
                  const SizedBox(height: 20),
                  _buildTitleText(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 5,
                  ),
                  _buildGrid(),
                  _buildActionButton(
                      context, isWorldUnlocked, coinProvider, puzzle),
                  const SizedBox(height: 20),
                  //_buildBottomRow(),
                  //const SizedBox(height: 30),
                ],
              ),
              _buildSwipeGestureDetector(),
              _buildNavigationArrows(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 100.0),
        itemCount: 9,
        itemBuilder: (context, index) {
          int x = index ~/ 3;
          int y = index % 3;
          Color tileColor = colors[currentWorld - 1][index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tileColor.withOpacity(0.8), tileColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(""),
          );
        },
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
              const SizedBox(width: 16),
              _buildIconButton(
                icon: Icons.palette,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) =>
                        const WallpaperSelectionWidget(),
                  );
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
              //const SizedBox(width: 16),
              /*_buildIconButton(
                icon: Icons.settings,
                onPressed: () {
                  // Handle settings navigation
                },
              ),*/
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
        color: Colors.white,
        fontSize: 42,
        fontWeight: FontWeight.bold,
        fontFamily: 'Quicksand',
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.2),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 178, 9, 9),
            Color.fromARGB(255, 210, 9, 9)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          _showUnlockOptionsDialog(
              context, currentWorldIndex, coinProvider, puzzle);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open, color: Colors.white, size: 36),
            SizedBox(width: 8),
            Text(
              'Unlock',
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
        color: Colors.white,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 28),
      color: Colors.white,
      onPressed: onPressed,
    );
  }
}

void _showUnlockOptionsDialog(BuildContext context, int currentWorldIndex,
    CoinProvider coinProvider, PuzzleModel puzzle) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10))),
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Unlock Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Do you want to unlock this world for €0.99 or all worlds for €2.99?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildUnlockButton(
              context,
              'Unlock Single World (€0.99)',
              Colors.teal,
              () {
                // Add unlock single world logic here
                Navigator.of(context).pop();
              },
            ),
            _buildUnlockButton(
              context,
              'Unlock All Worlds (€2.99)',
              Colors.orangeAccent,
              () {
                // Add unlock all worlds logic here
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

Widget _buildUnlockButton(
    BuildContext context, String text, Color color, VoidCallback onPressed) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}