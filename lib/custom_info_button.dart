import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomInfoButton extends StatefulWidget {
  final String value;
  final int targetColor;
  final int movesLeft;
  final String iconPath;
  final Color backgroundColor;
  final Color textColor;
  final int isLarge; // New parameter to adjust size
  final bool blink;
  final bool originShop;

  const CustomInfoButton(
      {super.key,
      required this.value,
      required this.targetColor,
      required this.movesLeft,
      required this.iconPath,
      required this.backgroundColor,
      required this.textColor,
      this.blink = false,
      this.isLarge = 0, // Default to false
      this.originShop = false});

  @override
  State<CustomInfoButton> createState() => _CustomInfoButtonState();
}

class _CustomInfoButtonState extends State<CustomInfoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  int _blinkCount = 0; // To keep track of the number of blinks

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Duration of one blink
      vsync: this,
    );

    // Define the animation to transition from red to indigo
    _colorAnimation = ColorTween(
      begin: Colors.amber,
      end: Colors.orange, // End color
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth transition
    ));

    // Add a listener to control the blinking behavior
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // When the animation completes, reverse it to create the blink effect
        _controller.reverse();
        _blinkCount++;
      } else if (status == AnimationStatus.dismissed) {
        // When the reverse completes, start the forward animation again
        _controller.forward();
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    double fontSize = widget.isLarge == 0
        ? 20
        : widget.isLarge == 1
            ? 16
            : 16;
    double iconSize = widget.isLarge == 0
        ? 34
        : widget.isLarge == 1
            ? 20
            : 16;
    double padding = widget.isLarge == 0
        ? 18
        : widget.isLarge == 1
            ? 14
            : 6;

    return GestureDetector(
      onTap: tutorialActive
          ? null
          : () => widget.isLarge != 1 && widget.isLarge != 2
              ? _showInfoDialog(context)
              : widget.isLarge == 2 && !widget.originShop
                  ? Navigator.of(context).push(
                      FadePageRoute(
                        page: ShopScreen(
                          puzzle: puzzle,
                        ), // Verwende hier das existierende PuzzleModel
                      ),
                    )
                  : null, // Show info dialog on tap
      child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              padding:
                  EdgeInsets.symmetric(vertical: padding, horizontal: padding),
              decoration: !widget.blink
                  ? BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius:
                          BorderRadius.circular(widget.isLarge == 0 ? 15 : 10),
                    )
                  : BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(
                        widget.isLarge == 0 ? 15 : 10,
                      ),
                      border: Border.all(
                          color: _colorAnimation.value ?? Colors.amber,
                          width: 4),
                    ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coin Icon
                  widget.iconPath != ""
                      ? Image.asset(
                          widget.iconPath,
                          height: iconSize,
                          width: iconSize,
                        )
                      : const SizedBox(),
                  widget.iconPath != ""
                      ? const SizedBox(width: 8)
                      : const SizedBox(),
                  // Coin Value
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                  if (widget.targetColor != -1) ...[
                    // Target Color
                    Text(
                      AppLocalizations.of(context)?.fill ?? "Play",
                      style: TextStyle(
                          color: widget.textColor.withOpacity(0.8),
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: iconSize * 0.8,
                      height: iconSize * 0.8,
                      decoration: BoxDecoration(
                        color: puzzle.getColor(widget
                            .targetColor), // Function to get color from name
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(
                        "${widget.targetColor}",
                        style: TextStyle(
                            fontSize: widget.isLarge == 0 ? 15 : 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      )),
                    ),
                  ],
                  if (widget.movesLeft > -1 && widget.targetColor == -1) ...[
                    // Moves Left
                    Text(
                      '${widget.movesLeft} ${widget.movesLeft == 1 ? AppLocalizations.of(context)?.move ?? "Play" : AppLocalizations.of(context)?.moves ?? "Play"}',
                      style: TextStyle(
                          color: widget.textColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            );
          }),
    );
  }

  // Function to show the information dialog
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.targetColor != -1
              ? AppLocalizations.of(context)?.colorTheGrid ?? "Play"
              : "${widget.movesLeft == 1 ? AppLocalizations.of(context)?.oneNStep ?? "Play" : "${widget.movesLeft} ${AppLocalizations.of(context)?.dialogMoreSteps ?? "Play"}"} ${AppLocalizations.of(context)?.left ?? "Play"}"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To fit the content size
            children: [
              Text(
                widget.targetColor != -1
                    ? '${AppLocalizations.of(context)?.tDialogContentTargetColor ?? "Play"} ${widget.movesLeft == 1 ? AppLocalizations.of(context)?.oneNStep ?? "Play" : "${widget.movesLeft} ${AppLocalizations.of(context)?.dialogMoreSteps ?? "Play"}"} ${AppLocalizations.of(context)?.left ?? "Play"}! ${AppLocalizations.of(context)?.dialogReminderAdjacent ?? "Play"}'
                    : '${AppLocalizations.of(context)?.tDialogContentStepsLeft ?? "Play"} ${widget.movesLeft == 1 ? AppLocalizations.of(context)?.oneNStep ?? "Play" : "${widget.movesLeft} ${AppLocalizations.of(context)?.dialogMoreSteps ?? "Play"}"} ${AppLocalizations.of(context)?.left ?? "Play"}, ${AppLocalizations.of(context)?.toReachGoal ?? "Play"}.',
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
