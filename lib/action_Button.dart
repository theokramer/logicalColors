import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';

class CustomActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int count;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color borderColor;
  final bool blink;

  const CustomActionButton(
      {super.key,
      required this.icon,
      required this.onPressed,
      required this.count,
      required this.gradientColors,
      required this.iconColor,
      this.blink = false,
      this.borderColor = Colors.transparent});

  @override
  State<CustomActionButton> createState() => _CustomActionButtonState();
}

class _CustomActionButtonState extends State<CustomActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

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
      begin: widget.gradientColors.first,
      end: widget.gradientColors.last, // End color
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth transition
    ));

    // Add a listener to control the blinking behavior
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // When the animation completes, reverse it to create the blink effect
        _controller.reverse();
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
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: tutorialActive &&
                  widget.count != -1 &&
                  currentTutorialStep != TutorialStep.step5 &&
                  currentTutorialStep != TutorialStep.completed
              ? null
              : widget.onPressed,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 50,
                    decoration: widget.blink
                        ? BoxDecoration(
                            color: _colorAnimation.value ??
                                widget.gradientColors.first,
                            border:
                                Border.all(color: widget.borderColor, width: 3),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          )
                        : BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border:
                                Border.all(color: widget.borderColor, width: 3),
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
                          widget.icon,
                          color: widget.iconColor,
                          size: 26,
                        ),
                        (widget.count == -1 || widget.count == 0)
                            ? const Text("")
                            : const SizedBox(
                                width: 10), // Space between icon and text
                        Text(
                          (widget.count == -1 || widget.count == 0)
                              ? ''
                              : widget.count.toString(),
                          //count == -1 ? '\u221e' : count.toString(),
                          style: TextStyle(
                            color: widget.iconColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.count == 0)
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
      },
    );
  }
}
