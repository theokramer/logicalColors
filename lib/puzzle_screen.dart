// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tone_twister/action_Button.dart';
import 'package:tone_twister/custom_info_button.dart';
import 'package:tone_twister/difficulty_bar.dart';
import 'package:tone_twister/hints_manager.dart';
import 'package:tone_twister/main.dart';
import 'package:tone_twister/main_menu_screen.dart';
import 'package:tone_twister/tutorial_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

import 'puzzle_model.dart';

void showStarsInfo(
    BuildContext context, bool proportional, PuzzleModel puzzle) {
  showDialog(
    context: context,
    builder: (BuildContext builder) {
      return AlertDialog(
        //TODO: Translate!
        title: const Text("Sterne-System"),
        content: Text(
            "Im Sterne-System erhältst du nach jedem neuen Level einen Stern. "
            "Wenn du eine bestimmte Anzahl an Sternen gesammelt hast, steigst du eine Stufe auf. "
            "Zusätzlich schaltest du mit den Sternen neue Wallpaper frei. "
            "${proportional ? "Du hast in diesem Level bereits ${puzzle.getCurrencyAmountForWorld(currentWorld)} von ${worlds[currentWorld - 1].anzahlLevels} möglichen Sternen gesammelt." : ""}"
            "Sammle so viele Sterne wie möglich, um alle Belohnungen freizuschalten! "),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
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
              color: primaryColor,
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
                            ? const Icon(Icons.double_arrow,
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
                    style: TextStyle(color: primaryColor),
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

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  final List<ProductDetails> products = [];
  var _subscription;
  bool available = true; // Track availability of in-app purchases

  void _loadProducts() async {
    const Set<String> productIds = {
      'de.tk.noAds.bundle',
      'de.tk.noAds',
      'de.tk.colorizer1',
      'de.tk.hints1',
      'de.tk.hints2',
      'de.tk.hints3',
      'de.tk.hints4',
      'de.tk.crystals1',
      'de.tk.crystals2',
      'de.tk.crystals3',
      'de.tk.crystals4',
      'de.tk.crystals5',
    };

    final ProductDetailsResponse response =
        await inAppPurchase.queryProductDetails(productIds);
    if (response.error == null && response.productDetails.isNotEmpty) {
      products.addAll(response.productDetails);
    }
  }

  //DateTime? _startTime;

  @override
  void initState() {
    super.initState();

    timeElapsed = 0;

    //_startTime = DateTime.now();

    // if (timer == null || !timer!.isActive) {
    //   timer =
    //       Timer.periodic(const Duration(seconds: 1), (Timer t) => _onTick());
    // }

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

    PuzzleModel puzzle = Provider.of<PuzzleModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentTutorialStep == TutorialStep.step3) {
        _showInfoDialogStart(context, puzzle);
      }
      /*if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
        showUnlockWorldsDialog(puzzle);
      }*/
    });

    // Access PuzzleModel via Provider here

    // Now you can safely use puzzle in your initState logic
    // For example, loading some data or calling a method on the PuzzleModel
    // You can call other methods on puzzle as needed

    _loadProducts();

    // Listen to the purchaseUpdatedStream
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchases) {
      _handlePurchaseUpdates(purchases, puzzle);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle errors here if necessary
      print('Error in purchase stream: $error');
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

  Future<void> handleBuyHint() async {
    /*if (await CoinManager.loadCrystals() >= 200) {
      subtractCrystals(200);
      
    } else {}*/
    // addHints(15);
    // Navigator.pop(context);
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

  Future<void> handleBuyRem() async {
    /*if (await CoinManager.loadCrystals() >= 200) {
      subtractCrystals(200);
      
    } else {
      // Handle not enough Crystals
    }*/
    addRems(10);
    Navigator.pop(context);
  }

  void buyHints(int index) {
    if (products.isNotEmpty) {
      for (int i = 0; i < products.length; i++) {
        if (products[i].id == "hints.$index") {}
      }
    }
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
        Navigator.of(context).pop();
      },
    );
    _loadRewardedAdHints();
  }

  void handleWatchAdForRems() {
    _rewardedAdRems?.show(
      onUserEarnedReward: (_, reward) {
        _showPurchaseDialog(
            context,
            "Skip Level ${AppLocalizations.of(context)?.earned ?? "earned'"}",
            1,
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
    if (_subscription != null) {
      _subscription.cancel();
    }
    //timer?.cancel(); // Timer stoppen, wenn der Screen verlassen wird
    _confettiController.dispose();
    _animationController.dispose();
    _bannerAd.dispose();

    super.dispose();
  }

  bool resettedGrid = false;

  void playGame(PuzzleModel puzzle) async {
    int size = await puzzle.readSize(currentWorld, selectedLevel);
    int level = await puzzle.readMoves(currentWorld, selectedLevel);
    Navigator.of(context).pushReplacement(
      FadePageRoute(
        page: ChangeNotifierProvider(
          create: (_) => PuzzleModel(
            size: size,
            level: level,
            colorMapping: {
              1: worlds[currentWorld - 1].colors[0],
              2: worlds[currentWorld - 1].colors[1],
              3: worlds[currentWorld - 1].colors[2],
            },
          ),
          child: selectedLevel <= worlds[currentWorld - 1].anzahlLevels
              ? const PuzzleScreen()
              : const MainMenuScreen(),
        ),
      ),
    );
  }

  void showErrorDialog(BuildContext context, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.actionRequiredTitle ?? "Play"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)?.actionRequiredBody ?? "Play",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: GestureDetector(
                  onTap: () {
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
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)?.resetGrid ?? "Play",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showEndScreen(PuzzleModel puzzle) {
    //timer?.cancel();
    puzzle.countClicks = 0;
    denyClick = true;
    levelsSinceAd++;

    if (worlds[currentWorld - 1].maxLevel > selectedLevel ||
        (worlds[currentWorld - 1].maxLevel == -2)) {
      getsLightBulb = -1;
    } else {
      setState(() {
        getsLightBulb = ((_random.nextInt(7)) +
                    (calculateDifficulty(puzzle.maxMoves, puzzle.size) * 4.4))
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
        Future.delayed(Duration(milliseconds: tutorialActive ? 600 : 300), () {
          _animationController.reverse().then((_) {
            Future.delayed(Duration(milliseconds: tutorialActive ? 1000 : 500),
                () {
              setState(() {
                if (selectedLevel >= worlds[currentWorld - 1].anzahlLevels) {
                  selectedLevel = -2;
                  worlds[currentWorld - 1].maxLevel = -2;
                  puzzle.updateWorldLevel(currentWorld, -2);
                } else {
                  selectedLevel += 1;
                  puzzle.updateWorldLevel(currentWorld, selectedLevel);
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
      Future.delayed(Duration(milliseconds: tutorialActive ? 900 : 600), () {
        setState(() {
          showBanner = true;
        });
        if (_interstitialAd != null) {
          _interstitialAd?.show();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
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
                        //         color: primaryColor70,
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
                                        showPauseMenuDialog(context, puzzle);
                                      },
                                      icon: Icon(
                                        Icons.pause,
                                        color: primaryColor,
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
                                            color: primaryColor),
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
                        if (tutorialActive == false)
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
                                backgroundColor:
                                    puzzle.getColor(puzzle.targetColorNumber),
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
                  if (currentWorld != 1 && false)
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
                            Icon(
                              Icons.timer, // Timer icon
                              color: primaryColor,
                              size: 24.0,
                            ),
                            const SizedBox(
                                width: 8.0), // Space between icon and text
                            Text(
                              _formatTime(
                                  timeElapsed), // Format time based on elapsed seconds
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight
                                    .w600, // Semi-bold for game-like style
                                letterSpacing:
                                    1.2, // Slightly spaced out text for clarity
                                shadows: const [
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
                        crossAxisCount: puzzle.size > 0 ? puzzle.size : 1,
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
                            onTap: () async {
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
                                      var resetFirst = await puzzle.getHint();
                                      if (resetFirst) {
                                        //showErrorDialog(context);
                                      }

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
                                  showEndScreen(puzzle);
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
                                    () {},
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
                                    color: primaryColor,
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

            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // if (currentTutorialStep == TutorialStep.step5 ||
                  //     tutorialActive == false)
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
                            // if (currentTutorialStep == TutorialStep.step5) {
                            //   changeTextStep5 = true;
                            // }

                            // showHintDialog(context, hintsProvider.hints, puzzle);
                            if (currentTutorialStep == TutorialStep.step5) {
                              changeTextStep5 = true;
                            }
                            if (hintsProvider.hints > 0) {
                              bool hintUsed = await puzzle.getHint();
                              if (hintUsed) {
                                showErrorDialog(context, puzzle);
                                // Your hint used logic here
                              } else {
                                /*Future.delayed(Duration(milliseconds: 500), () {
                        puzzle.clearHint();
                      });*/
                              }
                            } else {
                              buyHintDialog(
                                  context, hintsProvider.hints, puzzle, true);
                              // showGadgetPopup(
                              //     context,
                              //     AppLocalizations.of(context)?.hints ??
                              //         "Hints",
                              //     handleBuyHint,
                              //     handleWatchAdForHints,
                              //     [Colors.amber, Colors.orange],
                              //     false);
                            }
                          },
                          count:
                              hintsProvider.hints, // Number of hints available
                          gradientColors: const [Colors.amber, Colors.orange],
                          iconColor: primaryColor,
                          blink: currentTutorialStep == TutorialStep.step5 &&
                              !changeTextStep5,
                          borderColor: Colors.transparent,
                        );
                      }),
                      Consumer<RemsProvider>(
                          builder: (context, remsProvider, child) {
                        return CustomActionButton(
                          icon: Icons.double_arrow,
                          onPressed: () {
                            // if ((!worlds.last.unlocked && selectedLevel > 14) &&
                            //     false) {
                            //   showUnlockWorldsDialog();
                            // } else {

                            if (remsProvider.rems > 0) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text(AppLocalizations.of(context)
                                                ?.skipLevelTitle ??
                                            "removeTile"),
                                        content: Text(
                                            AppLocalizations.of(context)
                                                    ?.skipLevelBody ??
                                                "removeTile"),
                                        actions: [
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)
                                                        ?.cancel ??
                                                    "removeTile"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)
                                                        ?.skipLevelTitle ??
                                                    "removeTile"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              remsProvider.subtractRems(1);
                                              puzzle.fillWholeGrid();
                                              showEndScreen(puzzle);
                                            },
                                          ),
                                        ]);
                                  });

                              TODO:
                              "Fill Grid with targetColor. Show Level Completion Screen";
                              // setState(() {
                              //   if (isRemoveTileMode) {
                              //     isRemoveTileMode = false;
                              //   } else {
                              //     isRemoveTileMode = true;
                              //   }
                              // });
                            } else {
                              buyHintDialog(
                                  context, remsProvider.rems, puzzle, false);
                              // showGadgetPopup(
                              //     context,
                              //     AppLocalizations.of(context)?.colorizer ??
                              //         "Colorizer'", () {
                              //   Navigator.of(context).push(
                              //     MaterialPageRoute(
                              //       builder: (context) => const ShopScreen(),
                              //     ),
                              //   );
                              // },
                              //     handleWatchAdForRems,
                              //     [
                              //       const Color.fromARGB(255, 176, 2, 124),
                              //       const Color.fromARGB(255, 255, 0, 81)
                              //     ],
                              //     false);
                              //}
                            }
                          },
                          count:
                              remsProvider.rems, // Number of removes available
                          gradientColors: const [
                            Color.fromARGB(255, 176, 2, 124),
                            Color.fromARGB(255, 255, 0, 81)
                          ],
                          iconColor: primaryColor,
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

                        iconColor: primaryColor,
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
                        iconColor: primaryColor,
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
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 90.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                                                          : AppLocalizations.of(context)
                                                                  ?.tStep51 ??
                                                              "Step 51")
                                                      : AppLocalizations.of(context)
                                                              ?.tStepCompleted ??
                                                          "Step Completed",
                          onClose: () {},
                        ),
                      ],
                    ),
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
                                                tutorialActive = false;
                                                currentTutorialStep =
                                                    TutorialStep.none;
                                                saveTutorial(tutorialActive);
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

                                      playGame(puzzle);
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
                                            color: primaryColor,
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
                                            // selectedLevel: selectedLevel,
                                            timeElapsed: timeElapsed,
                                            onContinue: () {
                                              if (!animationStarted) {
                                                setState(() {
                                                  animationStarted = true;
                                                  showCoinAnimation = true;

                                                  if (selectedLevel <=
                                                      worlds[currentWorld - 1]
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
                                                                context,
                                                                puzzle);
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
                                                            setState(() {
                                                              tutorialActive =
                                                                  false;
                                                              currentTutorialStep =
                                                                  TutorialStep
                                                                      .none;
                                                              saveTutorial(
                                                                  tutorialActive);
                                                            });
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

                                                  playGame(puzzle);
                                                });
                                              }
                                            },
                                            puzzle: puzzle,
                                          ),
                                        ),

                                        Positioned(
                                            top:
                                                -75, // 30px above the LevelCompletionScreen
                                            left:
                                                0, // adjust left or right if needed
                                            right:
                                                0, // center the icon horizontally
                                            child: GestureDetector(
                                              onTap: () {
                                                showStarsInfo(
                                                    context, false, puzzle);
                                              },
                                              child: Container(
                                                  height: 150,
                                                  width: 150,
                                                  decoration: BoxDecoration(
                                                    color: currencyColor,
                                                    shape: BoxShape.circle,
                                                    // border: Border.all(
                                                    //     color: primaryColor,
                                                    //     width: 1.5)
                                                  ),
                                                  child: Icon(
                                                    currencyIcon,
                                                    color: primaryColor,
                                                    size: 90,
                                                  )),
                                            )),
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
                          backgroundColor: primaryColor,
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
                              // HorizontalDifficultyBar(
                              //     gridSize: puzzle.size,
                              //     maxMoves: puzzle.maxMoves,
                              //     colors: worlds[currentWorld - 1].colors),
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

  void buy(Map<String, dynamic> item, PuzzleModel puzzle) async {
    int type = item['type'] as int;

    if (type == 0) {
      _rewardedAdHints?.show(
        onUserEarnedReward: (_, reward) {
          _showPurchaseDialog(
              context,
              '${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.earned ?? "World"}',
              150,
              true,
              type); // Zeige Pop-Up an
        },
      );
      _loadRewardedAdHints();
    }
    if (type == 1) {
      _rewardedAdRems?.show(
        onUserEarnedReward: (_, reward) {
          _showPurchaseDialog(
              context,
              '${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.earned ?? "World"}',
              150,
              true,
              type); // Zeige Pop-Up an
        },
      );
      _loadRewardedAdRems();
    }
    if (type == 2) {
      _rewardedAdMoves?.show(
        onUserEarnedReward: (_, reward) {
          _showPurchaseDialog(
              context,
              '${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.earned ?? "World"}',
              150,
              true,
              type); // Zeige Pop-Up an
        },
      );
      _loadRewardedAdMoves();
    }
  }

  void _buyProduct(ProductDetails productDetails, PuzzleModel puzzle) async {
    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Purchase error: $e');
    }
  }

  void _restorePurchases(PuzzleModel puzzle) async {
    if (!(await puzzle.loadHasRestoredPurchases())) {
      try {
        await inAppPurchase.restorePurchases();
      } catch (e) {
        print('Restoration error: $e');
      }
    }
  }

  // Handle the purchase updates
// Handle the purchase updates, including restored purchases
  void _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList, PuzzleModel puzzle) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.restored) {
        puzzle.saveHasRestoredPurchases(true);
      }
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        bool isVerified = _verifyPurchase(purchaseDetails);
        if (purchaseDetails.status == PurchaseStatus.restored) {}
        if (isVerified) {
          _onPurchaseSuccess(purchaseDetails, puzzle);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error ||
          purchaseDetails.status == PurchaseStatus.canceled) {
        print('Purchase failed: ${purchaseDetails.error}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  void _onPurchaseSuccess(PurchaseDetails purchaseDetails, PuzzleModel puzzle) {
    // Call your desired function after purchase success
    print('Purchase successful: ${purchaseDetails.productID}');

    // For example, unlock content or remove ads

    switch (purchaseDetails.productID) {
      case 'de.tk.colorizer1':
        addRems(10);
        _showPurchaseDialog(
            context,
            "Skip Level ${AppLocalizations.of(context)?.purchased ?? "World"}",
            10,
            false,
            1);
        break;
      case 'de.tk.hints1':
        addHints(15);
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.hints ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}",
            15,
            false,
            0);
        break;
      case 'de.tk.hints2':
        addHints(40);
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.hints ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}",
            40,
            false,
            0);
        break;
      default:
        addHints(40);
        _showPurchaseDialog(
            context,
            "${AppLocalizations.of(context)?.hints ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}",
            40,
            false,
            0);
        break;
    }

    // Add more product logic as needed
  }

  bool _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Perform your verification logic (server-side verification is recommended)
    return true; // For demo purposes, assuming all purchases are verified.
  }

  void buyHintDialog(
      BuildContext context, int hintCount, PuzzleModel puzzle, bool hints) {
    String name = hints ? "Hinweise" : "Skip Level";
    final filteredAndSortedProducts = products
        .where((p) =>
            p.id != 'de.tk.noAds' &&
            p.id != 'de.tk.noAds.bundle' &&
            !p.id.contains('crystals'))
        .toList()
      ..sort((a, b) {
        // Erstes Kriterium: Kategorie
        int getCategoryOrder(ProductDetails item) {
          if (item.id == 'de.tk.colorizer1') return 0; // Colorizer kommt zuerst
          if (item.id == 'de.tk.hints1' ||
              item.id == 'de.tk.hints2' ||
              item.id == 'de.tk.hints3' ||
              item.id == 'de.tk.hints4') {
            return 1; // Hints kommen danach
          }
          return 2; // Crystals kommen zuletzt
        }

        final categoryComparison =
            getCategoryOrder(a).compareTo(getCategoryOrder(b));

        // Wenn beide Produkte in der gleichen Kategorie sind, sortiere nach Preis
        if (categoryComparison == 0) {
          return a.rawPrice.compareTo(b.rawPrice);
        }
        return categoryComparison;
      });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 500,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      '$name erhalten',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // const SizedBox(height: 8),
                    // const Text(
                    //   'Fehler beim Kaufvorgang',
                    //   style: TextStyle(
                    //     color: Colors.red,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 10),
                    OptionButton(
                      product: ProductDetails(
                        id: "de.tk.watchAd",
                        title: 'Video schauen\nfür ${hints ? "3" : 1} $name',
                        description: '',
                        price: "-1",
                        rawPrice: 0,
                        currencyCode: '',
                      ),
                      onPressed:
                          hints ? handleWatchAdForHints : handleWatchAdForRems,
                    ),
                    const SizedBox(height: 10),
                    for (var i in filteredAndSortedProducts)
                      if (i.id
                          .contains(hints ? "de.tk.hints" : "de.tk.colorizer"))
                        Column(
                          children: [
                            OptionButton(
                              product: i,
                              onPressed: () {
                                _buyProduct(i, puzzle);
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                    GestureDetector(
                      onTap: () {
                        _restorePurchases(puzzle);
                      },
                      child: Text(
                        "${AppLocalizations.of(context)?.restorePurchases ?? "World"} ",
                        style: const TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration
                                .underline, // Add this line to underline the text
                            decorationColor: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showHintDialog(BuildContext context, int hintCount, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  children: [
                    Text(
                      'Brauchst du einen Hinweis:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Horizontal scroll view with centered hint
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 200, // Fixed height for the hint display
                      child: HintScrollView(
                        hintCount: puzzle.maxMoves,
                        puzzle: puzzle,
                      ),
                    ),

                    // Display the count of hints below the scroll view
                    const SizedBox(height: 15),
                    Text(
                      'Hinweise: $hintCount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              TextButton(
                onPressed: () {
                  // Action for getting more hints, possibly navigate to shop
                  buyHintDialog(context, hintCount, puzzle, true);
                },
                child: const Text(
                  'MEHR HINWEISE ERHALTEN',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialogStart(BuildContext context, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              worlds[currentWorld - 1].colors[puzzle.targetColorNumber - 1],
          title: Text(
            AppLocalizations.of(context)?.colorTheGrid ?? "Play",
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              Text(
                AppLocalizations.of(context)?.colorTheGridBody ?? "Play",
                style: const TextStyle(color: Colors.white),
              ),
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
              child: const Text(
                'Ok',
                style: TextStyle(color: Colors.white),
              ),
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
          backgroundColor: primaryColor,
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
                  style: TextStyle(fontSize: 20, color: primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Function to show the pause dialog
  void showPauseMenuDialog(BuildContext context, PuzzleModel puzzle) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing on outside tap
      builder: (BuildContext context) {
        return PauseMenuDialog(
          puzzle: puzzle,
        );
      },
    );
  }

  void showPauseMenu(BuildContext context, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: primaryColor,
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
                    dispose();
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
            height: 250, // Adjust height
            width: MediaQuery.of(context).size.width * 0.75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sale
                      ? "${AppLocalizations.of(context)?.getMore ?? "Play"} $gadgetName with a 200 Crystals discount"
                      : '${AppLocalizations.of(context)?.getMore ?? "Play"} $gadgetName',
                  style: TextStyle(
                    color: primaryColor,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                // const SizedBox(height: 10),
                // Text(
                //   gadgetName ==
                //           (AppLocalizations.of(context)?.colorizer ?? "Play")
                //       ? "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.colorizer ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}"
                //       : gadgetName ==
                //               (AppLocalizations.of(context)?.hints ?? "Play")
                //           ? "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.hints ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}"
                //           : "${AppLocalizations.of(context)?.chooseHowTo ?? "Play"} ${AppLocalizations.of(context)?.moves ?? "Play"} ${AppLocalizations.of(context)?.getChoose ?? "Play"}",
                //   style: TextStyle(
                //     color: primaryColor,
                //     fontFamily: 'Quicksand',
                //     fontWeight: FontWeight.normal,
                //     fontSize: 15,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gadgetName == "Skip Level"
                          ? Icons.double_arrow
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
                          gadgetName == "Skip Level"
                              ? '${AppLocalizations.of(context)?.watchAds ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} a Skip Level'
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
                        foregroundColor: primaryColor,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    // Consumer<CoinProvider>(
                    //     builder: (context, coinProvider, child) {
                    //   return ElevatedButton.icon(
                    //     onPressed: () {
                    //       /*coinProvider.Crystals >= 200
                    //           ? onBuyPressed()
                    //           : Navigator.of(context).popAndPushNamed("/shop");*/
                    //       if (gadgetName ==
                    //           (AppLocalizations.of(context)?.moves ?? "Play")) {
                    //         coinProvider.Crystals >= 150
                    //             ? onBuyPressed()
                    //             : Navigator.of(context)
                    //                 .popAndPushNamed("/shop");
                    //       } else {
                    //         onBuyPressed();
                    //       }
                    //     },
                    //     icon: const Icon(Icons.monetization_on),
                    //     label: Padding(
                    //       padding: const EdgeInsets.only(left: 8.0),
                    //       child: Text(
                    //         gadgetName ==
                    //                 (AppLocalizations.of(context)?.colorizer ??
                    //                     "Play")
                    //             ? (sale
                    //                 ? '100 ${AppLocalizations.of(context)?.crystals ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 10 ${AppLocalizations.of(context)?.colorizer ?? "Play"}'
                    //                 : 'EUR 0,49 ${AppLocalizations.of(context)?.forName ?? "Play"}\n10 ${AppLocalizations.of(context)?.colorizer ?? "Play"}')
                    //             : gadgetName ==
                    //                     (AppLocalizations.of(context)?.hints ??
                    //                         "Play")
                    //                 ? (sale
                    //                     ? '100 ${AppLocalizations.of(context)?.crystals ?? "Play"} ${AppLocalizations.of(context)?.forName ?? "Play"} 15 ${AppLocalizations.of(context)?.hints ?? "Play"}'
                    //                     : 'EUR 0,49 ${AppLocalizations.of(context)?.forName ?? "Play"}\n15 ${AppLocalizations.of(context)?.hints ?? "Play"}')
                    //                 : "150 ${AppLocalizations.of(context)?.crystals ?? "Play"}",
                    //         style: const TextStyle(
                    //           fontFamily: 'Quicksand',
                    //           fontSize: 16,
                    //         ),
                    //       ),
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       padding: const EdgeInsets.symmetric(
                    //           vertical: 10, horizontal: 20),
                    //       shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(10)),
                    //       backgroundColor: gradientColors.first,
                    //       foregroundColor: primaryColor,
                    //     ),
                    //   );
                    // }),
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
            icon: Icon(icon, color: primaryColor),
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

class PauseMenuDialog extends StatelessWidget {
  PuzzleModel puzzle;
  PauseMenuDialog({
    super.key,
    required this.puzzle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
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
              height: 30,
            ),

            // Continue Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow, size: 24),
              label: const Text(
                'Continue',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 25),

            // Home Button
            OutlinedButton.icon(
              onPressed: () {
                //! Maybe Problem dispose();
                Navigator.of(context).pushReplacement(
                  FadePageRoute(page: const MainMenuScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.home, size: 24),
              label: const Text(
                'Home',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 25),

            // Settings Button
            OutlinedButton.icon(
              onPressed: () {
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
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.settings, size: 24),
              label: const Text(
                'Settings',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionButton extends StatelessWidget {
  final ProductDetails product;
  final bool isPopular;
  final void Function() onPressed;

  const OptionButton({
    super.key,
    required this.product,
    this.isPopular = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.grey[200],
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.title,
              style: const TextStyle(fontSize: 16),
            ),
            (product.price != "-1")
                ? Text(
                    product.price,
                    style: const TextStyle(fontSize: 16),
                  )
                : const Icon(Icons.movie_creation, size: 40),
          ],
        ),
      ),
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
              color: primaryColor,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Text(
            text,
            style: TextStyle(color: primaryColor, fontSize: 28),
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
      icon: Icon(icon, color: primaryColor),
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
          color: primaryColor,
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

class HintScrollView extends StatefulWidget {
  final int hintCount;
  final PuzzleModel puzzle;

  const HintScrollView({
    super.key,
    required this.hintCount,
    required this.puzzle,
  });

  @override
  _HintScrollViewState createState() => _HintScrollViewState();
}

class _HintScrollViewState extends State<HintScrollView> {
  late PageController _pageController;
  int _currentHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.4);
    _pageController.addListener(() {
      setState(() {
        _currentHintIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.hintCount,
        onPageChanged: (index) {
          setState(() {
            _currentHintIndex = index;
          });
        },
        itemBuilder: (context, index) {
          // Scaling animation for the active hint
          bool isActive = index == _currentHintIndex;
          double scale = isActive ? 1.3 : 0.6;

          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () async {
                if (anzHintsGot >= index) {
                  if (widget.puzzle.moves >= 1) {
                    print("You have to reset the grid first");
                  } else {
                    anzHintsGot += 1;
                    bool temp = await widget.puzzle.getHint();
                    Navigator.of(context).pop();
                  }
                }

                // Action for selecting the hint
                print("Hint $index selected");
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  //color: isActive ? Colors.blueGrey[800] : Colors.black45,
                  color: const Color(0xffA3C5C4).withOpacity(0.8),
                  boxShadow: [
                    if (index <= anzHintsGot)
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Icon(Icons.lightbulb,
                              size: 70,
                              color: index <= anzHintsGot
                                  ? const Color(0xff404D52)
                                  : Colors.black26),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14.0),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                  color: index <= anzHintsGot
                                      ? Colors.white
                                      : Colors.black26,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        )
                      ],
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class LevelCompletionScreen extends StatelessWidget {
  // int selectedLevel;
  final int timeElapsed;
  final Function onContinue;
  final PuzzleModel puzzle;

  final texts = [
    "Yeah! Du hast dein erstes Level abgeschlossen.",
    "So langsam verstehst du es!",
    "Gar nicht so schwer, oder?",
  ];

  LevelCompletionScreen(
      {super.key,
      // required this.selectedLevel,
      required this.timeElapsed,
      required this.onContinue,
      required this.puzzle});

  @override
  Widget build(BuildContext context) {
    bool lastLevel = selectedLevel == -2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 80),

        // Title Text
        Text(
          "Level ${selectedLevel == -2 ? worlds[currentWorld - 1].anzahlLevels : selectedLevel - 1} ${AppLocalizations.of(context)?.completed ?? "Play"}",
          style: TextStyle(
            color: Colors.blueGrey[800],
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        ),

        //const Divider(),
        if (currentTutorialStep != TutorialStep.step2)
          const SizedBox(height: 20),

        // Feedback Text
        if (currentTutorialStep != TutorialStep.step2)
          Text(
            AppLocalizations.of(context)?.congratulations ?? "Play",
            style: TextStyle(
              color: Colors.blueGrey[800],
              fontSize: 18,
            ),
          ),

        const SizedBox(height: 35),
        if (currentTutorialStep == TutorialStep.step2)
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.indigo,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                textAlign: TextAlign.center,
                AppLocalizations.of(context)?.starAwarded ?? "Play",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        if (displayIndicator(puzzle))
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.indigo,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                textAlign: TextAlign.center,
                AppLocalizations.of(context)?.levelUp ?? "Play",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        // Time Display
        // Text(
        //   "TIME",
        //   style: TextStyle(
        //     color: Colors.blueGrey[800],
        //     fontSize: 18,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        if (currentTutorialStep == TutorialStep.none && false)
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

        if (currentTutorialStep != TutorialStep.none)
          const SizedBox(height: 50),

        const SizedBox(height: 45),

        // Navigation Buttons (Home, Stats, Share)
        if (currentTutorialStep == TutorialStep.none)
          _buildNavigationRow(context, lastLevel, puzzle),
        const SizedBox(
          height: 3,
        ),

        // Continue Button
        GestureDetector(
          onTap: () {
            if (lastLevel) {
              (Navigator.of(context).pushReplacement(
                FadePageRoute(page: const MainMenuScreen()),
              ));
              selectedLevel = worlds[currentWorld - 1].anzahlLevels;
            } else {
              onContinue();
            }
          },
          child: Stack(
            children: [
              Container(
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
                  color: primaryColor,
                ),
              ),
              if (displayIndicator(puzzle) && lastLevel)
                Positioned(
                  top: 3,
                  right: 15,
                  child: _BlinkingIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime2(int timeElapsed) {
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;

    return "$minutes:${seconds < 10 ? 0 : ""}$seconds";
  }

  bool displayIndicator(PuzzleModel puzzle) {
    for (int i = 0; i < worlds.length + 1; i++) {
      var unlocked = puzzle.getMaxLevelForWorld(i) != 0;
      if (puzzle.getCurrencyAmount() >= puzzle.getNeededCurrencyAmount(i - 1) &&
          !unlocked) {
        return true;
      }
    }

    return false;
  }

  void playGame(PuzzleModel puzzle, BuildContext context) async {
    int size = await puzzle.readSize(currentWorld, selectedLevel);
    int level = await puzzle.readMoves(currentWorld, selectedLevel);
    Navigator.of(context).pushReplacement(
      FadePageRoute(
        page: ChangeNotifierProvider(
            create: (_) => PuzzleModel(
                  size: size,
                  level: level,
                  colorMapping: {
                    1: worlds[currentWorld].colors[0],
                    2: worlds[currentWorld].colors[1],
                    3: worlds[currentWorld].colors[2],
                  },
                ),
            child: const PuzzleScreen()),
      ),
    );
  }

  // Updated _buildNavigationRow method to pass the showIndicator parameter
  Widget _buildNavigationRow(
      BuildContext context, bool lastLevel, PuzzleModel puzzle) {
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
            showIndicator: displayIndicator(
                puzzle), // Set to true when there’s something to claim
          ),
        // const SizedBox(
        //   width: 3,
        // ),
        // _buildNavButton(
        //   context,
        //   lastLevel: lastLevel,
        //   color: Colors.deepPurple,
        //   icon: Icons.bar_chart,
        //   onTap: () {
        //     // Handle stats action
        //   },
        //   showIndicator: false, // No indicator for stats button
        // ),
        const SizedBox(
          width: 3,
        ),
        _buildNavButton(
          context,
          lastLevel: lastLevel,
          color: Colors.deepPurple,
          icon: Icons.replay,
          onTap: () {
            !lastLevel
                ? selectedLevel -= 1
                : selectedLevel = worlds[currentWorld - 1].anzahlLevels;
            playGame(puzzle, context);
            // Handle share action
          },
          showIndicator: false, // No indicator for share button
        ),
      ],
    );
  }

// Updated _buildNavButton method to include a larger, blinking indicator
  Widget _buildNavButton(BuildContext context,
      {required Color color,
      required IconData icon,
      required Function onTap,
      required bool lastLevel,
      required bool showIndicator}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 35,
                color: primaryColor,
              ),
              if (showIndicator)
                Positioned(
                  top: 3,
                  right: 15,
                  child: _BlinkingIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create a separate widget for the blinking indicator
class _BlinkingIndicator extends StatefulWidget {
  @override
  __BlinkingIndicatorState createState() => __BlinkingIndicatorState();
}

class __BlinkingIndicatorState extends State<_BlinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Map the animation values from 0.6 to 1.0
    _opacityAnimation =
        Tween<double>(begin: 0.7, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
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
  late AnimationController controller;
  late Animation<Color?> colorAnimation;
  late Animation<double> sizeAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    colorAnimation = ColorTween(
      begin: Colors.indigo[300],
      end: Colors.indigo[500],
    ).animate(controller);

    sizeAnimation = Tween<double>(
      begin: 25,
      end: 28,
    ).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Text(
          AppLocalizations.of(context)?.tapToClaim ?? "Play",
          style: TextStyle(
            color: animations ? colorAnimation.value : Colors.indigo,
            fontSize: animations ? sizeAnimation.value : 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
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
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> positionAnimation;
  late List<Widget> Crystals;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(
          milliseconds: 1500), // Duration for the entire animation
      vsync: this,
    )..forward();

    scaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    Crystals = List.generate(
      widget.numberOfCrystals,
      (index) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final double scale = scaleAnimation.value;
          final double progress = positionAnimation.value;
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
        children: Crystals,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
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
  void launchPrivacyPolicy(BuildContext context) async {
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
                  onTap: () => launchPrivacyPolicy(context), // Open URL on tap
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
