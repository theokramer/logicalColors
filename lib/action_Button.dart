import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int count;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color borderColor;

  const CustomActionButton(
      {super.key,
      required this.icon,
      required this.onPressed,
      required this.count,
      required this.gradientColors,
      required this.iconColor,
      this.borderColor = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tutorialActive && count != -1 && borderColor == Colors.transparent
          ? null
          : onPressed,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: borderColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 26,
                    ),
                    (count == -1 || count == 0)
                        ? const Text("")
                        : const SizedBox(
                            width: 10), // Space between icon and text
                    Text(
                      (count == -1 || count == 0) ? '' : count.toString(),
                      //count == -1 ? '\u221e' : count.toString(),
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (count == 0)
                SizedBox(
                  width: 90,
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              Positioned(
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: const BoxDecoration(
                                    color: Colors.green, // Badge color
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}
