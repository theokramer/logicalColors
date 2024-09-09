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

int selectedLevel = 1;
bool tutorialActive = true;

int levelsSinceAd = 0;

enum TutorialStep { none, step1, step2, step3, step4, step5, completed }

Timer? _timer; // Declare the timer at the class level

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
  bool changeTextStep5 = false;
  final Random _random = Random();
  bool showResetGadgetHint = false;
  bool showStartBanner = (currentTutorialStep != TutorialStep.step1 &&
          currentTutorialStep != TutorialStep.step2 &&
          currentTutorialStep != TutorialStep.step3 &&
          false) ||
      (!tutorialActive && false); // delete && false when wanted
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

  void _showPurchaseDialog(
      BuildContext context, String title, int amount, bool ad) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Damit das Dialogfenster nicht außerhalb geschlossen werden kann
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
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
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$title!',
                  style: TextStyle(
                    color: Colors.blueGrey[800],
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    amount == 3
                        ? const Icon(
                            Icons.lightbulb,
                            size: 50,
                            color: Colors.amber,
                          )
                        : amount == 5
                            ? const Icon(Icons.colorize,
                                size: 50, color: Colors.redAccent)
                            : Image.asset(
                                'images/Crystals.png',
                                height: 50,
                              ),
                    const SizedBox(width: 20),
                    Text(
                      '+$amount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    amount == 3
                        ? title == "Moves earned"
                            ? addMoves(3)
                            : addHints(3)
                        : addRems(5);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Great',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    if (levelsSinceAd > 5 && worlds[0].maxLevel > 10 && !noAds) {
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

    if (worlds[0].maxLevel > 10 && !noAds) {
      _bannerAd.load();
    }
    setState(() {
      showStartBanner = false;
      denyClick = false;
    });
    //Zeit erhöhen in Production
    /*if (currentTutorialStep == TutorialStep.none || tutorialActive == false) {
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
    }*/

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentTutorialStep == TutorialStep.step3) {
        _showInfoDialogStart(context);
      }
      if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
        showUnlockWorldsDialog();
      }
    });
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
  }

  List<PopupMenuEntry<String>> _showPopupMenu() {
    return <PopupMenuEntry<String>>[
      _buildPopupMenuItem('home', 'Home', Icons.home, Colors.indigo),
      _buildPopupMenuItem('shop', 'Shop', Icons.shopping_cart, Colors.indigo),
      _buildPopupMenuItem(
          'refresh',
          'New Level ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 10 Crystals' : ""}',
          Icons.refresh,
          Colors.indigo),
      if (selectedLevel > 1)
        _buildPopupMenuItem('prev', 'Level ${selectedLevel - 1}',
            Icons.skip_previous, Colors.indigo),
      _buildPopupMenuItem(
          'next',
          'Level ${selectedLevel + 1} ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 100 Crystals' : ""}',
          Icons.skip_next,
          Colors.indigo),
    ];
  }

  void showUnlockWorldsDialog() {
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
                  'Unlocking all Worlds',
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
                  Navigator.of(context).pushReplacement(
                    FadePageRoute(
                      page: const MainMenuScreen(),
                    ),
                  );
                },
                child: Text(
                  'Back to Home',
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

  Future<void> handleBuyHint() async {
    /*if (await CoinManager.loadCrystals() >= 200) {
      subtractCrystals(200);
      
    } else {}*/
    addHints(3);
    Navigator.pop(context);
  }

  Future<void> handleBuyMoves() async {
    if (await CoinManager.loadCrystals() >= 150) {
      subtractCrystals(150);
      addMoves(3);
    } else {}
    Navigator.pop(context);
  }

  void handleWatchAdForMoves() {
    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(context, "Moves earned", 3, true);
      },
    );
    _loadRewardedAd();
  }

  Future<void> handleBuyHintSale() async {
    if (await CoinManager.loadCrystals() >= 300) {
      subtractCrystals(300);
      addHints(3);
    } else {}
    Navigator.pop(context);
  }

  void addCrystals(int amount) async {
    await context
        .read<CoinProvider>()
        .addCrystals(amount); // Verwende den Provider
  }

  void addHints(int amount) async {
    await context
        .read<HintsProvider>()
        .addHints(amount); // Verwende den Provider
  }

  void addMoves(int amount) async {
    context.read<PuzzleModel>().addMoves(amount); // Verwende den Provider
  }

  void addRems(int amount) async {
    await context.read<RemsProvider>().addRems(amount); // Verwende den Provider
  }

  void subtractCrystals(int amount) async {
    await context
        .read<CoinProvider>()
        .subtractCrystals(amount); // Verwende den Provider
  }

  Future<void> handleBuyRem() async {
    /*if (await CoinManager.loadCrystals() >= 200) {
      subtractCrystals(200);
      
    } else {
      // Handle not enough Crystals
    }*/
    addRems(5);
    Navigator.pop(context);
  }

  void handleWatchAdForHints() {
    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(context, "Hints earned", 3, true);
      },
    );
    _loadRewardedAd();
  }

  void handleWatchAdForRems() {
    _rewardedAd?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(context, "Colorizer earned", 5, true);
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
    Future.microtask(() => context.read<CoinProvider>().loadCrystals());
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      children: [
                        // Left side with PopupMenuButton
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: tutorialActive
                                ? const SizedBox
                                    .shrink() // Hide when tutorial is active
                                : Consumer<CoinProvider>(
                                    builder: (context, coinProvider, child) {
                                      return PopupMenuButton<String>(
                                        key: popUpKey,
                                        offset: const Offset(10, 50),
                                        enabled: !denyClick,
                                        icon: const Icon(Icons.pause,
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
                                                    child:
                                                        const MainMenuScreen(),
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
                                              if ((!worlds.last.unlocked &&
                                                      selectedLevel > 14) &&
                                                  false) {
                                                showUnlockWorldsDialog();
                                              } else {
                                                if (coinProvider.Crystals >=
                                                        10 ||
                                                    worlds[currentWorld - 1]
                                                            .maxLevel >
                                                        selectedLevel) {
                                                  if (worlds[currentWorld - 1]
                                                          .maxLevel <=
                                                      selectedLevel) {
                                                    coinProvider
                                                        .subtractCrystals(10);
                                                  }
                                                  puzzle.refreshGrid(
                                                      puzzle.maxMoves,
                                                      puzzle.size);
                                                } else {
                                                  Navigator.of(context).push(
                                                    FadePageRoute(
                                                      page:
                                                          ChangeNotifierProvider
                                                              .value(
                                                        value: puzzle,
                                                        child:
                                                            const ShopScreen(),
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
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
                                                      },
                                                    ),
                                                    child: const PuzzleScreen(),
                                                  ),
                                                ),
                                              );
                                            case 'next':
                                              if ((!worlds.last.unlocked &&
                                                      selectedLevel > 14) &&
                                                  false) {
                                                showUnlockWorldsDialog();
                                              } else {
                                                if (coinProvider.Crystals >=
                                                        100 ||
                                                    worlds[currentWorld - 1]
                                                            .maxLevel >
                                                        selectedLevel) {
                                                  if (worlds[currentWorld - 1]
                                                          .maxLevel <=
                                                      selectedLevel) {
                                                    coinProvider
                                                        .subtractCrystals(100);
                                                  }

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
                                                        child: selectedLevel <
                                                                100
                                                            ? const PuzzleScreen()
                                                            : const MainMenuScreen(),
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  Navigator.of(context).push(
                                                    FadePageRoute(
                                                      page:
                                                          ChangeNotifierProvider
                                                              .value(
                                                        value: puzzle,
                                                        child:
                                                            const ShopScreen(),
                                                      ),
                                                    ),
                                                  );
                                                }
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
                                                      },
                                                    ),
                                                    child: const PuzzleScreen(),
                                                  ),
                                                ),
                                              );
                                          }
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            _showPopupMenu(),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        // Centered text
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'World $currentWorld – Level $selectedLevel',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                          ),
                        ),
                        // Right side with CustomInfoButton
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Consumer<CoinProvider>(
                              builder: (context, coinProvider, child) {
                                return CustomInfoButton(
                                  value: '${coinProvider.Crystals}',
                                  targetColor: -1,
                                  movesLeft: -1,
                                  iconPath: 'images/Crystals.png',
                                  backgroundColor: Colors.black45,
                                  textColor: Colors.white,
                                  isLarge: 2,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                blink:
                                    currentTutorialStep == TutorialStep.step4 &&
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
                                blink:
                                    currentTutorialStep == TutorialStep.step4 &&
                                        tutorialActive,
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
                      physics: const NeverScrollableScrollPhysics(),
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
                              if ((!worlds.last.unlocked &&
                                      selectedLevel > 14) &&
                                  false) {
                                showUnlockWorldsDialog();
                              } else {
                                if (!animationStarted &&
                                    !showBanner &&
                                    !denyClick &&
                                    (puzzle.maxMoves > puzzle.moves ||
                                        isRemoveTileMode)) {
                                  if (isRemoveTileMode) {
                                    // Remove the tile
                                    puzzle.clickTile(x, y, false, true);
                                    puzzle.removeRems(1);
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
                                      /*if (puzzle.countClicks >
                                        5 * puzzle.maxMoves) {
                                      puzzle.countClicks =
                                          double.negativeInfinity;
                                      showGadgetPopup(
                                          context,
                                          'Hints',
                                          handleBuyHintSale,
                                          handleWatchAdForHints,
                                          [Colors.amber, Colors.orange],
                                          false //Change this Line to true, if you want sale for 200 Crystals
                                          );
                                    }*/
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
                                                        4.4))
                                                .floor() -
                                            6;
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
                                        _animationController
                                            .reverse()
                                            .then((_) {
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
                                if (puzzle.moves >= puzzle.maxMoves &&
                                    puzzle.maxMoves > 2 &&
                                    !puzzle.isGridFilledWithTargetColor()) {
                                  showGadgetPopup(
                                      context,
                                      'Moves',
                                      handleBuyMoves,
                                      handleWatchAdForMoves,
                                      [Colors.indigo, Colors.indigoAccent],
                                      false);
                                } else if (puzzle.maxMoves == puzzle.moves &&
                                    tutorialActive) {
                                  showResetGadgetHint = true;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Consumer<HintsProvider>(
                          builder: (context, hintsProvider, child) {
                        return CustomActionButton(
                          icon: Icons.lightbulb,
                          onPressed: () async {
                            if ((!worlds.last.unlocked && selectedLevel > 14) &&
                                false) {
                              showUnlockWorldsDialog();
                            } else {
                              if (currentTutorialStep == TutorialStep.step5) {
                                changeTextStep5 = true;
                              }
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
                            }
                          },
                          count:
                              hintsProvider.hints, // Number of hints available
                          gradientColors: const [Colors.amber, Colors.orange],
                          iconColor: Colors.white,
                          blink: currentTutorialStep == TutorialStep.step5 &&
                              !changeTextStep5,
                          borderColor: Colors.transparent,
                        );
                      }),
                      Consumer<RemsProvider>(
                          builder: (context, remsProvider, child) {
                        return CustomActionButton(
                          icon: Icons.colorize,
                          onPressed: () {
                            if ((!worlds.last.unlocked && selectedLevel > 14) &&
                                false) {
                              showUnlockWorldsDialog();
                            } else {
                              if (!denyClick) {
                                if (remsProvider.rems > 0) {
                                  setState(() {
                                    if (isRemoveTileMode) {
                                      isRemoveTileMode = false;
                                    } else {
                                      isRemoveTileMode = true;
                                    }
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
                            }
                          },
                          count:
                              remsProvider.rems, // Number of removes available
                          gradientColors: const [
                            Color.fromARGB(255, 176, 2, 124),
                            Color.fromARGB(255, 255, 0, 81)
                          ],
                          iconColor: Colors.white,
                          blink:
                              currentTutorialStep == TutorialStep.completed &&
                                  !isRemoveTileMode,
                          borderColor: isRemoveTileMode
                              ? Colors.amber
                              : Colors.transparent,
                        );
                      }),
                      CustomActionButton(
                        icon: Icons.undo,
                        onPressed: () {
                          if (!denyClick) {
                            puzzle.undoMove();
                            setState(() {
                              showResetGadgetHint = false;
                            });
                          }
                        },
                        count: -1, // Infinite undo available
                        gradientColors: const [
                          Color.fromARGB(255, 255, 68, 0),
                          Colors.orangeAccent
                        ],

                        iconColor: Colors.white,
                        blink: tutorialActive &&
                            puzzle.maxMoves == puzzle.moves &&
                            showResetGadgetHint,
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
                            setState(() {
                              showResetGadgetHint = false;
                            });
                          }
                        },
                        count: -1, // Infinite refresh available
                        gradientColors: const [
                          Color.fromARGB(255, 63, 3, 165),
                          Colors.deepPurpleAccent
                        ],
                        iconColor: Colors.white,
                        blink: tutorialActive &&
                            puzzle.maxMoves == puzzle.moves &&
                            showResetGadgetHint,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: !noAds && _isBannerAdReady ? 55 : 0,
                  )
                ],
              ),

              if (_isBannerAdReady && !noAds)
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

              tutorialActive && currentTutorialStep != TutorialStep.none ||
                      isRemoveTileMode
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedCustomOverlay(
                          blink: currentTutorialStep == TutorialStep.step2 &&
                              tutorialActive,
                          message: isRemoveTileMode
                              ? "Click on a tile to increase its value by one. Tap again on the gadget to cancel."
                              : showResetGadgetHint
                                  ? "You have no moves left. Use the reset or the undo gadget to try again."
                                  : currentTutorialStep == TutorialStep.step2 &&
                                          tutorialActive
                                      ? 'Click on the tile to change its color'
                                      : currentTutorialStep ==
                                                  TutorialStep.step3 &&
                                              tutorialActive
                                          ? 'Click on the tile to also change the color of its neighbours'
                                          : currentTutorialStep ==
                                                      TutorialStep.step4 &&
                                                  tutorialActive
                                              ? "Fill the Grid with the color indicated. You have only one move!"
                                              : currentTutorialStep ==
                                                          TutorialStep.step5 &&
                                                      tutorialActive
                                                  ? (changeTextStep5
                                                      ? "Finish the level by filling the whole grid with the color indicated."
                                                      : "If you struggle with the puzzle, use a hint. In this level you have two moves.")
                                                  : "You can also use the Colorizer, it increases a single tile by one. Try it out!",
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
                                                currentTutorialStep =
                                                    TutorialStep.step2;
                                              });
                                              break;

                                            case TutorialStep.step2:
                                              setState(() {
                                                currentTutorialStep =
                                                    TutorialStep.step3;
                                              });
                                              break;
                                            case TutorialStep.step3:
                                              setState(() {
                                                currentTutorialStep =
                                                    TutorialStep.step4;
                                              });
                                              break;
                                            case TutorialStep.step4:
                                              setState(() {
                                                currentTutorialStep =
                                                    TutorialStep.step5;
                                              });
                                              break;
                                            case TutorialStep.step5:
                                              setState(() {
                                                currentTutorialStep =
                                                    TutorialStep.completed;
                                              });
                                              break;

                                            case TutorialStep.completed:
                                              setState(() {
                                                tutorialActive = false;
                                                currentTutorialStep =
                                                    TutorialStep.none;
                                                saveTutorial(tutorialActive);
                                              });
                                              break;
                                          }
                                        }

                                        //_showLevelStartInfo();
                                        puzzle.saveTutorialStep(
                                            currentTutorialStep);

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
                                      puzzle.addCrystals(puzzle.CrystalsEarned);
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
                                                  puzzle.CrystalsEarned),
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
                                                  if (tutorialActive == true) {
                                                    switch (
                                                        currentTutorialStep) {
                                                      case TutorialStep.none:
                                                        setState(() {
                                                          tutorialActive =
                                                              false;
                                                          saveTutorial(
                                                              tutorialActive);
                                                        });
                                                        break;

                                                      case TutorialStep.step1:
                                                        setState(() {
                                                          currentTutorialStep =
                                                              TutorialStep
                                                                  .step2;
                                                        });
                                                        break;

                                                      case TutorialStep.step2:
                                                        setState(() {
                                                          currentTutorialStep =
                                                              TutorialStep
                                                                  .step3;
                                                          _showInfoDialogStart(
                                                              context);
                                                        });
                                                        break;
                                                      case TutorialStep.step3:
                                                        setState(() {
                                                          currentTutorialStep =
                                                              TutorialStep
                                                                  .step4;
                                                        });
                                                        break;
                                                      case TutorialStep.step4:
                                                        setState(() {
                                                          currentTutorialStep =
                                                              TutorialStep
                                                                  .step5;
                                                        });
                                                        break;
                                                      case TutorialStep.step5:
                                                        setState(() {
                                                          currentTutorialStep =
                                                              TutorialStep
                                                                  .completed;
                                                        });
                                                        break;

                                                      case TutorialStep
                                                            .completed:
                                                        setState(() {
                                                          tutorialActive =
                                                              false;
                                                          currentTutorialStep =
                                                              TutorialStep.none;
                                                          saveTutorial(
                                                              tutorialActive);
                                                        });
                                                        break;
                                                    }
                                                  }
                                                  print(currentTutorialStep);

                                                  //_showLevelStartInfo();
                                                  puzzle.saveTutorialStep(
                                                      currentTutorialStep);
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
                                                puzzle.addCrystals(
                                                    puzzle.CrystalsEarned);

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
                  numberOfCrystals: puzzle.CrystalsEarned,
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
          title: const Text('Color the grid'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              const Text(
                  'Fill the entire grid with the displayed color. When you click on a cell, its color and the color of all adjacent cells will change.'),
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
            height: 450, // Adjust height
            width: MediaQuery.of(context).size.width * 0.75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sale
                      ? "Get more $gadgetName with a 200 Crystals discount"
                      : 'Get more $gadgetName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  gadgetName == "Colorizer"
                      ? "Choose how to get your Colorizer"
                      : gadgetName == "Hints"
                          ? "Choose how to get your Hints"
                          : "Choose how to get your Moves",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gadgetName == "Colorizer"
                          ? Icons.colorize
                          : gadgetName == "Hints"
                              ? Icons.lightbulb
                              : Icons.bolt,
                      size: 60,
                      color: gradientColors.first,
                    ),
                    const SizedBox(
                      width: 25,
                    ),
                    Text(
                      gadgetName == "Moves" ? "x3" : gadgetName,
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
                      label: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          gadgetName == "Colorizer"
                              ? 'Watch Ad for\n2 Colorizer'
                              : gadgetName == "Hints"
                                  ? 'Watch Ad for\n3 Hints'
                                  : "Watch Ad",
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: gradientColors.first,
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
                          /*coinProvider.Crystals >= 200
                              ? onBuyPressed()
                              : Navigator.of(context).popAndPushNamed("/shop");*/
                          if (gadgetName == "Moves") {
                            coinProvider.Crystals >= 150
                                ? onBuyPressed()
                                : Navigator.of(context)
                                    .popAndPushNamed("/shop");
                          } else {
                            onBuyPressed();
                          }
                        },
                        icon: const Icon(Icons.monetization_on),
                        label: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            gadgetName == "Colorizer"
                                ? (sale
                                    ? '100 Crystals for 10 Colorizers'
                                    : 'EUR 0.49 for\n10 Colorizer')
                                : gadgetName == "Hints"
                                    ? (sale
                                        ? '100 Crystals for 15 Hints'
                                        : 'EUR 0.49 for\n15 Hints')
                                    : "150 Crystals",
                            style: const TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: gradientColors.first,
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

  Widget _buildCoinDisplay(int CrystalsEarned) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/Crystals.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 30),
          Text(
            '$CrystalsEarned',
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
  final int numberOfCrystals;

  const CoinAnimation({
    super.key,
    required this.start,
    required this.end,
    required this.numberOfCrystals,
  });

  @override
  _CoinAnimationState createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _positionAnimation;
  late List<Widget> _Crystals;

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

    _Crystals = List.generate(
      widget.numberOfCrystals,
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
                'images/Crystals.png',
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
        children: _Crystals,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
