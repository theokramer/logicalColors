import 'dart:math';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_manager.dart';
import 'puzzle_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WallpaperSelectionWidget extends StatefulWidget {
  final Function(int) onWallpaperSelected;

  const WallpaperSelectionWidget(
      {super.key, required this.onWallpaperSelected});

  @override
  _WallpaperSelectionWidgetState createState() =>
      _WallpaperSelectionWidgetState();
}

class _WallpaperSelectionWidgetState extends State<WallpaperSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    final coinProvider = Provider.of<CoinProvider>(context);

    return Container(
      decoration: selectedWallpaper < 5
          ? BoxDecoration(
              color: getBackgroundColor(selectedWallpaper),
            )
          : BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/w${selectedWallpaper - 5}.jpg"),
                fit: BoxFit.cover,
              ),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.65,
              ),
              itemCount: 17, // updated to 19
              itemBuilder: (context, index) {
                bool isLocked = !boughtWallpapers.contains(index);
                bool isUnlockable = puzzle.getCurrencyAmount() >=
                    puzzle.getNeededCurrencyAmount(index);

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      if (isUnlockable) {
                        _showWallpaperPreview(
                            context, index, isLocked, coinProvider, puzzle);
                      } else {
                        // Show a message that the user needs more stars
                        _showUnlockMessage(context, index, puzzle);
                      }
                    } else {
                      setState(() {
                        selectedWallpaper = index;
                        puzzle.saveSelectedWallpaper(selectedWallpaper);
                      });
                      widget.onWallpaperSelected(index);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedWallpaper == index
                              ? Colors.green
                              : Colors.transparent,
                          width: 5,
                        ),
                        color: getBackgroundColor(index),
                        image: index < 17
                            ? DecorationImage(
                                image: AssetImage("images/w${index - 5}.jpg"),
                                fit: BoxFit.cover,
                                colorFilter: isLocked
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.5),
                                        BlendMode.darken,
                                      )
                                    : null,
                              )
                            : null,
                      ),
                      child: isLocked && !isUnlockable
                          ? Center(
                              child: Text(
                                'Unlock by reaching ${index < 6 ? worlds[index].name : worlds[5].name}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : !isLocked
                              ? null
                              : isUnlockable
                                  ? const Center(
                                      child: Text(
                                        'Unlock for free',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWallpaperPreview(BuildContext context, int index, bool isLocked,
      CoinProvider coinProvider, PuzzleModel puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: index >= 0 && index < 5
                          ? (getBackgroundColor(index))
                          : null,
                      image: index > 4
                          ? DecorationImage(
                              image: AssetImage("images/w${index - 5}.jpg"),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    height: 500,
                    width: 300,
                  ),
                  const SizedBox(height: 16),
                  isLocked
                      ? ElevatedButton(
                          onPressed: () {
                            unlockWallpaper(
                                context,
                                index,
                                coinProvider,
                                puzzle,
                                (exp(index * 0.4) * 15 +
                                        index * 50 +
                                        log(index * 10000))
                                    .floor());
                          },
                          child: Text(
                              '${AppLocalizations.of(context)?.unlock ?? "Unlock"} ${AppLocalizations.of(context)?.forName ?? "for"} free'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedWallpaper = index;
                            });
                            puzzle.saveSelectedWallpaper(selectedWallpaper);
                            Navigator.pop(context);
                          },
                          child: Text(
                              AppLocalizations.of(context)?.selectWallpaper ??
                                  "Select Wallpaper"),
                        ),
                  const SizedBox(
                    height: 16,
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUnlockMessage(BuildContext context, int index, PuzzleModel puzzle) {
    final requiredStars = puzzle.getNeededCurrencyAmount(index);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("You have not enough stars"),
          content: Text(
              "You need $requiredStars stars to unlock this wallpaper. You can collect stars, by completing levels"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)?.close ?? "Close"),
            ),
          ],
        );
      },
    );
  }

  void unlockWallpaper(
    BuildContext context,
    int index,
    CoinProvider coinProvider,
    PuzzleModel puzzle,
    int wallpaperCost,
  ) {
    // if (coinProvider.Crystals >= wallpaperCost) {
    //   coinProvider.subtractCrystals(wallpaperCost);
    //   setState(() {
    //     selectedWallpaper = index;
    //   });

    //   Navigator.pop(context);
    // } else {
    //   Navigator.of(context).push(
    //     FadePageRoute(
    //       page: const ShopScreen(),
    //     ),
    //   );
    // }
    selectedWallpaper = index;
    puzzle.saveBoughtWallpaper(selectedWallpaper);
    puzzle.saveSelectedWallpaper(selectedWallpaper);
    if (!boughtWallpapers.contains(selectedWallpaper)) {
      boughtWallpapers.add(selectedWallpaper);
    }
    Navigator.pop(context);
  }
}
