import 'dart:math';

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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)?.chooseWallpaper ??
                  "Choose Wallpaper",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.65,
              ),
              itemCount: 19, // updated to 19
              itemBuilder: (context, index) {
                bool isLocked = !boughtWallpapers.contains(index);

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      _showWallpaperPreview(
                          context, index, isLocked, coinProvider, puzzle);
                    } else {
                      setState(() {
                        selectedWallpaper = index;
                        puzzle.saveSelectedWallpaper(selectedWallpaper);
                      });
                      widget.onWallpaperSelected(index);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedWallpaper == index
                              ? Colors.green
                              : Colors.transparent,
                          width: 5,
                        ),
                        // If it's one of the 5 new wallpapers, just use a solid color
                        color: getBackgroundColor(index),
                        image: index < 19
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
                      child: isLocked
                          ? Center(
                              child: Text(
                                '${(exp(index * 0.4) * 15 + index * 50 + log(index * 10000)).floor()}\n${AppLocalizations.of(context)?.crystals ?? "Crystals"}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
          if (boughtWallpapers.length < 19)
            Column(
              children: [
                const SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _buyRandomWallpaper(context, coinProvider, puzzle);
                    },
                    child: Text(
                        '${AppLocalizations.of(context)?.randomCTA ?? "Get random for"} 2000 ${AppLocalizations.of(context)?.crystals ?? "Crystals"}'),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            )
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
                      // Show color preview for new wallpapers
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
                              '${AppLocalizations.of(context)?.unlock ?? "Unlock"} ${AppLocalizations.of(context)?.forName ?? "for"} ${(exp(index * 0.4) * 15 + index * 50 + log(index * 10000)).floor()} ${AppLocalizations.of(context)?.crystals ?? "Crystals"}'),
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

  void _buyRandomWallpaper(
      BuildContext context, CoinProvider coinProvider, PuzzleModel puzzle) {
    const int wallpaperCost = 2000;
    int totalWallpapers = 19; // Updated to 19 wallpapers
    int randomWallpaperIndex = Random().nextInt(totalWallpapers);

    while (boughtWallpapers.contains(randomWallpaperIndex)) {
      randomWallpaperIndex = Random().nextInt(totalWallpapers);
    }

    unlockWallpaper(
        context, randomWallpaperIndex, coinProvider, puzzle, wallpaperCost);
  }

  void unlockWallpaper(
    BuildContext context,
    int index,
    CoinProvider coinProvider,
    PuzzleModel puzzle,
    int wallpaperCost,
  ) {
    if (coinProvider.Crystals >= wallpaperCost) {
      coinProvider.subtractCrystals(wallpaperCost);
      setState(() {
        selectedWallpaper = index;
      });
      puzzle.saveBoughtWallpaper(selectedWallpaper);
      puzzle.saveSelectedWallpaper(selectedWallpaper);
      if (!boughtWallpapers.contains(selectedWallpaper)) {
        boughtWallpapers.add(selectedWallpaper);
      }
      Navigator.pop(context);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShopScreen(
            puzzle: puzzle,
          ),
        ),
      );
    }
  }
}
