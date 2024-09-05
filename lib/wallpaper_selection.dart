import 'dart:math';

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
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.65,
              ),
              itemCount: 12,
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedWallpaper == index
                            ? Colors.green
                            : Colors.transparent,
                        width: 3,
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
                              '${(log(index * 10000) * index * 50).floor()}\nCoins',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
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
          child: Column(
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
                        _unlockWallpaper(context, index, coinProvider, puzzle);
                      },
                      child: Text('Unlock for ${exp(index).floor()} coins'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedWallpaper = index;
                        });
                        puzzle.saveSelectedWallpaper(selectedWallpaper);
                        Navigator.pop(context); // Close the dialog
                        Navigator.pop(
                            context); // Close the wallpaper selection dialog
                      },
                      child: const Text('Select Wallpaper'),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _unlockWallpaper(BuildContext context, int index,
      CoinProvider coinProvider, PuzzleModel puzzle) {
    int wallpaperCost = (exp(index)).floor();

    if (coinProvider.coins >= wallpaperCost) {
      coinProvider.subtractCoins(wallpaperCost); // Deduct coins
      setState(() {
        // Unlock the wallpaper logic here
        selectedWallpaper = index;
      });
      puzzle.saveBoughtWallpaper(selectedWallpaper);
      puzzle.saveSelectedWallpaper(selectedWallpaper); // Save the selection
      boughtWallpapers.add(index);
      Navigator.pop(context); // Close the purchase dialog
      //Navigator.pop(context); // Close the preview dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins!'),
        ),
      );
    }
  }
}
