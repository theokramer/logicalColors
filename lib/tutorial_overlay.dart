import 'package:flutter/material.dart';
import 'dart:ui'; // For the BackdropFilter

class AnimatedCustomOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onClose;
  final bool blink;

  const AnimatedCustomOverlay({Key? key, required this.message, required this.onClose, required this.blink})
      : super(key: key);

  @override
  _AnimatedCustomOverlayState createState() => _AnimatedCustomOverlayState();
}

class _AnimatedCustomOverlayState extends State<AnimatedCustomOverlay>
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
      begin: Colors.indigo.withOpacity(0.5), 
      end: Colors.red, // End color
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth transition
    ));

    // Add a listener to control the blinking behavior
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _blinkCount < 3) {
        // When the animation completes, reverse it to create the blink effect
        _controller.reverse();
        _blinkCount++;
      } else if (status == AnimationStatus.dismissed && _blinkCount < 3) {
        // When the reverse completes, start the forward animation again
        _controller.forward();
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounded corners
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
            child: AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: widget.blink ? _colorAnimation.value : Colors.indigo.withOpacity(0.5), // Use the animated color
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5), // Soft shadow
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16), // Padding inside the overlay
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white, // Matches light or dark theme
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
