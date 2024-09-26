// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/level_selection.dart';
import 'package:color_puzzle/main.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:color_puzzle/wallpaper_selection.dart';

import 'custom_info_button.dart';
import 'puzzle_model.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // final InAppPurchase inAppPurchase = InAppPurchase.instance;
  // final List<ProductDetails> products = [];
  int selectedWallpaperIndex = 1; // Default wallpaper selection
  //bool available = true; // Track availability of in-app purchases
  late BannerAd _bannerAd;
  final bool _isBannerAdReady = false;

  // void _loadProduct() async {
  //   const Set<String> productIds = {
  //     'de.tk.no.ads',
  //   };

  //   final ProductDetailsResponse response =
  //       await inAppPurchase.queryProductDetails(productIds);
  //   if (response.error == null && response.productDetails.isNotEmpty) {
  //     products.addAll(response.productDetails);
  //   }
  // }

  // void _buyProduct(ProductDetails productDetails, PuzzleModel puzzle) {
  //   final PurchaseParam purchaseParam =
  //       PurchaseParam(productDetails: productDetails);
  //   InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  // }

  // // Handle the purchase updates
  // void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
  //   for (var purchaseDetails in purchaseDetailsList) {
  //     if (purchaseDetails.status == PurchaseStatus.purchased) {
  //       // If the purchase is successful
  //       bool isVerified = _verifyPurchase(purchaseDetails);
  //       if (isVerified) {
  //         // Call your custom function after successful purchase
  //         _onPurchaseSuccess(purchaseDetails);
  //       }
  //     } else if (purchaseDetails.status == PurchaseStatus.canceled) {
  //       // Handle purchase failure
  //       print('Purchase failed: ${purchaseDetails.error}');
  //     }

  //     // Complete the purchase if necessary
  //     if (purchaseDetails.pendingCompletePurchase) {
  //       InAppPurchase.instance.completePurchase(purchaseDetails);
  //     }
  //   }
  // }

  // bool _verifyPurchase(PurchaseDetails purchaseDetails) {
  //   // Perform your verification logic (server-side verification is recommended)
  //   return true; // For demo purposes, assuming all purchases are verified.
  // }

  // void _onPurchaseSuccess(PurchaseDetails purchaseDetails) {
  //   puzzle.saveNoAds(true);
  //   noAds = true;
  //   _showPurchaseDialog(
  //       context,
  //       AppLocalizations.of(context)?.noAdsTitle ?? "Play",
  //       0,
  //       widget.puzzle,
  //       false);
  // }

  @override
  void initState() {
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
    _bannerAd.dispose();
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
        child: SafeArea(
          child: Stack(
            children: [
              Stack(
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
                      ),

                      const Spacer(),

                      _buildActionButton(
                          context, isWorldUnlocked, coinProvider, puzzle, () {
                        setState(() {
                          isWorldUnlocked = true;
                        });
                      }),
                      const SizedBox(height: 80),
                      const Divider(
                        thickness: 1.5,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildBottomRow(puzzle),
                      //const SizedBox(height: 30),
                    ],
                  ),
                  Column(
                    children: [const Spacer(), _buildGrid(), const Spacer()],
                  ),
                ],
              ),
              //_buildSwipeGestureDetector(),
              //_buildNavigationArrows(),
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
        padding: EdgeInsets.symmetric(
            horizontal: (MediaQuery.of(context).size.width < 500) ? 95.0 : 300),
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
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
                      //           textColor: Colors.white,
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
            ],
          ),
          Center(
            child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return LevelSelectionScreen(
                        onLevelSelected: _updateLevel,
                        worldIndex: worldIndex,
                        currentLevel: maxLevel,
                      );
                    },
                    isScrollControlled:
                        true, // Optional: damit Modal den ganzen Bildschirm ausfüllt
                  );
                },
                child: _buildTitleText(maxLevel)),
          )
        ],
      ),
    );
  }

  Widget _buildTitleText(int maxLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Level $selectedLevel',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
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
        ),
        const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white,
          size: 35,
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
          // if ((!worlds.last.unlocked && selectedLevel > 14) && false) {
          //   _showUnlockOptionsDialog(context, thisWorld, puzzle, () {});
          // } else {
          //   selectedLevel = maxLevel;

          Navigator.of(context).push(
            FadePageRoute(
              page: ChangeNotifierProvider(
                create: (_) => PuzzleModel(
                  size: puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2,
                  level:
                      puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
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
          //}
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            const SizedBox(width: 8),
            Text(
              "${AppLocalizations.of(context)?.play ?? "Play"} ${selectedLevel < maxLevel || maxLevel == -2 ? "Again" : ""}",
              style: const TextStyle(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open, color: Colors.white, size: 36),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.unlock ?? "Unlock",
              style: const TextStyle(
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

  Widget _buildBottomRow(PuzzleModel puzzle) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIconButton2(
                icon: Icons.more_vert,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                "ANFÄNGER",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
          Consumer<CoinProvider>(
            builder: (context, coinProvider, child) {
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
                    "${puzzle.getCurrencyAmount()}/${puzzle.getNeededCurrencyAmount(currentWorld)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              );
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
      color: Colors.black,
      onPressed: onPressed,
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
            border: Border.all(color: Colors.white, width: 1.5)),
        child: Icon(
          icon,
          color: Colors.white,
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
              style: const TextStyle(
                  color: Colors.white,
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
              child: Text(
                AppLocalizations.of(context)?.unlockTitle ?? "",
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
