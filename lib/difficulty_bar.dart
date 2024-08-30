import 'package:flutter/material.dart';

  double calculateDifficulty(int maxMoves, int gridSize) {
    double difficulty = ((maxMoves * 3) / ((gridSize * gridSize) + 6)) * 0.9; // Adjusting the multiplier to keep within 0 to 1 range
    return difficulty.clamp(0.0, 1.0);
  }

class HorizontalDifficultyBar extends StatelessWidget {
  final int gridSize;
  final int maxMoves;
  final List<Color> colors;

  HorizontalDifficultyBar({
    required this.gridSize,
    required this.maxMoves,
    required this.colors,
  });

  // Calculate the difficulty as a value between 0.0 and 1.0


  // Generate segments based on difficulty
  List<Widget> buildSegments(double difficulty) {
    int totalSegments = 10;
    int filledSegments = (difficulty * totalSegments).round();

    // Determine the thresholds for green, yellow, and red segments
    int greenThreshold = (totalSegments * 0.3).ceil();  // 30% of the bar is green
    int yellowThreshold = (totalSegments * 0.6).ceil(); // 60% of the bar is yellow

    return List.generate(totalSegments, (index) {
      bool isFilled = index < filledSegments;
      Color segmentColor;

      if (isFilled) {
        // Choose color based on the segment's position
        if (index < greenThreshold) {
          segmentColor = colors[0];
        } else if (index < yellowThreshold) {
          segmentColor = colors[1];
        } else {
          segmentColor = colors[2];
        }
      } else {
        // Grey for unfilled segments
        segmentColor = Colors.grey.shade300;
      }

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 20,
          decoration: BoxDecoration(
            color: segmentColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = calculateDifficulty(maxMoves, gridSize);
    final segments = buildSegments(difficulty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Row(
          children: segments,
        ),
        SizedBox(height: 8),
        Text(
          'Difficulty',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
