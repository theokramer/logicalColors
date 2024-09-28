// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:color_puzzle/action_Button.dart';
import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/custom_info_button.dart';
import 'package:color_puzzle/difficulty_bar.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/tutorial_overlay.dart';

import 'puzzle_model.dart';
import 'shop_screen.dart';

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

  Timer? timer;

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAdHints;
  RewardedAd? _rewardedAdRems;
  RewardedAd? _rewardedAdMoves;

  bool shouldTimerRun = true;

  Future<void> saveTutorial(bool tutorial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialActive', tutorial);
  }

  void _showPurchaseDialog(
      BuildContext context, String title, int amount, bool ad, int type) {
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
                    type == 0
                        ? const Icon(
                            Icons.lightbulb,
                            size: 50,
                            color: Colors.amber,
                          )
                        : type == 1
                            ? const Icon(Icons.colorize,
                                size: 50, color: Colors.redAccent)
                            : const Icon(Icons.bolt,
                                size: 50, color: Colors.indigo),
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
                    type == 2
                        ? addMoves(amount)
                        : type == 0
                            ? addHints(amount)
                            : addRems(amount);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.great ?? "Great",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadRewardedAdHints() {
    RewardedAd.load(
      adUnitId: "ca-app-pub-3263827122305139/2631314684",
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAdHints = null;
              });
              _loadRewardedAdHints();
            },
          );

          setState(() {
            _rewardedAdHints = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  void _loadRewardedAdRems() {
    RewardedAd.load(
      adUnitId: "ca-app-pub-3263827122305139/9970748650",
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAdRems = null;
              });
              _loadRewardedAdRems();
            },
          );

          setState(() {
            _rewardedAdRems = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  void _loadRewardedAdMoves() {
    RewardedAd.load(
      adUnitId: "ca-app-pub-3263827122305139/7344585315",
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAdMoves = null;
              });
              _loadRewardedAdMoves();
            },
          );

          setState(() {
            _rewardedAdMoves = ad;
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
      adUnitId: 'ca-app-pub-3263827122305139/1837668840', // correct one:
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              //selectedLevel += 1;
            },
          );
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

  //DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    print("HIER");

    timeElapsed = 0;

    //_startTime = DateTime.now();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _onTick());

    if (((selectedLevel > 40 && levelsSinceAd > 4) || levelsSinceAd > 7) &&
        worlds[0].maxLevel > 10 &&
        !noAds) {
      if (_interstitialAd == null) {
        _loadInterstitialAd();
      }

      levelsSinceAd = 0;
    }

    if (_rewardedAdHints == null) {
      _loadRewardedAdHints();
    }

    if (_rewardedAdRems == null) {
      _loadRewardedAdRems();
    }

    if (_rewardedAdMoves == null) {
      _loadRewardedAdMoves();
    }

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3263827122305139/9324715541',
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

    if (worlds[1].maxLevel > 1 && !noAds) {
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
      /*if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
        showUnlockWorldsDialog(puzzle);
      }*/
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

  void _onTick() {
    setState(() {
      timeElapsed += 1;
    });
  }

  List<PopupMenuEntry<String>> _showPopupMenu() {
    return <PopupMenuEntry<String>>[
      _buildPopupMenuItem('home', AppLocalizations.of(context)?.home ?? "Home",
          Icons.home, Colors.indigo),
      // _buildPopupMenuItem('shop', AppLocalizations.of(context)?.shop ?? "Shop",
      //     Icons.shopping_cart, Colors.indigo),
      // _buildPopupMenuItem(
      //     'refresh',
      //     '${AppLocalizations.of(context)?.newS ?? "New"} Level ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 10 ${AppLocalizations.of(context)?.crystals ?? "Crystals"}' : ""}',
      //     Icons.refresh,
      //     Colors.indigo),
      // if (selectedLevel > 1)
      //   _buildPopupMenuItem('prev', 'Level ${selectedLevel - 1}',
      //       Icons.skip_previous, Colors.indigo),
      // if (!(worlds[currentWorld - 1].maxLevel <= selectedLevel))
      //   _buildPopupMenuItem(
      //       'next',
      //       'Level ${selectedLevel + 1} ${worlds[currentWorld - 1].maxLevel <= selectedLevel ? '– 100 ${AppLocalizations.of(context)?.crystals ?? "Crystals"}' : ""}',
      //       Icons.skip_next,
      //       Colors.indigo),
      _buildPopupMenuItem(
          'settings',
          '${AppLocalizations.of(context)?.settings ?? "New"} ',
          Icons.settings,
          Colors.indigo),
    ];
  }

  void showUnlockWorldsDialog(PuzzleModel puzzle) {
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
                  AppLocalizations.of(context)?.unlockTitle ?? "Unlock",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)?.unlockBody ?? "Unlock",
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
                  AppLocalizations.of(context)?.backToHome ?? "Back to home",
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
    // addHints(15);
    // Navigator.pop(context);
  }

  Future<void> handleBuyMoves() async {
    if (await CoinManager.loadCrystals() >= 150) {
      subtractCrystals(150);
      addMoves(3);
    } else {}
    Navigator.pop(context);
  }

  void handleWatchAdForMoves() {
    _rewardedAdMoves?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.moves ?? "Moves'"} ${AppLocalizations.of(context)?.earned ?? "earned'"}",
            3,
            true,
            2);
      },
    );
    _loadRewardedAdMoves();
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
    addRems(10);
    Navigator.pop(context);
  }

  void handleWatchAdForHints() {
    _rewardedAdHints?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.hints ?? "Hints'"} ${AppLocalizations.of(context)?.earned ?? "earned'"}",
            3,
            true,
            0);
      },
    );
    _loadRewardedAdHints();
  }

  void handleWatchAdForRems() {
    _rewardedAdRems?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.colorizer ?? "Colorizer'"} ${AppLocalizations.of(context)?.earned ?? "earned'"}",
            2,
            true,
            1);
      },
    );
    _loadRewardedAdRems();
  }

  /// Method to format time into minutes and seconds
  String _formatTime(int timeElapsed) {
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;

    if (minutes > 0) {
      // Display minutes and seconds if more than 60 seconds have passed
      return '$minutes:${seconds.toString().padLeft(2, '0')} min';
    } else {
      // Otherwise display just seconds
      return '$seconds s';
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    _animationController.dispose();
    _bannerAd.dispose();

    super.dispose();
  }

  bool resettedGrid = false;

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    Future.microtask(() => context.read<CoinProvider>().loadCrystals());
    Future.microtask(() => context.read<HintsProvider>().loadHints());
    Future.microtask(() => context.read<RemsProvider>().loadRems());

    return Scaffold(
      //backgroundColor: Colors.blue[50], // Playful background color
      backgroundColor:
          getBackgroundColor(selectedWallpaper), // Playful background color
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // Left side with PopupMenuButton

                        // Centered text
                        // Expanded(
                        //   flex: 2,
                        //   child: Center(
                        //     child: Text(
                        //       'Anfänger $selectedLevel',
                        //       textAlign: TextAlign.center,
                        //       style: const TextStyle(
                        //         color: Colors.white70,
                        //         fontSize: 18,
                        //         fontWeight: FontWeight.bold,
                        //         fontFamily: 'Quicksand',
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // Right side with CustomInfoButton

                        Expanded(
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: tutorialActive
                                  ? const SizedBox
                                      .shrink() // Hide when tutorial is active
                                  : IconButton(
                                      onPressed: () {
                                        showPauseMenu(context, puzzle);
                                      },
                                      icon: const Icon(
                                        Icons.pause,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    )
                              /*Consumer<CoinProvider>(
                                    builder: (context, coinProvider, child) {
                                      return PopupMenuButton<String>(
                                        key: popUpKey,
                                        offset: const Offset(10, 50),
                                        enabled: !denyClick,
                                        icon: const Icon(
                                            Icons.arrow_back_rounded,
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
                                              // if ((!worlds.last.unlocked &&
                                              //         selectedLevel > 14) &&
                                              //     false) {
                                              //   showUnlockWorldsDialog();
                                              // } else {
                                              if (coinProvider.Crystals >= 10 ||
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
                                                    page: ChangeNotifierProvider
                                                        .value(
                                                      value: puzzle,
                                                      child: const ShopScreen(),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              //}
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
                                              // if ((!worlds.last.unlocked &&
                                              //         selectedLevel > 14) &&
                                              //     false) {
                                              //   showUnlockWorldsDialog();
                                              // } else {
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
                                                      child: selectedLevel < 50
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
                                              //}
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
                                            case 'settings': // Neu hinzugefügt
                                              showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return SettingsScreen(
                                                    puzzle: puzzle,
                                                  ); // Hier wird die SettingsScreen als Modal geladen
                                                },
                                                isScrollControlled:
                                                    true, // Optional: damit Modal den ganzen Bildschirm ausfüllt
                                              );
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            _showPopupMenu(),
                                      );
                                    },
                                  ),*/
                              ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                const Spacer(),
                                SunnysDisplay(
                                  puzzle: puzzle,
                                ),
                              ],
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

                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 24.0, vertical: 5.0),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       showDifficultyInfo(context);
                  //     },
                  //     child: HorizontalDifficultyBar(
                  //         gridSize: puzzle
                  //             .size, // Assuming `puzzle.size` corresponds to the grid size
                  //         maxMoves: puzzle
                  //             .maxMoves, // Assuming `puzzle.maxMoves` is the maximum number of moves for the level
                  //         colors: worlds[currentWorld - 1].colors),
                  //   ),
                  // ),

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

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withOpacity(0.6), // Semi-transparent background
                        borderRadius:
                            BorderRadius.circular(12.0), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // Shadow position
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer, // Timer icon
                            color: Colors.white,
                            size: 24.0,
                          ),
                          const SizedBox(
                              width: 8.0), // Space between icon and text
                          Text(
                            _formatTime(
                                timeElapsed), // Format time based on elapsed seconds
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight
                                  .w600, // Semi-bold for game-like style
                              letterSpacing:
                                  1.2, // Slightly spaced out text for clarity
                              shadows: [
                                Shadow(
                                  color: Colors
                                      .black54, // Adds a slight shadow to the text
                                  blurRadius: 3,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  MediaQuery.of(context).size.height > 700
                      ? const SizedBox(
                          height: 50,
                        )
                      : const SizedBox(
                          height: 20,
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
                              // if ((!worlds.last.unlocked &&
                              //         selectedLevel > 14) &&
                              //     false) {
                              //   showUnlockWorldsDialog();
                              // } else {
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
                                  timer?.cancel();
                                  puzzle.countClicks = 0;
                                  denyClick = true;
                                  levelsSinceAd++;

                                  if (worlds[currentWorld - 1].maxLevel >
                                          selectedLevel ||
                                      (worlds[currentWorld - 1].maxLevel ==
                                          -2)) {
                                    getsLightBulb = -1;
                                  } else {
                                    setState(() {
                                      getsLightBulb = ((_random.nextInt(7)) +
                                                  (calculateDifficulty(
                                                          puzzle.maxMoves,
                                                          puzzle.size) *
                                                      4.4))
                                              .floor() -
                                          6;
                                    });
                                  }

                                  if (animations) {
                                    _confettiController.play();
                                  }

                                  if (vibration) {
                                    HapticFeedback.heavyImpact();
                                  }
                                  if (animations) {
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
                                              if (selectedLevel >=
                                                  worlds[currentWorld - 1]
                                                      .anzahlLevels) {
                                                worlds[currentWorld - 1]
                                                    .maxLevel = -2;
                                                puzzle.updateWorldLevel(
                                                    currentWorld, -2);
                                              } else {
                                                selectedLevel += 1;
                                                puzzle.updateWorldLevel(
                                                    currentWorld,
                                                    selectedLevel);
                                              }

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
                                    Future.delayed(
                                        Duration(
                                            milliseconds: tutorialActive
                                                ? 900
                                                : 600), () {
                                      setState(() {
                                        showBanner = true;
                                      });
                                      if (_interstitialAd != null) {
                                        _interstitialAd?.show();
                                      }
                                    });
                                  }
                                } else {
                                  if (vibration) {
                                    HapticFeedback.selectionClick();
                                  }

                                  if (puzzle.maxMoves == puzzle.moves) {
                                    showResetGadgetHint = true;
                                  }
                                }
                              }
                              if (puzzle.moves >= puzzle.maxMoves &&
                                  puzzle.maxMoves > 2 &&
                                  !puzzle.isGridFilledWithTargetColor()) {
                                showGadgetPopup(
                                    context,
                                    AppLocalizations.of(context)?.moves ??
                                        "Moves",
                                    handleBuyMoves,
                                    handleWatchAdForMoves,
                                    [Colors.indigo, Colors.indigoAccent],
                                    false);
                                // }
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
                          // if ((!worlds.last.unlocked && selectedLevel > 14) &&
                          //     false) {
                          //   showUnlockWorldsDialog();
                          // } else {
                          if (currentTutorialStep == TutorialStep.step5) {
                            changeTextStep5 = true;
                          }
                          if (hintsProvider.hints > 0) {
                            bool temp = await puzzle.getHint();
                            setState(() {
                              resettedGrid = temp;
                            });
                            if (resettedGrid) {
                              Future.delayed(const Duration(milliseconds: 2000),
                                  () {
                                setState(() {
                                  resettedGrid = false;
                                });
                              });
                            } else {
                              /*Future.delayed(Duration(milliseconds: 500), () {
                    puzzle.clearHint();
                  });*/
                            }
                          } else {
                            showGadgetPopup(context,
                                AppLocalizations.of(context)?.hints ?? "Hints",
                                () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ShopScreen(),
                                ),
                              );
                            }, handleWatchAdForHints,
                                [Colors.amber, Colors.orange], false);
                          }
                          //}
                        },
                        count: hintsProvider.hints, // Number of hints available
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
                          // if ((!worlds.last.unlocked && selectedLevel > 14) &&
                          //     false) {
                          //   showUnlockWorldsDialog();
                          // } else {
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
                                  AppLocalizations.of(context)?.colorizer ??
                                      "Colorizer'", () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ShopScreen(),
                                  ),
                                );
                              },
                                  handleWatchAdForRems,
                                  [
                                    const Color.fromARGB(255, 176, 2, 124),
                                    const Color.fromARGB(255, 255, 0, 81)
                                  ],
                                  false);
                              //}
                            }
                          }
                        },
                        count: remsProvider.rems, // Number of removes available
                        gradientColors: const [
                          Color.fromARGB(255, 176, 2, 124),
                          Color.fromARGB(255, 255, 0, 81)
                        ],
                        iconColor: Colors.white,
                        blink: currentTutorialStep == TutorialStep.completed &&
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
                      blink: puzzle.maxMoves == puzzle.moves &&
                          showResetGadgetHint &&
                          selectedLevel < 12,
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
                      blink: puzzle.maxMoves == puzzle.moves &&
                          showResetGadgetHint &&
                          selectedLevel < 12,
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
                    isRemoveTileMode ||
                    resettedGrid
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AnimatedCustomOverlay(
                        blink: currentTutorialStep == TutorialStep.step2 &&
                            tutorialActive &&
                            !resettedGrid,
                        message: resettedGrid
                            ? AppLocalizations.of(context)?.resettedGrid ??
                                "removeTile"
                            : isRemoveTileMode
                                ? AppLocalizations.of(context)?.tRemoveTile ??
                                    "removeTile"
                                : showResetGadgetHint
                                    ? AppLocalizations.of(context)?.tResetGadget ??
                                        "reset Gadget"
                                    : currentTutorialStep == TutorialStep.step2 &&
                                            tutorialActive
                                        ? AppLocalizations.of(context)?.tStep2 ??
                                            "Step 2"
                                        : currentTutorialStep ==
                                                    TutorialStep.step3 &&
                                                tutorialActive
                                            ? AppLocalizations.of(context)
                                                    ?.tStep3 ??
                                                "Step 3"
                                            : currentTutorialStep ==
                                                        TutorialStep.step4 &&
                                                    tutorialActive
                                                ? AppLocalizations.of(context)
                                                        ?.tStep4 ??
                                                    "Step 4"
                                                : currentTutorialStep ==
                                                            TutorialStep
                                                                .step5 &&
                                                        tutorialActive
                                                    ? (changeTextStep5
                                                        ? AppLocalizations.of(context)
                                                                ?.tStep52 ??
                                                            "Step 52"
                                                        : AppLocalizations.of(
                                                                    context)
                                                                ?.tStep51 ??
                                                            "Step 51")
                                                    : AppLocalizations.of(context)
                                                            ?.tStepCompleted ??
                                                        "Step Completed",
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
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: Container(
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
                                      if (selectedLevel <
                                          worlds[currentWorld].anzahlLevels) {
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

                                        denyClick = false;
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
                                            child: selectedLevel <
                                                    worlds[currentWorld]
                                                        .anzahlLevels
                                                ? const PuzzleScreen()
                                                : const MainMenuScreen(),
                                          ),
                                        ),
                                      );
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(35.0),
                                  child: Center(
                                    child: Stack(
                                      clipBehavior: Clip
                                          .none, // This allows overflow beyond the screen bounds
                                      children: [
                                        // Positioned Icon that overflows above the LevelCompletionScreen

                                        // LevelCompletionScreen container
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          child: LevelCompletionScreen(
                                            selectedLevel: selectedLevel,
                                            timeElapsed: timeElapsed,
                                            onContinue: () {
                                              if (!animationStarted) {
                                                setState(() {
                                                  animationStarted = true;
                                                  showCoinAnimation = true;
                                                  if (selectedLevel <
                                                      worlds[currentWorld]
                                                          .anzahlLevels) {
                                                    puzzle.updateWorldLevel(
                                                        currentWorld,
                                                        selectedLevel);
                                                    if (tutorialActive ==
                                                        true) {
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
                                                                TutorialStep
                                                                    .none;
                                                            saveTutorial(
                                                                tutorialActive);
                                                          });
                                                          break;
                                                      }
                                                    }
                                                    print(currentTutorialStep);
                                                    puzzle.saveTutorialStep(
                                                        currentTutorialStep);
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
                                                        child: selectedLevel <
                                                                50
                                                            ? const PuzzleScreen()
                                                            : const MainMenuScreen(),
                                                      ),
                                                    ),
                                                  );
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned(
                                            top:
                                                -75, // 30px above the LevelCompletionScreen
                                            left:
                                                0, // adjust left or right if needed
                                            right:
                                                0, // center the icon horizontally
                                            child: Container(
                                                height: 150,
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  color: currencyColor,
                                                  shape: BoxShape.circle,
                                                  // border: Border.all(
                                                  //     color: Colors.white,
                                                  //     width: 1.5)
                                                ),
                                                child: Icon(
                                                  currencyIcon,
                                                  color: Colors.white,
                                                  size: 90,
                                                ))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Confetti effect
            // if (animationStarted && showCoinAnimation && animations)
            //   CoinAnimation(
            //     start: Offset(MediaQuery.of(context).size.width / 2,
            //         MediaQuery.of(context).size.height / 2),
            //     end: const Offset(50, 75),
            //     numberOfCrystals: puzzle.CrystalsEarned,
            //   ),

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
                                        movesLeft:
                                            puzzle.maxMoves, // Number of moves
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
    );
  }

  void _showInfoDialogStart(BuildContext contex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.colorTheGrid ?? "Play",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              Text(AppLocalizations.of(context)?.colorTheGridBody ?? "Play"),
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
              child: const Text('Ok'),
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
          title: Text(
            AppLocalizations.of(context)?.difficultyExplTitle ?? "Play",
          ),
          content: Text(
            AppLocalizations.of(context)?.difficultyExplBody ?? "Play",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)?.close ?? "Cancel",
              ),
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
                child: Text(
                  AppLocalizations.of(context)?.start ?? "Start",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showPauseMenu(BuildContext context, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(25),
            height: 355, // Adjust height
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${worlds[currentWorld - 1].name} $selectedLevel",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(); // Closes the modal view
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      FadePageRoute(page: const MainMenuScreen()),
                    );
                  },
                  child: PausedButton(icon: Icons.home, text: "Home"),
                ),
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: PausedButton(icon: Icons.play_arrow, text: "Continue"),
                ),
                const SizedBox(
                  height: 10,
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
                  child: PausedButton(icon: Icons.tune, text: "Settings"),
                ),
                const Spacer()
              ],
            ),
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
                      ? "${AppLocalizations.of(context)?.getMore ?? "Play"} $gadgetName with a 200 Crystals discount"
                      : '${AppLocalizations.of(context)?.getMore ?? "Play"} $gadgetName',
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
                  gadgetName ==
                          (AppLocalizations.of(context)?.colorizer ?? "Play")
                      ? "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.colorizer ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}"
                      : gadgetName ==
                              (AppLocalizations.of(context)?.hints ?? "Play")
                          ? "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.hints ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}"
                          : "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.moves ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}",
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
                      gadgetName ==
                              (AppLocalizations.of(context)?.colorizer ??
                                  "Play")
                          ? Icons.colorize
                          : gadgetName ==
                                  (AppLocalizations.of(context)?.hints ??
                                      "Play")
                              ? Icons.lightbulb
                              : Icons.bolt,
                      size: 60,
                      color: gradientColors.first,
                    ),
                    const SizedBox(
                      width: 25,
                    ),
                    Text(
                      gadgetName ==
                              (AppLocalizations.of(context)?.moves ?? "Play")
                          ? "x3"
                          : gadgetName,
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
                          gadgetName ==
                                  (AppLocalizations.of(context)?.colorizer ??
                                      "Play")
                              ? '${AppLocalizations.of(context)?.watchAds ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 2 ${AppLocalizations.of(context)?.colorizer ?? "Play"}'
                              : gadgetName ==
                                      (AppLocalizations.of(context)?.hints ??
                                          "Play")
                                  ? '${AppLocalizations.of(context)?.watchAds ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 3 ${AppLocalizations.of(context)?.hints ?? "Play"}'
                                  : AppLocalizations.of(context)?.watchAds ??
                                      "Play",
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
                          if (gadgetName ==
                              (AppLocalizations.of(context)?.moves ?? "Play")) {
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
                            gadgetName ==
                                    (AppLocalizations.of(context)?.colorizer ??
                                        "Play")
                                ? (sale
                                    ? '100 ${AppLocalizations.of(context)?.crystals ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 10 ${AppLocalizations.of(context)?.colorizer ?? "Play"}'
                                    : 'EUR 0,49 ${AppLocalizations.of(context)?.forName ?? "Play"}\n10 ${AppLocalizations.of(context)?.colorizer ?? "Play"}')
                                : gadgetName ==
                                        (AppLocalizations.of(context)?.hints ??
                                            "Play")
                                    ? (sale
                                        ? '100 ${AppLocalizations.of(context)?.crystals ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 15 ${AppLocalizations.of(context)?.hints ?? "Play"}'
                                        : 'EUR 0,49 ${AppLocalizations.of(context)?.forName ?? "Play"}\n15 ${AppLocalizations.of(context)?.hints ?? "Play"}')
                                    : "150 ${AppLocalizations.of(context)?.crystals ?? "Play"}",
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

class PausedButton extends StatelessWidget {
  IconData icon;
  String text;
  PausedButton({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 50,
            child: Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 28),
          )
        ],
      ),
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

class LevelCompletionScreen extends StatelessWidget {
  final int selectedLevel;
  final int timeElapsed;
  final Function onContinue;

  const LevelCompletionScreen({
    super.key,
    required this.selectedLevel,
    required this.timeElapsed,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    bool lastLevel = selectedLevel >= worlds[currentWorld - 1].anzahlLevels;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 80),

        // Title Text
        Text(
          "Level abgeschlossen!",
          style: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        ),

        //const Divider(),
        const SizedBox(height: 20),

        // Feedback Text
        Text(
          "Prächtig!",
          style: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 35),

        // Time Display
        // Text(
        //   "TIME",
        //   style: TextStyle(
        //     color: Colors.blueGrey[800],
        //     fontSize: 18,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 45),
            const SizedBox(
              width: 10,
            ),
            Text(
              _formatTime2(timeElapsed),
              style: TextStyle(
                fontSize: 45,
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 45),

        // Navigation Buttons (Home, Stats, Share)
        _buildNavigationRow(
          context,
          lastLevel,
        ),
        const SizedBox(
          height: 3,
        ),

        // Continue Button
        GestureDetector(
          onTap: () {
            lastLevel
                ? Navigator.of(context).pushReplacement(
                    FadePageRoute(page: const MainMenuScreen()),
                  )
                : onContinue();
          },
          child: Container(
            height: 80,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: lastLevel ? Colors.blue : Colors.teal,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Icon(
              lastLevel ? Icons.home : Icons.skip_next,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Reusable widget for navigation buttons
  Widget _buildNavigationRow(BuildContext context, bool lastLevel) {
    return Row(
      children: [
        if (!lastLevel)
          _buildNavButton(
            context,
            lastLevel: lastLevel,
            color: Colors.blue,
            icon: Icons.home,
            onTap: () {
              Navigator.of(context).pushReplacement(
                FadePageRoute(page: const MainMenuScreen()),
              );
            },
          ),
        const SizedBox(
          width: 3,
        ),
        _buildNavButton(
          context,
          lastLevel: lastLevel,
          color: Colors.deepPurple,
          icon: Icons.bar_chart,
          onTap: () {
            // Handle stats action
          },
        ),
        const SizedBox(
          width: 3,
        ),
        _buildNavButton(
          context,
          lastLevel: lastLevel,
          color: Colors.red,
          icon: Icons.share,
          onTap: () {
            // Handle share action
          },
        ),
      ],
    );
  }

  String _formatTime2(int timeElapsed) {
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;

    return "$minutes:${seconds < 10 ? 0 : ""}$seconds";
  }

  // Reusable widget for each individual button
  Widget _buildNavButton(BuildContext context,
      {required Color color,
      required IconData icon,
      required Function onTap,
      required bool lastLevel}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Icon(
            icon,
            size: 35,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
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
          AppLocalizations.of(context)?.tapToClaim ?? "Play",
          style: TextStyle(
            color: animations ? _colorAnimation.value : Colors.indigo,
            fontSize: animations ? _sizeAnimation.value : 26,
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

class SettingsScreen extends StatefulWidget {
  final PuzzleModel puzzle;
  const SettingsScreen({super.key, required this.puzzle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Function to open a URL
  void _launchPrivacyPolicy(BuildContext context) async {
    final Uri uri = Uri.parse('https://694764.8b.io/privacy.html');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // can't launch url
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the LanguageProvider to change the locale
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.45 +
          100, // Limit height to 50% of the screen
      child: Column(
        children: [
          // A small "bar" to close the modal view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.settings ?? "Settings",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the modal view
                },
              ),
            ],
          ),
          const Divider(), // Separator line
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: vibration,
                  onChanged: (bool value) {
                    setState(() {
                      vibration = value; // Update vibration state
                    });
                    widget.puzzle.saveVibration(value);
                  },
                ),
                const SizedBox(height: 20), // Spacing
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)?.sounds ?? "Sounds",
                  ),
                  value: sounds,
                  onChanged: (bool value) {
                    setState(() {
                      sounds = value; // Update sounds state
                    });
                    widget.puzzle.saveSounds(value);
                  },
                ),
                const SizedBox(height: 20), // Spacing
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)?.animations ?? "Animations",
                  ),
                  value: animations,
                  onChanged: (bool value) {
                    setState(() {
                      animations = value; // Update animations state
                    });
                    widget.puzzle.saveAnimations(value);
                  },
                ),
                const SizedBox(height: 20), // Spacing
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.language ?? "Language",
                  ),
                  trailing: DropdownButton<String>(
                    value: languages[selectedLanguage],
                    onChanged: (String? newValue) {
                      setState(() {
                        switch (newValue) {
                          case "English":
                            selectedLanguage = 0;
                            break;
                          case "Deutsch":
                            selectedLanguage = 1;
                            break;
                          case "Español":
                            selectedLanguage = 2;
                            break;
                          default:
                            selectedLanguage = 0;
                        }
                        // Update the selected language
                        widget.puzzle.saveSelectedLanguage(selectedLanguage);

                        // Change the locale in the provider
                        languageProvider
                            .setLocale(Locale(locales[selectedLanguage]));
                      });
                    },
                    items: languages
                        .map<DropdownMenuItem<String>>((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  title: Center(
                    child: Text(
                      AppLocalizations.of(context)?.privacy ?? "Privacy Policy",
                      style:
                          const TextStyle(color: Colors.indigo, fontSize: 15),
                    ),
                  ),
                  onTap: () => _launchPrivacyPolicy(context), // Open URL on tap
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
