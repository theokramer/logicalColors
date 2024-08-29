import 'package:flutter/material.dart';
import 'dart:ui'; // For the BackdropFilter

class CustomOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const CustomOverlay({Key? key, required this.message, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Rounded corners
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
            child: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.5), // Transparent background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5), // Soft shadow
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16), // Padding inside the overlay
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white, // Matches light or dark theme
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
