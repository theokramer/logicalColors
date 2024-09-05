import 'dart:ffi';
import 'dart:math';

import 'package:color_puzzle/action_Button.dart';
import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/custom_info_button.dart';
import 'package:color_puzzle/difficulty_bar.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_model.dart';
import 'shop_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'dart:async';

int selectedLevel = 1;
bool tutorialActive = true;

int levelsSinceAd = 0;

enum TutorialStep { none, step1, step2, step3, completed }

Timer? _timer; // Declare the timer at the class level

TutorialStep currentTutorialStep = TutorialStep.step1;

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool showBanner = false;
  bool showCoinAnimation = false;
  bool animationStarted = false;
  bool denyClick = true;
  double pi = 3.1415926535897932;
  bool isRemoveTileMode = false;
  final Random _random = Random();
  bool showStartBanner = (currentTutorialStep != TutorialStep.step1 &&
          currentTutorialStep != TutorialStep.step2 &&
          currentTutorialStep != TutorialStep.step3) ||
      !tutorialActive;
  int getsLightBulb = 0;
  final GlobalKey<PopupMenuButtonState> popUpKey = GlobalKey();

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  Future<void> saveTutorial(bool tutorial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialActive', tutorial);
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1712485313",
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
              });
              _loadRewardedAd();
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId:
          "ca-app-pub-3940256099942544/4411468910", // correct one: 'ca-app-pub-3263827122305139/6797409538'
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              //selectedLevel += 1;
            },
          );
          print("HIER");
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (levelsSinceAd > 5 && worlds[0].maxLevel > 10) {
      if (_interstitialAd == null) {
        _loadInterstitialAd();
      }

      levelsSinceAd = 0;
    }

    if (_rewardedAd == null) {
      _loadRewardedAd();
    }

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

    if (worlds[0].maxLevel > 10) {
      _bannerAd.load();
    }

    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 500));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tutorialActive == true) {
        switch (currentTutorialStep) {
          case TutorialStep.none:
            setState(() {
              tutorialActive = false;
              saveTutorial(tutorialActive);
            });
            break;

          case TutorialStep.step1:
            setState(() {
              currentTutorialStep = TutorialStep.step2;
            });
            break;

          case TutorialStep.step2:
            setState(() {
              currentTutorialStep = TutorialStep.step3;
              _showInfoDialogStart(context);
            });
            break;
          case TutorialStep.step3:
            setState(() {
              currentTutorialStep = TutorialStep.completed;
            });
            break;

          case TutorialStep.completed:
            setState(() {
              tutorialActive = false;
              currentTutorialStep = TutorialStep.none;
              saveTutorial(tutorialActive);
            });
            break;
        }
      }

      //Zeit erhöhen in Production
      if (currentTutorialStep == TutorialStep.none || tutorialActive == false) {
        _timer = Timer(const Duration(milliseconds: 7000), () {
          if (mounted) {
            setState(() {
              showStartBanner = false;
              denyClick = false;
            });
          }
        });
      } else {
        setState(() {
          showStartBanner = false;
          denyClick = false;
        });
      }

      //_showLevelStartInfo();
    });
  }

  Future<void> handleBuyHint() async {
    if (await CoinManager.loadCoins() >= 200) {
      subtractCoins(200);
      addHints(3);
    } else {}
    Navigator.pop(context);
  }

  Future<void> handleBuyHintSale() async {
    if (await CoinManager.loadCoins() >= 300) {
      subtractCoins(300);
      addHints(3);
    } else {}
    Navigator.pop(context);
  }

  void addCoins(int amount) async {
    await context
        .read<CoinProvider>()
        .addCoins(amount); // Verwende den Provider
  }

  void addHints(int amount) async {
    await context
        .read<HintsProvider>()
        .addHints(amount); // Verwende den Provider
  }

  void addRems(int amount) async {
    await context.read<RemsProvider>().addRems(amount); // Verwende den Provider
  }

  void subtractCoins(int amount) async {
    await context
        .read<CoinProvider>()
        .subtractCoins(amount); // Verwende den Provider
  }

  Future<void> handleBuyRem() async {
    if (await CoinManager.loadCoins() >= 200) {
      subtractCoins(200);
      addRems(5);
    } else {
      // Handle not enough coins
    }
    Navigator.pop(context);
  }

  void handleWatchAdForHints() {
    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        addHints(3);
      },
    );
    _loadRewardedAd();
  }

  void handleWatchAdForRems() {
    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        addRems(5);
      },
    );
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer
    _confettiController.dispose();
    _animationController.dispose();
    _bannerAd.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    Future.microtask(() => context.read<CoinProvider>().loadCoins());
    Future.microtask(() => context.read<HintsProvider>().loadHints());
    Future.microtask(() => context.read<RemsProvider>().loadRems());

    return Scaffold(
      backgroundColor: Colors.blue[50], // Playful background color

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
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            //Remove option to leave Screen when tutorial is active
                            tutorialActive
                                ? const Text("")
                                : Consumer<CoinProvider>(
                                    builder: (context, coinProvider, child) {
                                    return PopupMenuButton<String>(
                                      key: popUpKey,
                                      offset: const Offset(-10, 50),
                                      enabled: !denyClick,
                                      icon: const Icon(Icons.settings,
                                          color: Colors.white),
                                      onSelected: (String value) {
                                        switch (value) {
                                          case 'home':
                                            Navigator.of(context)
                                                .pushReplacement(
                                              FadePageRoute(
                                                page: ChangeNotifierProvider
                                                    .value(
                                                  value: puzzle,
                                                  child: const MainMenuScreen(),
                                                ),
                                              ),
                                            );
                                            break;
                                          case 'shop':
                                            Navigator.of(context).push(
                                              FadePageRoute(
                                                page: ChangeNotifierProvider
                                                    .value(
                                                  value: puzzle,
                                                  child: const ShopScreen(),
                                                ),
                                              ),
                                            );
                                            break;
                                          case 'refresh':
                                            if (coinProvider.coins >= 10 ||
                                                worlds[currentWorld - 1]
                                                        .maxLevel >
                                                    selectedLevel) {
                                              if (worlds[currentWorld - 1]
                                                      .maxLevel <=
                                                  selectedLevel) {
                                                coinProvider.subtractCoins(10);
                                              }
                                              puzzle.refreshGrid(
                                                  puzzle.maxMoves, puzzle.size);
                                            } else {
                                              Navigator.of(context).push(
                                                FadePageRoute(
                                                  page: ChangeNotifierProvider
                                                      .value(
                                                    value: puzzle,
                                                    child: const ShopScreen(),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            break;
                                          case "prev":
                                            selectedLevel -= 1;
                                            denyClick = false;
                                            Navigator.of(context)
                                                .pushReplacement(
                                              FadePageRoute(
                                                page: ChangeNotifierProvider(
                                                  create: (_) => PuzzleModel(
                                                      size: puzzle.getSizeAndMaxMoves(
                                                                  selectedLevel)[
                                                              "size"] ??
                                                          2,
                                                      level: puzzle.getSizeAndMaxMoves(
                                                                  selectedLevel)[
                                                              "maxMoves"] ??
                                                          2,
                                                      colorMapping: {
                                                        1: worlds[currentWorld -
                                                                1]
                                                            .colors[0],
                                                        2: worlds[currentWorld -
                                                                1]
                                                            .colors[1],
                                                        3: worlds[currentWorld -
                                                                1]
                                                            .colors[2],
                                                      }),
                                                  child: const PuzzleScreen(),
                                                ),
                                              ),
                                            );
                                          case 'next':
                                            if (coinProvider.coins >= 100 ||
                                                worlds[currentWorld - 1]
                                                        .maxLevel >
                                                    selectedLevel) {
                                              if (worlds[currentWorld - 1]
                                                      .maxLevel <=
                                                  selectedLevel) {
                                                coinProvider.subtractCoins(100);
                                              }
                                              //Watch Ad, when following level isn't unlocked

                                              if (selectedLevel >= 10 &&
                                                  worlds[currentWorld + 1]
                                                          .maxLevel ==
                                                      0) {
                                                puzzle.updateWorldLevel(
                                                    currentWorld + 1, 1);
                                              }
                                              if (selectedLevel < 100) {
                                                puzzle.updateWorldLevel(
                                                    currentWorld,
                                                    selectedLevel + 1);
                                                selectedLevel += 1;
                                                denyClick = false;
                                              }
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                FadePageRoute(
                                                  page: ChangeNotifierProvider(
                                                    create: (_) => PuzzleModel(
                                                        size: puzzle.getSizeAndMaxMoves(
                                                                    selectedLevel)[
                                                                "size"] ??
                                                            2,
                                                        level: puzzle.getSizeAndMaxMoves(
                                                                    selectedLevel)[
                                                                "maxMoves"] ??
                                                            2,
                                                        colorMapping: {
                                                          1: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[0],
                                                          2: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[1],
                                                          3: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[2],
                                                        }),
                                                    child: selectedLevel < 100
                                                        ? const PuzzleScreen()
                                                        : const MainMenuScreen(),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              Navigator.of(context).push(
                                                FadePageRoute(
                                                  page: ChangeNotifierProvider
                                                      .value(
                                                    value: puzzle,
                                                    child: const ShopScreen(),
                                                  ),
                                                ),
                                              );
                                            }
                                            break;
                                          case 'tutorial':
                                            tutorialActive = true;
                                            currentTutorialStep =
                                                TutorialStep.step1;
                                            selectedLevel = 1;
                                            currentWorld = 1;
                                            Navigator.of(context)
                                                .pushReplacement(
                                              FadePageRoute(
                                                page: ChangeNotifierProvider(
                                                  create: (_) => PuzzleModel(
                                                      size: 1,
                                                      level: 1,
                                                      colorMapping: {
                                                        1: worlds[currentWorld -
                                                                1]
                                                            .colors[0],
                                                        2: worlds[currentWorld -
                                                                1]
                                                            .colors[1],
                                                        3: worlds[currentWorld -
                                                                1]
                                                            .colors[2],
                                                      }),
                                                  child: const PuzzleScreen(),
                                                ),
                                              ),
                                            );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                        _buildPopupMenuItem('home', 'Home',
                                            Icons.home, Colors.indigo),
                                        _buildPopupMenuItem('shop', 'Shop',
                                            Icons.shopping_cart, Colors.indigo),
                                        _buildPopupMenuItem(
                                            'refresh',
                                            'New Level ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 10 Coins' : ""}',
                                            Icons.refresh,
                                            Colors.indigo),
                                        if (selectedLevel > 1)
                                          _buildPopupMenuItem(
                                              'prev',
                                              'Level ${selectedLevel - 1}',
                                              Icons.skip_previous,
                                              Colors.indigo),
                                        _buildPopupMenuItem(
                                            'next',
                                            'Level ${selectedLevel + 1} ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 100 Coins' : ""}',
                                            Icons.skip_next,
                                            Colors.indigo),
                                        /*_buildPopupMenuItem(
                                        'tutorial',
                                        'Watch the Tutorial',
                                        Icons.cast_for_education,
                                        Colors.indigo),*/
                                      ],
                                    );
                                  }),
                          ],
                        ),
                      ),
                      //if (MediaQuery.of(context).size.height <= 700)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Level $selectedLevel',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  //SizedBox(height: 10),
                  /*if (MediaQuery.of(context).size.height > 700)
                    Text(
                      'Level $selectedLevel',
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                      ),
                    ),*/

                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        showDifficultyInfo(context);
                      },
                      child: HorizontalDifficultyBar(
                          gridSize: puzzle
                              .size, // Assuming `puzzle.size` corresponds to the grid size
                          maxMoves: puzzle
                              .maxMoves, // Assuming `puzzle.maxMoves` is the maximum number of moves for the level
                          colors: worlds[currentWorld - 1].colors),
                    ),
                  ),
                  if (MediaQuery.of(context).size.height > 700)
                    const SizedBox(
                      height: 15,
                    ),
                  SizedBox(
                    height: 90,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 5, // Adjust depending on level position
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomInfoButton(
                                value: '', // No value needed here
                                targetColor:
                                    puzzle.targetColorNumber, // Target color
                                movesLeft: (puzzle.maxMoves -
                                    puzzle.moves), // No moves left needed here
                                iconPath: '', // No icon needed
                                backgroundColor: Colors.grey[100]!,
                                textColor: Colors.black,
                                isLarge: 0, // Increase size
                                blink: currentTutorialStep ==
                                        TutorialStep.completed &&
                                    tutorialActive,
                              ),
                              CustomInfoButton(
                                value: '', // No value needed here
                                targetColor: -1, // No target color needed here
                                movesLeft: (puzzle.maxMoves -
                                    puzzle.moves), // Number of moves left
                                iconPath: '', // No icon needed
                                backgroundColor: Colors.grey[100]!,
                                textColor: Colors.black,
                                isLarge: 0, // Increase size
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.of(context).size.height > 700)
                    const SizedBox(
                      height: 15,
                    ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: puzzle.size,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: (MediaQuery.of(context).size.height > 700)
                              ? 35.0
                              : 50),
                      itemCount: puzzle.size * puzzle.size,
                      itemBuilder: (context, index) {
                        int x = index ~/ puzzle.size;
                        int y = index % puzzle.size;
                        int colorNumber = puzzle.grid[x][y];
                        Color tileColor = puzzle.getColor(colorNumber);
                        bool isHintTile =
                            (x == puzzle.hintX && y == puzzle.hintY);

                        return ScaleTransition(
                          scale: _animation,
                          child: GestureDetector(
                            onTap: () {
                              if (!animationStarted &&
                                  !showBanner &&
                                  !denyClick) {
                                if (isRemoveTileMode) {
                                  // Remove the tile
                                  puzzle.clickTile(x, y, false, true);

                                  //_showSnackbar(context, "Tile removed.");
                                  setState(() {
                                    isRemoveTileMode =
                                        false; // Exit remove mode after removing a tile
                                  });
                                } else {
                                  puzzle.countClicks += 1;
                                  if (puzzle.maxMoves < 3) {
                                    if (puzzle.countClicks >
                                        3 * puzzle.maxMoves) {
                                      puzzle.getHint();
                                      puzzle.countClicks = 0;
                                    }
                                  } else {
                                    if (puzzle.countClicks >
                                        5 * puzzle.maxMoves) {
                                      puzzle.countClicks =
                                          double.negativeInfinity;
                                      showGadgetPopup(
                                          context,
                                          'Hints',
                                          handleBuyHintSale,
                                          handleWatchAdForHints,
                                          [Colors.amber, Colors.orange],
                                          false //Change this Line to true, if you want sale for 200 coins
                                          );
                                    }
                                  }

                                  puzzle.clickTile(x, y, false, false);
                                }

                                if (puzzle.isGridFilledWithTargetColor()) {
                                  puzzle.countClicks = 0;
                                  denyClick = true;
                                  levelsSinceAd++;

                                  if (worlds[currentWorld - 1].maxLevel >
                                      selectedLevel) {
                                    getsLightBulb = -1;
                                  } else {
                                    setState(() {
                                      getsLightBulb = ((_random.nextInt(8)) +
                                                  (calculateDifficulty(
                                                          puzzle.maxMoves,
                                                          puzzle.size) *
                                                      3))
                                              .floor() -
                                          7;
                                    });
                                  }

                                  _confettiController.play();
                                  HapticFeedback.heavyImpact();
                                  _animationController.forward().then((_) {
                                    Future.delayed(
                                        Duration(
                                            milliseconds: tutorialActive
                                                ? 600
                                                : 300), () {
                                      _animationController.reverse().then((_) {
                                        Future.delayed(
                                            Duration(
                                                milliseconds: tutorialActive
                                                    ? 1000
                                                    : 500), () {
                                          setState(() {
                                            showBanner = true;
                                          });
                                          if (_interstitialAd != null) {
                                            _interstitialAd?.show();
                                          }
                                        });
                                      });
                                    });
                                  });
                                } else {
                                  HapticFeedback.selectionClick();
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    tileColor.withOpacity(0.8),
                                    tileColor
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: isHintTile
                                    ? Border.all(color: Colors.amber, width: 5)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  colorNumber.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 3.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Consumer<HintsProvider>(
                            builder: (context, hintsProvider, child) {
                          return CustomActionButton(
                            icon: Icons.lightbulb,
                            onPressed: () async {
                              if (hintsProvider.hints > 0) {
                                bool hintUsed = await puzzle.getHint();
                                if (hintUsed) {
                                  // Your hint used logic here
                                } else {
                                  /*Future.delayed(Duration(milliseconds: 500), () {
                        puzzle.clearHint();
                      });*/
                                }
                              } else {
                                showGadgetPopup(
                                    context,
                                    'Hints',
                                    handleBuyHint,
                                    handleWatchAdForHints,
                                    [Colors.amber, Colors.orange],
                                    false);
                              }
                            },
                            count: hintsProvider
                                .hints, // Number of hints available
                            gradientColors: const [Colors.amber, Colors.orange],
                            iconColor: Colors.white,
                          );
                        }),
                        Consumer<RemsProvider>(
                            builder: (context, remsProvider, child) {
                          return CustomActionButton(
                            icon: Icons.colorize,
                            onPressed: () {
                              if (!denyClick) {
                                if (remsProvider.rems > 0) {
                                  setState(() {
                                    puzzle.removeRems(1);
                                    isRemoveTileMode = true;
                                  });
                                } else {
                                  showGadgetPopup(
                                      context,
                                      'Colorizer',
                                      handleBuyRem,
                                      handleWatchAdForRems,
                                      [
                                        const Color.fromARGB(255, 176, 2, 124),
                                        const Color.fromARGB(255, 255, 0, 81)
                                      ],
                                      false);
                                }
                              }
                            },
                            count: remsProvider
                                .rems, // Number of removes available
                            gradientColors: const [
                              Color.fromARGB(255, 176, 2, 124),
                              Color.fromARGB(255, 255, 0, 81)
                            ],
                            iconColor: Colors.white,
                          );
                        }),
                        CustomActionButton(
                          icon: Icons.undo,
                          onPressed: () {
                            if (!denyClick) {
                              puzzle.undoMove();
                            }
                          },
                          count: -1, // Infinite undo available
                          gradientColors: const [
                            Color.fromARGB(255, 255, 68, 0),
                            Colors.orangeAccent
                          ],

                          iconColor: Colors.white,
                        ),
                        CustomActionButton(
                          icon: Icons.refresh,
                          onPressed: () {
                            if (!denyClick) {
                              puzzle.grid = puzzle.savedGrid
                                  .map((row) => List<int>.from(row))
                                  .toList();
                              puzzle.resetMoves();
                              puzzle.moveWhereError = -1;
                              puzzle.clicks = puzzle.savedClicks
                                  .map((click) => List<int>.from(click))
                                  .toList();
                              puzzle.undoStack.clear();
                            }
                          },
                          count: -1, // Infinite refresh available
                          gradientColors: const [
                            Color.fromARGB(255, 63, 3, 165),
                            Colors.deepPurpleAccent
                          ],
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  )
                ],
              ),

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

              tutorialActive && currentTutorialStep != TutorialStep.none
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedCustomOverlay(
                          blink: currentTutorialStep == TutorialStep.step2 &&
                              tutorialActive,
                          message: currentTutorialStep == TutorialStep.step2 &&
                                  tutorialActive
                              ? 'Click on the tile to change its color'
                              : currentTutorialStep == TutorialStep.step3 &&
                                      tutorialActive
                                  ? 'Click to change color of its neighbours'
                                  : "Fill the Grid with the Color indicated!",
                          onClose: () {},
                        ),
                      ],
                    )
                  : const SizedBox(),

              if (showBanner && !animationStarted)
                Positioned.fill(
                  child: Stack(
                    children: [
                      // Background overlay with a subtle dark tint
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main banner with rounded corners and light shadow
                              GestureDetector(
                                onTap: () {
                                  // Button action
                                  if (!animationStarted) {
                                    setState(() {
                                      animationStarted = true;
                                      showCoinAnimation = true;
                                      if (selectedLevel < 100) {
                                        puzzle.updateWorldLevel(
                                            currentWorld, selectedLevel + 1);
                                        selectedLevel += 1;
                                        denyClick = false;
                                      }

                                      if (selectedLevel >= 69 &&
                                          currentWorld <= 4) if (worlds[
                                                  currentWorld + 1]
                                              .maxLevel ==
                                          0) {
                                        puzzle.updateWorldLevel(
                                            currentWorld + 1, 1);
                                      }
                                    });

                                    // Delay navigation to ensure coin animation completes
                                    Future.delayed(
                                        const Duration(milliseconds: 800), () {
                                      puzzle.addCoins(puzzle.coinsEarned);
                                      if (getsLightBulb == 1) {
                                        setState(() {
                                          puzzle.addHints(1);
                                        });
                                      }
                                      if (getsLightBulb == 2) {
                                        setState(() {
                                          puzzle.addRems(1);
                                        });
                                      }
                                      if (getsLightBulb >= 3) {
                                        setState(() {
                                          puzzle.addHints(2);
                                        });
                                      }
                                      denyClick = false;

                                      Navigator.of(context).pushReplacement(
                                        FadePageRoute(
                                          page: ChangeNotifierProvider(
                                            create: (_) => PuzzleModel(
                                              size: puzzle.getSizeAndMaxMoves(
                                                      selectedLevel)["size"] ??
                                                  2,
                                              level: puzzle.getSizeAndMaxMoves(
                                                          selectedLevel)[
                                                      "maxMoves"] ??
                                                  2,
                                              colorMapping: {
                                                1: worlds[currentWorld - 1]
                                                    .colors[0],
                                                2: worlds[currentWorld - 1]
                                                    .colors[1],
                                                3: worlds[currentWorld - 1]
                                                    .colors[2],
                                              },
                                            ),
                                            child: selectedLevel < 100
                                                ? const PuzzleScreen()
                                                : const MainMenuScreen(),
                                          ),
                                        ),
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 30, horizontal: 30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title text
                                      Text(
                                        'Level Complete!',
                                        style: TextStyle(
                                          color: Colors.blueGrey[800],
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Quicksand',
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      // Coin display or animation
                                      Row(
                                        mainAxisAlignment: getsLightBulb >= 1
                                            ? MainAxisAlignment.spaceAround
                                            : MainAxisAlignment.center,
                                        children: [
                                          animationStarted
                                              ? const SizedBox(height: 100)
                                              : _buildCoinDisplay(
                                                  puzzle.coinsEarned),
                                          getsLightBulb >= 1
                                              ? Row(children: [
                                                  (Icon(
                                                      getsLightBulb == 1 ||
                                                              getsLightBulb >= 3
                                                          ? Icons.lightbulb
                                                          : Icons.colorize,
                                                      color: Colors.amber,
                                                      size: 80)),
                                                  const SizedBox(width: 30),
                                                  Text(
                                                    getsLightBulb >= 3
                                                        ? '2'
                                                        : '1',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ])
                                              : const SizedBox(),
                                        ],
                                      ),

                                      const SizedBox(height: 20),
                                      // Continue button
                                      GestureDetector(
                                          onTap: () {
                                            if (!animationStarted) {
                                              setState(() {
                                                animationStarted = true;
                                                showCoinAnimation = true;
                                                if (selectedLevel < 100) {
                                                  puzzle.updateWorldLevel(
                                                      currentWorld,
                                                      selectedLevel + 1);
                                                  selectedLevel += 1;
                                                  denyClick = false;
                                                }
                                                if (selectedLevel >= 69 &&
                                                    worlds[currentWorld + 1]
                                                            .maxLevel ==
                                                        0) {
                                                  puzzle.updateWorldLevel(
                                                      currentWorld + 1, 1);
                                                }
                                              });

                                              // Delay navigation to ensure coin animation completes
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 800), () {
                                                puzzle.addCoins(
                                                    puzzle.coinsEarned);

                                                if (getsLightBulb == 1) {
                                                  setState(() {
                                                    puzzle.addHints(1);
                                                  });
                                                }
                                                if (getsLightBulb == 2) {
                                                  setState(() {
                                                    puzzle.addRems(1);
                                                  });
                                                }
                                                if (getsLightBulb >= 3) {
                                                  setState(() {
                                                    puzzle.addHints(2);
                                                  });
                                                }
                                                denyClick = false;

                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  FadePageRoute(
                                                    page:
                                                        ChangeNotifierProvider(
                                                      create: (_) =>
                                                          PuzzleModel(
                                                        size: puzzle.getSizeAndMaxMoves(
                                                                    selectedLevel)[
                                                                "size"] ??
                                                            2,
                                                        level: puzzle.getSizeAndMaxMoves(
                                                                    selectedLevel)[
                                                                "maxMoves"] ??
                                                            2,
                                                        colorMapping: {
                                                          1: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[0],
                                                          2: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[1],
                                                          3: worlds[
                                                                  currentWorld -
                                                                      1]
                                                              .colors[2],
                                                        },
                                                      ),
                                                      child: selectedLevel < 100
                                                          ? const PuzzleScreen()
                                                          : const MainMenuScreen(),
                                                    ),
                                                  ),
                                                );
                                              });
                                            }
                                          },
                                          child: const SizedBox(
                                              height: 60, child: AnimatedText())
                                          /*ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Next Level',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ), */
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Confetti effect
              if (animationStarted && showCoinAnimation)
                CoinAnimation(
                  start: Offset(MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2),
                  end: const Offset(50, 75),
                  numberOfCoins: puzzle.coinsEarned,
                ),

              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality:
                    BlastDirectionality.explosive, // Adjusts the direction
                minBlastForce: 5,
                maxBlastForce: 20,
                emissionFrequency: 0.3,
                numberOfParticles: 15,
                gravity: 0.1,
                colors: const [
                  Colors.lightBlueAccent,
                  Colors.lightGreen,
                  Colors.pinkAccent,
                  Colors.yellow
                ],
              ),

              if (showStartBanner)
                GestureDetector(
                    onTap: () {
                      if (showStartBanner) {
                        setState(() {
                          showStartBanner = false;
                          denyClick = false;
                        });
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.transparent,
                      child: GestureDetector(
                        onTap: !tutorialActive
                            ? () {
                                setState(() {
                                  showStartBanner = false;
                                  denyClick = false;
                                });
                              }
                            : null,
                        child: Center(
                          child: AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            contentPadding: const EdgeInsets.all(20),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Level $selectedLevel',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                HorizontalDifficultyBar(
                                    gridSize: puzzle.size,
                                    maxMoves: puzzle.maxMoves,
                                    colors: worlds[currentWorld - 1].colors),
                                Wrap(
                                  children: [
                                    Row(
                                      children: [
                                        CustomInfoButton(
                                          value: '', // No value needed here
                                          targetColor: puzzle
                                              .targetColorNumber, // Target color
                                          movesLeft:
                                              -1, // No moves left needed here
                                          iconPath: '', // No icon needed
                                          backgroundColor: Colors.grey[200]!,
                                          textColor: Colors.black,
                                          isLarge: 1, // Increase size
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        CustomInfoButton(
                                          value: '', // No value needed here
                                          targetColor:
                                              -1, // No target color needed here
                                          movesLeft: puzzle
                                              .maxMoves, // Number of moves
                                          iconPath: '', // No icon needed
                                          backgroundColor: Colors.grey[200]!,
                                          textColor: Colors.black,
                                          isLarge: 1, // Increase size
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        CustomInfoButton(
                                          value:
                                              '${puzzle.size}x${puzzle.size}', // Display grid size
                                          targetColor:
                                              -1, // No target color needed here
                                          movesLeft:
                                              -1, // No moves left needed here
                                          iconPath: '', // No icon needed
                                          backgroundColor: Colors.grey[200]!,
                                          textColor: Colors.black,
                                          isLarge: 1, // Increase size
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialogStart(BuildContext contex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Grid einfärben'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              const Text(
                  'Fülle das gesamte Raster mit der angezeigten Farbe. Wenn du ein Feld anklickst, verändert sich dessen Farbe und die Farbe aller angrenzenden Felder.'),
              const SizedBox(height: 30), // Space between text and GIF
              Image.asset(
                'images/tutorial_animation.gif', // Replace with your local path to the GIF
                height: 250, // Adjust the height as needed
                fit: BoxFit
                    .cover, // Adjust to cover or contain based on the look you want
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Öffnet den Info-Screen, wenn die Schwierigkeitsleiste angeklickt wird.
  void showDifficultyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Difficulty Explanation'),
          content: const Text(
            'The difficulty bar indicates how challenging the current puzzle is. '
            'Light segments indicate an easier puzzle, darker segments indicate moderate difficulty, '
            'and dark segments indicate a higher level of difficulty. The bar fills up based on the '
            'maximum number of moves and grid size, providing a visual representation of the challenge level.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLevelStartInfo() {
    final puzzle = Provider.of<PuzzleModel>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level $selectedLevel',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomInfoButton(
                    value: '',
                    targetColor: puzzle.targetColorNumber,
                    movesLeft: -1,
                    iconPath: '',
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: 0,
                  ),
                  CustomInfoButton(
                    value: '',
                    targetColor: -1,
                    movesLeft: puzzle.maxMoves,
                    iconPath: '',
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: 0,
                  ),
                  CustomInfoButton(
                    value: '${puzzle.size}x${puzzle.size}',
                    targetColor: -1,
                    movesLeft: -1,
                    iconPath: '',
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: 0,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showGadgetPopup(
      BuildContext context,
      String gadgetName,
      Function onBuyPressed,
      Function onWatchAdPressed,
      List<Color> gradientColors,
      bool sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.blueGrey[400],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(25),
            height: 400, // Höhe angepasst
            width: MediaQuery.of(context).size.width * 0.75, // Breite angepasst
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sale
                      ? "Get more $gadgetName with a 200 Coins discount"
                      : 'Get more $gadgetName',
                  style: const TextStyle(
                    color: Colors.white, // Farbe angepasst
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // Größe angepasst
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gadgetName == "Colorizer"
                          ? Icons.colorize
                          : Icons.lightbulb,
                      size: 60, // Größe des Icons
                      color: gradientColors.first, // Farbe des Icons
                    ),
                    const SizedBox(
                      width: 25,
                    ),
                    Text(
                      gadgetName == "Colorizer"
                          ? 'x5'
                          : 'x3', // Anzahl der Aktionen
                      style: TextStyle(
                        color: gradientColors.first,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        onWatchAdPressed();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text(
                        'Watch Ad',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor:
                            gradientColors.first, // Farbe angepasst
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Consumer<CoinProvider>(
                        builder: (context, coinProvider, child) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          coinProvider.coins >= 300
                              ? onBuyPressed()
                              : Navigator.of(context).popAndPushNamed("/shop");
                        },
                        icon: const Icon(Icons.monetization_on),
                        label: Text(
                          sale ? '100 Coins' : '200 Coins',
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor:
                              gradientColors.first, // Farbe angepasst
                          foregroundColor: Colors.white,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

/*Widget buildTutorialOverlay() {
  switch (currentTutorialStep) {
    case TutorialStep.step1:
      return Center(
        child: AlertDialog(
          title: Text("Step 1: Tap the Tile"),
          content: Text("Tap the tile to change its color."),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  showStartBanner = false;
                  denyClick = false;
                });
              },
              child: Text("Got it!"),
            ),
          ],
        ),
      );
    case TutorialStep.step2:
      return Center(
        child: AlertDialog(
          title: Text("Step 2: Tap the Correct Tile"),
          content: Text("Tap the correct tile to change its color, including neighboring tiles."),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  showStartBanner = false;
                  denyClick = false;
                });
              },
              child: Text("Next"),
            ),
          ],
        ),
      );
    default:
      return SizedBox.shrink();
  }
}*/

  PopupMenuEntry<String> _buildPopupMenuItem(
      String value, String text, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildCoinDisplay(int coinsEarned) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/coins.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 30),
          Text(
            '$coinsEarned',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton(
      {required IconData icon,
      required Color color,
      required void Function() onPressed,
      required int count}) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

Widget _buildIconButton(
    {required IconData icon,
    required Color color,
    required void Function() onPressed}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(2, 2),
        ),
      ],
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    ),
  );
}

Widget _buildTargetColorBox(Color targetColor, int targetColorNumber) {
  return Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: targetColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 3,
        ),
      ],
    ),
    child: Center(
      child: Text(
        targetColorNumber.toString(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ));
}

class AnimatedText extends StatefulWidget {
  const AnimatedText({super.key});

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.indigo[300],
      end: Colors.indigo[500],
    ).animate(_controller);

    _sizeAnimation = Tween<double>(
      begin: 25,
      end: 28,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          'Tap to claim',
          style: TextStyle(
            color: _colorAnimation.value,
            fontSize: _sizeAnimation.value,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var opacityAnimation = animation.drive(tween);
            return FadeTransition(opacity: opacityAnimation, child: child);
          },
          transitionDuration:
              const Duration(milliseconds: 500), // Dauer der Animation
        );
}

class CoinAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final int numberOfCoins;

  const CoinAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.numberOfCoins,
  });

  @override
  _CoinAnimationState createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _positionAnimation;
  late List<Widget> _coins;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
          milliseconds: 1500), // Duration for the entire animation
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _coins = List.generate(
      widget.numberOfCoins,
      (index) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double scale = _scaleAnimation.value;
          final double progress = _positionAnimation.value;
          final double dx =
              widget.start.dx + progress * (widget.end.dx - widget.start.dx);
          final double dy =
              widget.start.dy + progress * (widget.end.dy - widget.start.dy);

          return Positioned(
            left: dx - (12 * scale), // Center the coin correctly based on scale
            top: dy - (12 * scale), // Center the coin correctly based on scale
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'images/coins.png',
                width: 24,
                height: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: _coins,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
