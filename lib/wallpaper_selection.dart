import 'dart:math';

import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'coin_manager.dart';
import 'puzzle_model.dart';

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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Choose Wallpaper',
              style: TextStyle(
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
              itemCount: 14,
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
                        image: DecorationImage(
                          image: AssetImage("images/w$index.jpg"),
                          fit: BoxFit.cover,
                          colorFilter: isLocked
                              ? ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken,
                                )
                              : null,
                        ),
                      ),
                      child: isLocked
                          ? Center(
                              child: Text(
                                '${(exp(index * 0.55) * 15 + index * 220 + log(index * 10000)).floor()}\nCoins',
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
          if (boughtWallpapers.length < 14)
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
                    child: const Text('Get random for 2000 Coins'),
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
                      image: DecorationImage(
                        image: AssetImage("images/w$index.jpg"),
                        fit: BoxFit.cover,
                      ),
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
                                (exp(index * 0.5) * 10 +
                                        index * 200 +
                                        log(index * 10000))
                                    .floor());
                          },
                          child: Text(
                              'Unlock for ${(exp(index * 0.5) * 10 + index * 200 + log(index * 10000)).floor()} coins'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Unlock the wallpaper logic here
                              selectedWallpaper = index;
                            });
                            puzzle.saveSelectedWallpaper(
                                selectedWallpaper); // Save the selection
                            Navigator.pop(context); // Close the purchase dialog
                          },
                          child: const Text('Select Wallpaper'),
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

    // Select a random wallpaper
    int totalWallpapers = 14; // Assuming there are 14 wallpapers
    int randomWallpaperIndex = Random().nextInt(totalWallpapers);

    // Ensure the random wallpaper hasn't been bought already
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
    if (coinProvider.coins >= wallpaperCost) {
      coinProvider.subtractCoins(wallpaperCost); // Deduct coins
      setState(() {
        // Unlock the wallpaper logic here
        selectedWallpaper = index;
      });
      puzzle.saveBoughtWallpaper(selectedWallpaper);
      puzzle.saveSelectedWallpaper(selectedWallpaper); // Save the selection
      if (!boughtWallpapers.contains(selectedWallpaper)) {
        boughtWallpapers.add(selectedWallpaper);
      }
      Navigator.pop(context); // Close the purchase dialog
      //Navigator.pop(context); // Close the preview dialog
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ShopScreen(),
        ),
      );
    }
  }
}
