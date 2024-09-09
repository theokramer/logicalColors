import 'package:color_puzzle/level_selection.dart';
import 'package:color_puzzle/main.dart';
import 'package:color_puzzle/wallpaper_selection.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    _bannerAd = BannerAd(
      adUnitId:
          "ca-app-pub-3940256099942544/2435281174", // correct one: 'ca-app-pub-3263827122305139/6797409538'
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          //ad.dispose();
        },
      ),
    );
    if (worlds[0].maxLevel > 10 && !noAds) {
      _bannerAd.load();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd.dispose();
  }

  void _updateWallpaper(int newIndex) {
    setState(() {
      selectedWallpaperIndex = newIndex;
    });
  }

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
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.indigo
    ],
    [
      Colors.indigo,
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.indigo,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey
    ],
    [
      Colors.indigo,
      Colors.grey,
      Colors.indigo,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.indigo,
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
              Stack(
                children: [
                  Column(
                    children: [
                      _buildTopRow(context, coinProvider, currentWorld,
                          puzzle.getMaxLevelForWorld(currentWorld), puzzle),
                      const SizedBox(
                        height: 20,
                      ),

                      _buildTitleText(puzzle.getMaxLevelForWorld(currentWorld)),
                      const Spacer(),

                      _buildActionButton(
                          context, isWorldUnlocked, coinProvider, puzzle, () {
                        setState(() {
                          isWorldUnlocked = true;
                        });
                      }),
                      const SizedBox(height: 80),
                      //_buildBottomRow(),
                      //const SizedBox(height: 30),
                    ],
                  ),
                  Column(
                    children: [const Spacer(), _buildGrid(), const Spacer()],
                  ),
                ],
              ),
              _buildSwipeGestureDetector(),
              _buildNavigationArrows(),
              if (_isBannerAdReady)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: _bannerAd.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 95.0),
        itemCount: 9,
        itemBuilder: (context, index) {
          int x = index ~/ 3;
          int y = index % 3;
          Color tileColor = colors[currentWorld - 1][index];
          Color borderColor = currentWorld == 6 || currentWorld == 5
              ? index == 0
                  ? Colors.red
                  : Colors.transparent
              : index == 4
                  ? Colors.red
                  : Colors.transparent;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tileColor.withOpacity(0.8), tileColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: borderColor, width: 4),
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

  Widget _buildTopRow(BuildContext context, CoinProvider coinProvider,
      int worldIndex, int maxLevel, PuzzleModel puzzle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
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
                      if (puzzle.isWorldUnlocked(currentWorld)) {
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
                            WallpaperSelectionWidget(
                          onWallpaperSelected: _updateWallpaper,
                        ),
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
          if (!noAds)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5.0, top: 5),
                  child: GestureDetector(
                    onTap: () {
                      puzzle.saveNoAds(true);
                      noAds = true;
                      Navigator.of(context).pushReplacement(
                        FadePageRoute(
                          page: const MainMenuScreen(),
                        ),
                      );
                    },
                    child: Image.asset(
                      "images/no_ads.png",
                      height: 35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTitleText(int maxLevel) {
    return Text(
      'World $currentWorld ${maxLevel > 1 ? ("– Level $maxLevel") : ""}',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 35,
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
      CoinProvider coinProvider, PuzzleModel puzzle, Function onUnlock) {
    return Center(
      child: isWorldUnlocked
          ? _buildPlayButton(context, currentWorld - 1)
          : _buildUnlockButton(
              context, (currentWorld - 1), coinProvider, puzzle, onUnlock),
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
          if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
            _showUnlockOptionsDialog(context, thisWorld, puzzle, () {});
          } else {
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
          }
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
      CoinProvider coinProvider, PuzzleModel puzzle, Function onUnlock) {
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
      ),
      child: ElevatedButton(
        onPressed: () async {
          _showUnlockOptionsDialog(
              context, currentWorldIndex, puzzle, onUnlock);
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
        elevation: 4,
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

void _showUnlockOptionsDialog(BuildContext context, int currentWorldIndex,
    PuzzleModel puzzle, Function onUnlock) {
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
                'Unlocking all worlds',
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
                'You can unlock all worlds and levels in the game, by purchasing one item in the shop.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildUnlockButton(context, "Open Shop", Colors.teal, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ShopScreen(),
                ),
              );
            }),
            /*_buildUnlockButton(
              context,
              'Unlock Single World (€0.99)',
              Colors.teal,
              () {
                puzzle.saveWorldUnlocked(currentWorldIndex + 1, true);
                puzzle.unlockWorld(currentWorldIndex + 1);
                puzzle.updateWorldLevel(currentWorldIndex + 1, 1);
                puzzle.saveWorldProgress(currentWorldIndex + 1, 1);
                onUnlock();

                // Add unlock single world logic here
                Navigator.of(context).pop();
              },
            ),
            _buildUnlockButton(
              context,
              'Unlock All Worlds (€1.99)',
              Colors.orangeAccent,
              () {
                for (int i = 0; i < worlds.length; i++) {
                  if (!puzzle.isWorldUnlocked(i + 1)) {
                    puzzle.saveWorldUnlocked(i + 1, true);
                    puzzle.unlockWorld(i + 1);
                    puzzle.updateWorldLevel(i + 1, 1);
                    puzzle.saveWorldProgress(i + 1, 1);
                    onUnlock();
                  }

                  // Add unlock single world logic here
                }
                Navigator.of(context).pop();
              },
            ),*/
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
