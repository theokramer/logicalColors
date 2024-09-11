import 'dart:math';

import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'custom_info_button.dart'; // Dein CustomInfoButton
import 'coin_manager.dart'; // Dein CoinManager
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    if (_rewardedAd == null) {
      _loadRewardedAd();
    }
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

  void addRems(int amount) async {
    await context.read<RemsProvider>().addRems(amount); // Verwende den Provider
  }

  void subtractCrystals(int amount) async {
    await context
        .read<CoinProvider>()
        .subtractCrystals(amount); // Verwende den Provider
  }

  void buy(Map<String, dynamic> item, PuzzleModel puzzle) async {
    int type = item['type'] as int;
    int value = int.parse(item['title'] as String);
    int costs = 0;
    if (item['price'] == (AppLocalizations.of(context)?.free ?? "World") ||
        type == 2 ||
        type == 0 ||
        type == 1) {
      costs = 0;
    } else {
      costs = int.parse(item['price'] as String);
    }

    if (item['price'] == "") {
      _rewardedAd?.show(
        onUserEarnedReward: (_, reward) {
          _showPurchaseDialog(
              context,
              '${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.earned ?? "World"}',
              value,
              puzzle,
              true); // Zeige Pop-Up an
        },
      );
      _loadRewardedAd();
    }
    if (type == 2 &&
        item['price'] != (AppLocalizations.of(context)?.watchAds ?? "World")) {
      _showPurchaseDialog(
          context,
          '${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}',
          value,
          puzzle,
          false); // Zeige Pop-Up an
    }
    if (type == 0) {
      addHints(value);

      _showPurchaseDialog(
          context,
          '${AppLocalizations.of(context)?.hints ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}',
          value,
          puzzle,
          false); // Zeige Pop-Up an
    }
    if (type == 1) {
      addRems(value);
      _showPurchaseDialog(
          context,
          '${AppLocalizations.of(context)?.colorizer ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}',
          value,
          puzzle,
          false); // Zeige Pop-Up an
    }
  }

  RewardedAd? _rewardedAd;

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

  Future<void> handleBuyHint() async {
    if (context.read<CoinProvider>().Crystals >= 200) {
      await context.read<CoinProvider>().subtractCrystals(200);
      setState(() {
        // Hier sollten eventuell weitere Änderungen am Zustand vorgenommen werden
      });
    } else {
      // Nicht genügend Crystals
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    Future.microtask(() => context.read<CoinProvider>().loadCrystals());

    return Scaffold(
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.shop ?? "World",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
        ),
        foregroundColor: Colors.white,
        actions: [
          SizedBox(
            height: 65,
            width: 150,
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 20,
                  child: Consumer<CoinProvider>(
                    builder: (context, coinProvider, child) {
                      return CustomInfoButton(
                        value:
                            '${coinProvider.Crystals}', // Verwende die Crystals aus dem Provider
                        targetColor: -1,
                        movesLeft: -1,
                        iconPath: 'images/Crystals.png',
                        backgroundColor: Colors.black45,
                        textColor: Colors.white,
                        isLarge: 2,
                        originShop: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
            if (!noAds) _buildEnhancedBundleSection(puzzle),
            if (!noAds) const SizedBox(height: 15),
            _buildPageViewSection(puzzle),
            const SizedBox(height: 15),
            Expanded(child: _buildShopItemsGrid()),
            if (!worlds[1].unlocked)
              SafeArea(
                child: Text(
                  textAlign: TextAlign.center,
                  //worlds[1].unlocked
                  // ? ""
                  // : "With the purchase of any item in the shop, you unlock all current and future Levels in the game.",
                  (boughtWallpapers.length < 14)
                      ? AppLocalizations.of(context)?.freeWallpaper ?? "World"
                      : "",
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              )
          ],
        ),
      ),
    );
  }

  //int _currentPage = 0; // Current page indicator

  Widget _buildPageViewSection(PuzzleModel puzzle) {
    PageController pageController = PageController();

    return Column(
      children: [
        SizedBox(
          height:
              !puzzle.isWorldUnlocked(2) || !noAds ? 78 : 0, // Adjust as needed
          child: PageView(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                //_currentPage = index;
              });
            },
            children: [
              /*if (!puzzle.isWorldUnlocked(2))
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: _buildUnlockAllWorlds(puzzle),
                ),*/
              if (!noAds)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: _buildNoAdsBundleSection(puzzle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        //if (!puzzle.isWorldUnlocked(2) && !noAds)
        //_buildPageIndicator(pageController),
      ],
    );
  }

  Widget _buildPageIndicator(PageController controller) {
    return SmoothPageIndicator(
      controller: controller, // PageController
      count: 2, // Number of pages
      onDotClicked: (page) {
        controller.animateToPage(page,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
      },
      effect: WormEffect(
        dotHeight: 12.0,
        dotWidth: 12.0,
        spacing: 8.0,
        dotColor: Colors.white.withOpacity(0.3), // Inactive dot color
        activeDotColor: Colors.white, // Active dot color
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, String title, int amount,
      PuzzleModel puzzle, bool ad,
      {bool isEnhancedBundle = false}) {
    final Random random = Random();

    int newWallpaper = random.nextInt(14);
    if (boughtWallpapers.length < 14) {
      while (boughtWallpapers.contains(newWallpaper)) {
        newWallpaper = random.nextInt(14);
      }
      if (!boughtWallpapers.contains(newWallpaper) && !ad) {
        boughtWallpapers.add(newWallpaper);
        puzzle.saveBoughtWallpaper(newWallpaper);
      } else {
        newWallpaper = -1;
      }
    } else {
      newWallpaper = -1;
    }

    bool unlocked = false;
    int hintsAdded = 0;
    int wallpapersUnlocked = 0;

    if (!ad) {
      for (int i = 0; i < worlds.length; i++) {
        if (!puzzle.isWorldUnlocked(i + 1)) {
          puzzle.saveWorldUnlocked(i + 1, true);
          puzzle.unlockWorld(i + 1);
          puzzle.updateWorldLevel(i + 1, 1);
          puzzle.saveWorldProgress(i + 1, 1);
          unlocked = true;
        }
      }
    }

    // Special handling for the enhanced bundle
    if (isEnhancedBundle) {
      addCrystals(7000); // Adds 7000 crystals
      hintsAdded = 30; // Adds 30 hints
      puzzle.addHints(hintsAdded);
      wallpapersUnlocked = 3; // Assume bundle gives 3 wallpapers
      for (int i = 0; i < wallpapersUnlocked; i++) {
        newWallpaper = random.nextInt(14);
        while (boughtWallpapers.contains(newWallpaper)) {
          newWallpaper = random.nextInt(14);
        }
        boughtWallpapers.add(newWallpaper);
        puzzle.saveBoughtWallpaper(newWallpaper);
      }
      puzzle.saveNoAds(true);
      noAds = true;
      unlocked = true;
    }

    if (title ==
        "${AppLocalizations.of(context)?.crystals ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}") {
      addCrystals(amount);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            // Makes the content scrollable
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$title!',
                    style: TextStyle(
                      color: Colors.blueGrey[800],
                      fontSize: 24, // Reduced font size
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isEnhancedBundle)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            title ==
                                    "${AppLocalizations.of(context)?.hints ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}"
                                ? const Icon(
                                    Icons.lightbulb,
                                    size: 50,
                                    color: Colors.amber,
                                  )
                                : title ==
                                        "${AppLocalizations.of(context)?.colorizer ?? "World"} ${AppLocalizations.of(context)?.purchased ?? "World"}"
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
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  if (isEnhancedBundle)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/Crystals.png',
                              height: 40, // Smaller image
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '+7000 Crystals',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20, // Smaller font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              size: 40, // Smaller icon
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+$hintsAdded Hints',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 40, // Smaller icon
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+$wallpapersUnlocked Wallpapers',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: 40, // Smaller icon
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Ads Removed',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  if (newWallpaper != -1 && !isEnhancedBundle)
                    Container(
                      height: (MediaQuery.of(context).size.height > 700)
                          ? 150
                          : 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("images/w$newWallpaper.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (unlocked)
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_open,
                              size: 25, // Slightly smaller icon
                              color: Colors.green,
                            ),
                            Text(
                              AppLocalizations.of(context)?.unlockedWorlds ??
                                  "World",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14, // Smaller font size
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.great ?? "World",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBundleSection(PuzzleModel puzzle) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Colors.purple, // Updated background color
        borderRadius: BorderRadius.circular(30.0), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 12.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.5)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 8.0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /*const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    textAlign: TextAlign.center,
                    "Special Offer",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                ),*/
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeatureColumn(),
                    _buildItemsColumn(),
                  ],
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
          const SizedBox(height: 4), // Adjusted spacing
          _buildBottomCard(puzzle),
        ],
      ),
    );
  }

  Widget _buildFeatureColumn() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        children: [
          Image.asset(
            "images/no_ads_black.png", // Ensure correct asset path
            height: 65, // Slightly larger image
          ),
          const SizedBox(height: 5),
          Text(
            AppLocalizations.of(context)?.removeAdsBody ?? "Play",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8.5, // Larger font size
              fontWeight: FontWeight.w600,
              color: Colors.black87, // Darker text color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsColumn() {
    return Column(
      children: [
        Row(
          children: [
            _buildItem(Icons.monetization_on, '7000', Colors.black,
                "images/Crystals.png"),
            _buildItem(Icons.colorize, '20', Colors.red, ""),
          ],
        ),
        const SizedBox(height: 23), // Adjusted spacing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildItem(Icons.image, '3', Colors.green, ""),
            _buildItem(Icons.lightbulb, '30', Colors.amber, ""),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomCard(PuzzleModel puzzle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            '"${AppLocalizations.of(context)?.noAdsTitle ?? "Play"}"-Bundle',
            style: const TextStyle(
              fontSize: 16.0, // Larger font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton(
            onPressed: () {
              puzzle.saveNoAds(true);
              noAds = true;
              _showPurchaseDialog(
                  context,
                  '"${AppLocalizations.of(context)?.noAdsTitle ?? "Play"}"-Bundle',
                  0,
                  puzzle,
                  false,
                  isEnhancedBundle: true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              backgroundColor: Colors.green[500], // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
            ),
            child: const Text(
              'EUR 4,99',
              style: TextStyle(
                fontSize: 16.0, // Larger font size
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color matching button border
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String text, Color color, String imagePath) {
    return Container(
      width: 95, // Slightly wider container
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: const Color(0xffE0E7FF), // Updated background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 6),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          imagePath == ""
              ? Icon(
                  icon,
                  size: 22, // Larger icon size
                  color: color, // Updated icon color
                )
              : Image.asset(
                  imagePath,
                  height: 24,
                ),
          const SizedBox(
            width: 8,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15, // Larger font size
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Darker text color
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBundleItem(String iconPath, String quantity) {
    return Column(
      children: [
        Image.asset(
          iconPath,
          height: 30,
        ),
        const SizedBox(height: 8),
        Text(
          quantity,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildShopItemsGrid() {
    final puzzle = Provider.of<PuzzleModel>(context);
    final items = [
      //{'title': '1', 'price': 'Gratis!', 'type': 0},
      {'title': '10', 'price': 'EUR 0,49', 'type': 1},
      {'title': '15', 'price': 'EUR 0,49', 'type': 0},
      {'title': '40', 'price': 'EUR 0,99', 'type': 0},
      {'title': '150', 'price': 'Watch Ad', 'type': 2},
      {'title': '700', 'price': 'EUR 0,49', 'type': 2},
      {'title': '1800', 'price': 'EUR 0,99', 'type': 2},
      {'title': '4000', 'price': 'EUR 1,99', 'type': 2},
      {'title': '9000', 'price': 'EUR 3,99', 'type': 2},
      {'title': '30000', 'price': 'EUR 7,99', 'type': 2},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
            onTap: () {
              buy(item, puzzle); // Rufe die Kauf-Funktion mit dem Artikel auf
            },
            child: _buildShopItemCard(item['title'] as String,
                item['price'] as String, item['type'] as int));
      },
    );
  }

  Widget _buildShopItemCard(String title, String price, int type) {
    return Stack(
      clipBehavior: Clip.none, // Allow overflow
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent, // Outer container color
            borderRadius:
                BorderRadius.circular(20.0), // Outer container rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 12.0,
              ),
            ],
          ),
          child: Column(
            children: [
              FittedBox(
                child: Container(
                  width: 98,
                  height: 82,
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 8.0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      type == 0
                          ? const Icon(
                              Icons.lightbulb,
                              size: 40,
                              color: Colors.amber,
                            )
                          : type == 1
                              ? const Icon(
                                  Icons.colorize,
                                  size: 40,
                                  color: Colors.red,
                                )
                              : const SizedBox(
                                  height: 0,
                                ),
                      if (type == 2) const SizedBox(height: 45.0),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  (type == 0 || type == 1) &&
                          price !=
                              '${AppLocalizations.of(context)?.free ?? "Play"}!'
                      ? const SizedBox(
                          width: 8,
                        )
                      : const SizedBox(),
                  /*(type == 0 || type == 1) && price != 'Gratis!'
                      ? Image.asset(
                          title == '150' || title == '700'
                              ? "images/Crystals_less.png"
                              : "images/Crystals.png",
                          height: 15)
                      : const SizedBox(),*/
                ],
              ),
            ],
          ),
        ),
        // Overflowing coin image
        if (type == 2)
          SizedBox(
            width: 150,
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Positioned(
                            child: SizedBox(
                                width: 50,
                                height:
                                    title == '150' || title == '700' ? 45 : 45,
                                child: Image.asset(
                                    title == '150' || title == '700'
                                        ? "images/Crystals.png"
                                        : "images/Crystals.png",
                                    height: 100)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildUnlockAllWorlds(PuzzleModel puzzle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Icon(
                  Icons.lock_open,
                  size: 35, // Larger icon size
                  color: Colors.white, // Updated icon color
                ),
                SizedBox(
                  width: 12,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Unlock all Worlds',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Unlocks all worlds in the app.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () {
                for (int i = 0; i < worlds.length; i++) {
                  puzzle.saveWorldUnlocked(i + 1, true);
                  puzzle.unlockWorld(i + 1);
                  puzzle.updateWorldLevel(i + 1, 1);
                  puzzle.saveWorldProgress(i + 1, 1);

                  // Add unlock single world logic here
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                backgroundColor: Colors.green[500], // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
              ),
              child: const Text(
                'EUR 1,99',
                style: TextStyle(
                  fontSize: 16.0, // Larger font size
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color matching button border
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAdsBundleSection(PuzzleModel puzzle) {
    return Container(
      padding: const EdgeInsets.only(left: 10.0),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Row(
                  children: [
                    Image.asset(
                      "images/no_ads.png", // Ensure correct asset path
                      height: 55, // Slightly larger image
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.noAdsTitle ?? "Play",
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)?.removeAdsBody ?? "Play",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    puzzle.saveNoAds(true);
                    noAds = true;
                    _showPurchaseDialog(
                        context,
                        AppLocalizations.of(context)?.noAdsTitle ?? "Play",
                        0,
                        puzzle,
                        false);
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    backgroundColor:
                        Colors.green[500], // Button background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                    ),
                  ),
                  child: const Text(
                    'EUR 2,99',
                    style: TextStyle(
                      fontSize: 16.0, // Larger font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color matching button border
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
