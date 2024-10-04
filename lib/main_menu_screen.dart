// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/level_selection.dart';
import 'package:color_puzzle/main.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:color_puzzle/wallpaper_selection.dart';

import 'custom_info_button.dart';
import 'puzzle_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Level {
  int? worldNr;
  int? levelNr;
  int? size;
  List<Click>? clicks;

  Level({
    this.worldNr,
    this.levelNr,
    this.size,
    this.clicks,
  });

  Level.fromJson(Map<String, dynamic> json) {
    worldNr = json['worldNr'];
    levelNr = json['levelNr'];
    size = json['size'];
    if (json['clicks'] != null) {
      clicks = <Click>[];
      json['clicks'].forEach((v) {
        clicks!.add(Click.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['worldNr'] = worldNr;
    data['levelNr'] = levelNr;
    if (clicks != null) {
      data['clicks'] = clicks!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int selectedWallpaperIndex = 1; // Default wallpaper selection
  //late BannerAd _bannerAd;
  //final bool _isBannerAdReady = false;

  bool showWorldSelection = false;

  @override
  void initState() {
    super.initState();

    //_loadProduct;
    // _bannerAd = BannerAd(
    //   adUnitId: 'ca-app-pub-3263827122305139/4072388867',
    //   request: const AdRequest(),
    //   size: AdSize.banner,
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       setState(() {
    //         _isBannerAdReady = true;
    //       });
    //     },
    //     onAdFailedToLoad: (ad, err) {
    //       print('Failed to load a banner ad: ${err.message}');
    //       //ad.dispose();
    //     },
    //   ),
    // );
    // if (worlds[0].maxLevel > 10 && !noAds) {
    //   _bannerAd.load();
    // }
  }

  @override
  void dispose() {
    super.dispose();
    //_bannerAd.dispose();
  }

  void _updateLevel(int newIndex) {
    setState(() {
      selectedLevel = newIndex;
    });
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
  void closeWorldSelection(bool test) {
    setState(() {
      selectedLevel = worlds[currentWorld - 1].maxLevel == -2
          ? worlds[currentWorld - 1].anzahlLevels
          : worlds[currentWorld - 1].maxLevel;
      showWorldSelection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    final coinProvider = Provider.of<CoinProvider>(context);
    bool isWorldUnlocked = puzzle.isWorldUnlocked(currentWorld);

    return Scaffold(
      backgroundColor: getBackgroundColor(selectedWallpaper),
      body: Container(
        decoration: selectedWallpaper < 5
            ? const BoxDecoration()
            : BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/w${selectedWallpaper - 5}.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
        child: Stack(
          children: [
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopRow(context, coinProvider, currentWorld,
                          puzzle.getMaxLevelForWorld(currentWorld), puzzle),
                      // const SizedBox(
                      //   height: 5,
                      // ),
                      const Divider(
                        thickness: 1.5,
                        height: 1,
                      ),

                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                LevelSelectionWidget(puzzle: puzzle),
                                const SizedBox(
                                  height: 100,
                                ),
                                _buildGrid(),
                                _buildActionButton(context, isWorldUnlocked,
                                    coinProvider, puzzle, () {
                                  setState(() {
                                    isWorldUnlocked = true;
                                  });
                                }),
                                const SizedBox(height: 30),
                                const Divider(
                                  thickness: 1.5,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            showWorldSelection = true;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            _buildIconButton2(
                                              icon: Icons.more_vert,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              worlds[currentWorld - 1].name,
                                              style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ],
                                        ),
                                      ),
                                      Consumer<CoinProvider>(
                                        builder:
                                            (context, coinProvider, child) {
                                          return Row(
                                            children: [
                                              Icon(
                                                currencyIcon,
                                                color: currencyColor,
                                                size: 25,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              Text(
                                                "${puzzle.getCurrencyAmountForWorld(currentWorld)}/${worlds[currentWorld - 1].anzahlLevels}",
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ),
                            if (showWorldSelection)
                              Column(
                                children: [
                                  WorldSelectionScreen(
                                      puzzle: puzzle,
                                      onWorldSelected: closeWorldSelection),
                                ],
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            // _buildSwipeGestureDetector(),
            // _buildNavigationArrows(),
            // if (_isBannerAdReady)
            //   Align(
            //     alignment: Alignment.bottomCenter,
            //     child: LayoutBuilder(
            //       builder: (context, constraints) {
            //         return SizedBox(
            //           width: constraints.maxWidth,
            //           height: _bannerAd.size.height.toDouble(),
            //           child: AdWidget(ad: _bannerAd),
            //         );
            //       },
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLevelDisplay() {
    return Column(
      children: [
        Text(
          'Selected Level',
          style: TextStyle(
            color: primaryColor.withOpacity(0.8),
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          selectedLevel == -2
              ? (worlds[currentWorld - 1].anzahlLevels).toString()
              : selectedLevel.toString(),
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: SizedBox(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          padding: EdgeInsets.symmetric(
              horizontal:
                  (MediaQuery.of(context).size.width < 500) ? 95.0 : 300),
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
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, CoinProvider coinProvider,
      int worldIndex, int maxLevel, PuzzleModel puzzle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SunnysDisplay(
                        puzzle: puzzle,
                      ),
                      // _buildIconButton(
                      //   icon: Icons.shopping_cart,
                      //   onPressed: () {
                      //     Navigator.of(context).push(
                      //       FadePageRoute(
                      //         page: const ShopScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      //const SizedBox(width: 16),

                      //     // Handle grid view navigation
                      //   },
                      // ),
                      // const SizedBox(width: 16),
                      // _buildIconButton(
                      //   icon: Icons.palette,
                      //   onPressed: () {
                      //     showDialog(
                      //       context: context,
                      //       builder: (BuildContext context) =>
                      //           WallpaperSelectionWidget(
                      //         onWallpaperSelected: _updateWallpaper,
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                  Row(
                    children: [
                      //     Consumer<CoinProvider>(
                      //       builder: (context, coinProvider, child) {
                      //         return CustomInfoButton(
                      //           value: '${coinProvider.Crystals}',
                      //           targetColor: -1,
                      //           movesLeft: -1,
                      //           iconPath: 'images/Crystals.png',
                      //           backgroundColor: Colors.black45,
                      //           textColor: primaryColor,
                      //           isLarge: 2,
                      //         );
                      //       },
                      //     ),
                      //     //const SizedBox(width: 16),
                      // GestureDetector(
                      //   onTap: () {
                      //     if (puzzle.isWorldUnlocked(currentWorld)) {
                      //       Navigator.of(context).push(
                      //         MaterialPageRoute(
                      //           builder: (context) => LevelSelectionScreen(
                      //             worldIndex: worldIndex,
                      //             currentLevel: maxLevel,
                      //           ),
                      //         ),
                      //       );
                      //     }
                      //   },
                      //   child: _buildIconButton2(
                      //     icon: Icons.grid_view,
                      //   ),
                      // ),
                      const SizedBox(
                        width: 20,
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SettingsScreen(
                                puzzle: puzzle,
                              ); // Hier wird die SettingsScreen als Modal geladen
                            },
                            isScrollControlled:
                                true, // Optional: damit Modal den ganzen Bildschirm ausfüllt
                          );
                        },
                        child: _buildIconButton2(
                          icon: Icons.tune,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!noAds && false)
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
              const SizedBox(
                height: 5,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText(int maxLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${worlds[currentWorld - 1].name} $selectedLevel',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
            shadows: [
              Shadow(
                color: primaryColor.withOpacity(0.2),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Icon(
          Icons.keyboard_arrow_down,
          color: primaryColor,
          size: 45,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, bool isWorldUnlocked,
      CoinProvider coinProvider, PuzzleModel puzzle, Function onUnlock) {
    return Center(child: _buildPlayButton(context, currentWorld - 1)
        /*isWorldUnlocked
          ? _buildPlayButton(context, currentWorld - 1)
          : _buildUnlockButton(
              context, (currentWorld - 1), coinProvider, puzzle, onUnlock),*/
        );
  }

  Widget _buildPlayButton(BuildContext context, int thisWorld) {
    final puzzle = Provider.of<PuzzleModel>(context, listen: false);
    int maxLevel = puzzle.getMaxLevelForWorld(thisWorld + 1);
    void playGame() async {
      int size = currentWorld == 1
          ? await puzzle.readSize(selectedLevel)
          : puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2;
      int level = currentWorld == 1
          ? await puzzle.readMoves(selectedLevel)
          : puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2;
      Navigator.of(context).pushReplacement(
        FadePageRoute(
          page: ChangeNotifierProvider(
            create: (_) => PuzzleModel(
              size: size,
              level: level,
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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF1B5E20)], // Brighter green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50), // More rounded corners
        boxShadow: [
          const BoxShadow(
            color: Colors.black45, // Darker shadow
            offset: Offset(0, 8),
            blurRadius: 15,
            spreadRadius: 3, // More spread for depth
          ),
          BoxShadow(
            color: Colors.green.withOpacity(0.4), // Green inner glow
            blurRadius: 12,
            spreadRadius: -4,
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 18),
        ),
        onPressed: () {
          // if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
          //   _showUnlockOptionsDialog(context, thisWorld, puzzle, () {});
          // } else {
          //   selectedLevel = maxLevel;
          playGame();

          //}
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow,
                color: Colors.white, size: 38), // Slightly larger icon
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Colors.lightGreenAccent],
              ).createShader(bounds),
              child: Text(
                "${AppLocalizations.of(context)?.play ?? "Play"} ${selectedLevel < maxLevel || maxLevel == -2 ? "Again" : ""}",
                style: const TextStyle(
                  fontSize: 24, // Larger font
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open, color: primaryColor, size: 36),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.unlock ?? "Unlock",
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeGestureDetector() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          setState(() {
            if (details.primaryVelocity! < 0) {
              currentWorld++;
            } else if (details.primaryVelocity! > 0) {
              currentWorld--;
            }
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.withOpacity(0.3), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Icon(
          icon,
          size: 48, // Larger icon
          color: primaryColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 28),
      color: Colors.black,
      onPressed: onPressed,
    );
  }
}

class LevelSelectionWidget extends StatefulWidget {
  final PuzzleModel puzzle; // Make sure this is final to be properly used
  const LevelSelectionWidget({
    super.key,
    required this.puzzle,
  });

  @override
  State<LevelSelectionWidget> createState() => _LevelSelectionWidgetState();
}

class _LevelSelectionWidgetState extends State<LevelSelectionWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Automatically scroll to the selected level after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedLevel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the ScrollController
    super.dispose();
  }

  void _scrollToSelectedLevel() {
    int updatedSelectedLevel = selectedLevel == -2
        ? worlds[currentWorld - 1].anzahlLevels
        : selectedLevel;
    // Calculate the position to scroll to
    double offset = ((updatedSelectedLevel - 1) * (75) +
        20); // Width of the item (75) + horizontal margin (20)
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalLevels =
        worlds[currentWorld - 1].anzahlLevels; // Ensure worlds is defined
    int maxLevel = widget.puzzle
        .getMaxLevelForWorld(currentWorld); // The last unlocked level

    return SizedBox(
      height: 70, // Increased height for more space
      child: ListView.builder(
        controller: _scrollController, // Assign the ScrollController
        scrollDirection: Axis.horizontal,
        itemCount: totalLevels,
        itemBuilder: (context, index) {
          int levelNumber = index + 1;
          bool isLevelUnlocked = levelNumber <= maxLevel;
          bool isCurrentLevel = selectedLevel == -2
              ? worlds[currentWorld - 1].anzahlLevels == levelNumber
              : selectedLevel == levelNumber;
          bool isLastLevel =
              levelNumber == maxLevel; // Only the last level gives a bonus

          return GestureDetector(
            onTap: isLevelUnlocked || maxLevel == -2
                ? () {
                    setState(() {
                      selectedLevel = levelNumber;
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrentLevel ? 100 : 75,
              height: isCurrentLevel ? 80 : 60,
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCurrentLevel ? Colors.white : Colors.transparent,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(20), // Rounded corners
                gradient: LinearGradient(
                  colors: isLevelUnlocked || maxLevel == -2
                      ? isLastLevel
                          ? [
                              currencyColor,
                              currencyColor,
                            ] // Different color for last level
                          : [
                              Colors.blueAccent,
                              Colors.blue
                            ] // Bright colors for finished levels
                      : [Colors.black26, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  if (isLevelUnlocked || maxLevel == -2)
                    BoxShadow(
                      color: isCurrentLevel
                          ? primaryColor.withOpacity(0.15)
                          : Colors.black26,
                      blurRadius: isCurrentLevel ? 3 : 3,
                      offset: const Offset(3, 3),
                    ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$levelNumber",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    SizedBox(
                      width: isCurrentLevel ? 10 : 5,
                    ),
                    Icon(
                      isLevelUnlocked || maxLevel == -2
                          ? isLastLevel
                              ? currencyIcon // Icon for the last level with a bonus
                              : Icons.check_circle // Icon for finished levels
                          : Icons.lock, // Icon for locked levels
                      color: isLevelUnlocked || maxLevel == -2
                          ? isLastLevel
                              ? Colors.white // Color for the last level icon
                              : Colors.white // Color for completed levels
                          : Colors.white70, // Color for locked levels
                      size: isCurrentLevel
                          ? 30
                          : 25, // Size changes based on current level
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WorldSelectionScreen extends StatefulWidget {
  final Function(bool) onWorldSelected;
  PuzzleModel puzzle;
  WorldSelectionScreen({
    super.key,
    required this.onWorldSelected,
    required this.puzzle,
  });

  @override
  State<WorldSelectionScreen> createState() => _WorldSelectionScreenState();
}

class _WorldSelectionScreenState extends State<WorldSelectionScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onButtonPressed(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _updateWallpaper(int newIndex) {
    setState(() {
      selectedWallpaper = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: getBackgroundColor(selectedWallpaper),
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _onButtonPressed(0),
                  child: Text(
                    'Stufe',
                    style: TextStyle(
                      fontSize: 25,
                      color: _currentPage == 0
                          ? primaryColor
                          : primaryColor.withAlpha(80),
                      fontWeight: _currentPage == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _onButtonPressed(1),
                  child: Text(
                    'Wallpaper',
                    style: TextStyle(
                      fontSize: 25,
                      color: _currentPage == 1
                          ? primaryColor
                          : primaryColor.withAlpha(80),
                      fontWeight: _currentPage == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            const Divider(
              height: 1,
              thickness: 1.5,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildWorldSelectionScreen(),
                  WallpaperSelectionWidget(
                      onWallpaperSelected: _updateWallpaper)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldSelectionScreen() {
    return SafeArea(
      bottom: false,
      top: false,
      child: SizedBox(
        child: Scaffold(
          backgroundColor: getBackgroundColor(selectedWallpaper),
          body: Container(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: ListView.builder(itemBuilder: (context, index) {
                      return index == 0
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 30.0, top: 30, bottom: 8),
                                      child: Text(
                                        "Entdecke dein geistiges Auge",
                                        style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30.0, bottom: 50, right: 30),
                                  child: Text(
                                    "Eine friedvolle Reise durch immer komplexer werdende Spektren",
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300),
                                  ),
                                ),
                              ],
                            )
                          : index < 7
                              ? GestureDetector(
                                  onTap: () {
                                    if (widget.puzzle.getCurrencyAmount() >=
                                        widget.puzzle.getNeededCurrencyAmount(
                                            index - 1)) {
                                      currentWorld = index;
                                      widget.onWorldSelected(true);
                                      if (widget.puzzle
                                              .getMaxLevelForWorld(index) ==
                                          0) {
                                        widget.puzzle
                                            .updateWorldLevel(index, 1);
                                        selectedLevel = 1;
                                      }
                                    }
                                  },
                                  child: WorldItem(
                                    puzzle: widget.puzzle,
                                    worldID: index,
                                  ),
                                )
                              : index == 7
                                  ? const SizedBox(
                                      height: 150,
                                    )
                                  : null;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorldItem extends StatelessWidget {
  const WorldItem({
    super.key,
    required this.puzzle,
    required this.worldID,
  });

  final PuzzleModel puzzle;
  final int worldID;

  @override
  Widget build(BuildContext context) {
    bool unlocked = puzzle.getMaxLevelForWorld(worldID) != 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 90.0),
      child: SizedBox(
        height: 150,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30.0,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: unlocked ||
                            (puzzle.getCurrencyAmount() >=
                                puzzle.getNeededCurrencyAmount(worldID - 1))
                        ? worlds[worldID - 1].colors[1]
                        : Colors.grey,
                    child: Center(
                      child: worlds[worldID - 1].maxLevel == -2
                          ? Icon(
                              Icons.where_to_vote,
                              color: primaryColor,
                              size: 60,
                            )
                          : !unlocked &&
                                  !(puzzle.getCurrencyAmount() >=
                                      puzzle
                                          .getNeededCurrencyAmount(worldID - 1))
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      currencyIcon,
                                      color: primaryColor,
                                      size: 25,
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "${puzzle.getNeededCurrencyAmount(worldID - 1)}",
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              : null,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30.0, top: 20),
                child: Column(
                  children: [
                    Text(
                      worlds[worldID - 1].name,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 19,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (unlocked)
                      Row(
                        children: [
                          Icon(
                            currencyIcon,
                            color: currencyColor,
                            size: 25,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            "${puzzle.getCurrencyAmountForWorld(worldID)}/${worlds[worldID - 1].anzahlLevels}",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (puzzle.getCurrencyAmount() >=
                            puzzle.getNeededCurrencyAmount(worldID - 1) &&
                        !unlocked)
                      Text(
                        "Du hast genügend\nSterne gesammelt,\num zu diesem Rätsel\nvoranzuschreiten.",
                        style: TextStyle(color: primaryColor),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _buildIconButton2 extends StatelessWidget {
  IconData icon;
  _buildIconButton2({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor, width: 1.5)),
        child: Icon(
          icon,
          color: primaryColor,
          size: 25,
        ));
  }
}

class SunnysDisplay extends StatelessWidget {
  PuzzleModel puzzle;
  SunnysDisplay({
    super.key,
    required this.puzzle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinProvider>(
      builder: (context, coinProvider, child) {
        return Row(
          children: [
            Icon(
              currencyIcon,
              color: currencyColor,
              size: 33,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              "${puzzle.getCurrencyAmount()}",
              style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
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
        foregroundColor: primaryColor,
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
              child: Text(
                AppLocalizations.of(context)?.unlockTitle ?? "",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)?.unlockBody ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildUnlockButton(
                context,
                AppLocalizations.of(context)?.openShop ?? "Open Shop",
                Colors.teal, () {
              Navigator.of(context).push(
                FadePageRoute(
                  page: const ShopScreen(),
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
                AppLocalizations.of(context)?.cancel ?? "Cancel",
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
