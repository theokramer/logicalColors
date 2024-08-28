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
  final bool isLarge; // New parameter to adjust size

  const CustomInfoButton({
    required this.value,
    required this.targetColor,
    required this.movesLeft,
    required this.iconPath,
    required this.backgroundColor,
    required this.textColor,
    this.isLarge = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    double fontSize = isLarge ? 18 : 14;
    double iconSize = isLarge ? 32 : 24;
    double padding = isLarge ? 10 : 6;

    return Container(
      padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Coin Icon
          iconPath != "" ?
          Image.asset(
            iconPath,
            height: iconSize,
            width: iconSize,
          ) : Text(""),
          iconPath != "" ? SizedBox(width: 8) : Text(""),
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
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: iconSize * 0.8,
              height: iconSize * 0.8,
              decoration: BoxDecoration(
                color: puzzle.getColor(targetColor), // Function to get color from name
                shape: BoxShape.circle,
              ),
            ),
            
            
          ],
          if (movesLeft > -1) ...[
            // Moves Left
            Text(
              '$movesLeft Moves',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ],
      ),
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
