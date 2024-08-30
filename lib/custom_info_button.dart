import 'package:color_puzzle/puzzle_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomInfoButton extends StatelessWidget {
  final String value;
  final int targetColor;
  final int movesLeft;
  final String iconPath;
  final Color backgroundColor;
  final Color textColor;
  final int isLarge; // New parameter to adjust size

  const CustomInfoButton({
    required this.value,
    required this.targetColor,
    required this.movesLeft,
    required this.iconPath,
    required this.backgroundColor,
    required this.textColor,
    this.isLarge = 0, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    double fontSize = isLarge == 0 ? 20 : isLarge == 1 ? 18 : 16;
    double iconSize = isLarge == 0 ? 34 : isLarge == 1 ? 22 : 16;
    double padding = isLarge == 0 ? 18 : isLarge == 1 ? 12 : 6;

    return GestureDetector(
      onTap: () => _showInfoDialog(context), // Show info dialog on tap
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isLarge == 0 ? 15 : 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coin Icon
            iconPath != ""
                ? Image.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                  )
                : const SizedBox(),
            iconPath != "" ? const SizedBox(width: 8) : const SizedBox(),
            // Coin Value
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            if (targetColor != -1) ...[
              // Target Color
              Text(
                'Fill',
                style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                width: iconSize * 0.8,
                height: iconSize * 0.8,
                decoration: BoxDecoration(
                  color: puzzle.getColor(targetColor), // Function to get color from name
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (movesLeft > -1 && targetColor == -1) ...[
              // Moves Left
              Text(
                '$movesLeft Moves',
                style: TextStyle(
                    color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Function to show the information dialog
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(targetColor != - 1 ? 'Grid einfärben' : "${movesLeft == 1 ? 'Ein Schritt' : "$movesLeft Schritte"} übrig"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              Text(
                targetColor != -1
                    ? 'Fülle das gesamte Raster mit der ausgewählten Farbe. Du hast noch ${movesLeft == 1 ? 'einen Schritt' : "$movesLeft Schritte"}! Denke daran, dass auch benachbarte Felder sich verfärben'
                    : 'Du hast noch ${movesLeft == 1 ? 'einen Schritt' : "$movesLeft Schritte"}, um das Ziel zu erreichen.',
              ),
              const SizedBox(height: 30), // Space between text and GIF
            Image.asset(
              'images/tutorial_animation.gif', // Replace with your local path to the GIF
              height: 250, // Adjust the height as needed
              fit: BoxFit.cover, // Adjust to cover or contain based on the look you want
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

  // Helper function to get color from name
  Color getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey; // Default color
    }
  }
}

