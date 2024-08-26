import 'package:color_puzzle/congratulations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'package:confetti/confetti.dart'; // Import confetti package
import 'package:flutter/services.dart'; // Import for HapticFeedback

int currentLevel = 1;

class PuzzleScreen extends StatefulWidget {
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController; // Define the ConfettiController
  late AnimationController _animationController; // Define the AnimationController
  late Animation<double> _animation;
  double pi = 3.1415926535897932;

  @override
  void initState() {
    super.initState();
    // Initialize the ConfettiController
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 300));

    // Initialize AnimationController
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define the scale animation
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Dispose the controller when not needed
    _animationController.dispose(); // Dispose AnimationController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Level $currentLevel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.purpleAccent,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        elevation: 10,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Image.asset(
                  'images/coins.png',
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 4),
                Text(
                  '$coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard('Moves', '${puzzle.moves} / ${puzzle.maxMoves}'),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.black, size: 28),
                      onPressed: () {
                        puzzle.grid = puzzle.savedGrid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
                        puzzle.resetMoves();
                        puzzle.moveWhereError = -1;
                        puzzle.clicks = puzzle.savedClicks.map((click) => List<int>.from(click)).toList(); // Deep copy clicks
                      },
                    ),
                    _buildTargetColorBox(puzzle.targetColor),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: puzzle.size,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: puzzle.size * puzzle.size,
                  itemBuilder: (context, index) {
                    int x = index ~/ puzzle.size;
                    int y = index % puzzle.size;
                    int colorNumber = puzzle.grid[x][y];
                    Color tileColor = puzzle.getColor(colorNumber);
                    bool isHintTile = (x == puzzle.hintX && y == puzzle.hintY);

                    return ScaleTransition(
                      scale: _animation,
                      child: GestureDetector(
                        onTap: () {
                          puzzle.clickTile(x, y, false);

                          if (puzzle.isGridFilledWithTargetColor()) {
                            _confettiController.play(); 
                            HapticFeedback.heavyImpact();
                            _animationController.forward().then((_) {
                              Future.delayed(Duration(milliseconds: 200), () {
                                _animationController.reverse();
                                Future.delayed(Duration(milliseconds: 1200), () {
                                  puzzle.addCoins(30);
                                  // Trigger confetti animation
                                  setState(() {
                                    currentLevel += 1;
                                  });
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => CongratulationsScreen(currentLevel: currentLevel),
                                    ),
                                  );
                                });
                              });
                            });
                          } else {
                            HapticFeedback.selectionClick();
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tileColor.withOpacity(0.7), tileColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: isHintTile
                                ? Border.all(color: Colors.yellowAccent, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05), // Subtle shadow
                                blurRadius: 4, // Reduced blur radius
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              colorNumber.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0, // Reduced shadow blur
                                    color: Colors.black.withOpacity(0.2), // Subtle shadow color
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 7,
            minBlastForce: 5,
            maxBlastForce: 7,
            particleDrag: 0.03,
            emissionFrequency: 0.2,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (coins < 50) {
            _showSnackbar(context, "Not enough coins to use hint.");
          } else {
            bool resetOccurred = puzzle.getHint();
            if (resetOccurred) {
              _showSnackbar(context, "You made a mistake and have been reset to the last correct state.");
            } else {
              Future.delayed(Duration(milliseconds: 500), () {
                puzzle.clearHint();
              });
            }
          }
        },
        backgroundColor: Colors.purpleAccent,
        child: Icon(Icons.lightbulb_outline, color: Colors.white),
        tooltip: 'Get Hint',
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildTargetColorBox(Color targetColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: targetColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05), // Very subtle shadow
            blurRadius: 3, // Reduced blur radius
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Target',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
