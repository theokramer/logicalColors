import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'roadmap_screen.dart';
import 'shop_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

class PuzzleScreen extends StatefulWidget {
  int currentLevel;

  PuzzleScreen({required this.currentLevel});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final int _coinsEarned = 30; // Coins earned after level completion
  bool showBanner = false;
  double pi = 3.1415926535897932;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 500));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);

    return Scaffold(
      backgroundColor: Colors.blue[50], // Playful background color
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      icon: Icons.home,
                      color: Colors.orangeAccent,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RoadMapScreen(currentLevel: widget.currentLevel),
                          ),
                        );
                      },
                    ),
                    _buildIconButton(
                      icon: Icons.shopping_cart,
                      color: Colors.orangeAccent,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShopScreen(),
                          ),
                        );
                      },
                    ),
                    _buildIconButton(
                      icon: Icons.diamond,
                      color: Colors.orangeAccent,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShopScreen(),
                          ),
                        );
                      },
                    ),
                    _buildIconButton(
                      icon: Icons.refresh,
                      color: Colors.orangeAccent,
                      onPressed: () {
                        puzzle.grid = puzzle.savedGrid.map((row) => List<int>.from(row)).toList();
                        puzzle.resetMoves();
                        puzzle.moveWhereError = -1;
                        puzzle.clicks = puzzle.savedClicks.map((click) => List<int>.from(click)).toList();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Level ${widget.currentLevel}',
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand',
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            color: Colors.deepPurple[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildTargetColorBox(puzzle.targetColor, puzzle.targetColorNumber),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Moves left',
                          style: TextStyle(
                            color: Colors.deepPurple[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 50,
                          child: Text(
                            (puzzle.maxMoves - puzzle.moves).toString(),
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: puzzle.size,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
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
                              Future.delayed(Duration(milliseconds: 100), () {
                                _animationController.reverse().then((_) {
                                  setState(() {
                                    showBanner = true;
                                  });
                                  
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
                              colors: [tileColor.withOpacity(0.8), tileColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: isHintTile
                                ? Border.all(color: Colors.yellowAccent, width: 4)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              colorNumber.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.3),
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
                      Padding(
          padding: const EdgeInsets.only(bottom: 50, left: 50),
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
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
            ],
          ),
          if (showBanner)
            Container(
              color: Colors.black.withOpacity(0.6), // Dark overlay with opacity
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Level Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildCoinDisplay(_coinsEarned),
                          SizedBox(height: 20),
                          Container(
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                puzzle.addCoins(_coinsEarned);
                                  widget.currentLevel += 1;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChangeNotifierProvider(
                                      create: (_) => PuzzleModel(
                                          size: puzzle.getSizeAndMaxMoves(widget.currentLevel)["size"] ?? 2,
                                          level: puzzle.getSizeAndMaxMoves(widget.currentLevel)["maxMoves"] ?? 2,
                                          ),

                                      child: PuzzleScreen(currentLevel: widget.currentLevel),
                                    ),
                                  ),
                                );
                              },
                              child: AnimatedText(),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 5,
            minBlastForce: 5,
            maxBlastForce: 40,
            emissionFrequency: 1,
            numberOfParticles: 10,
            gravity: 0.15,
            colors: [Colors.pink, Colors.orange, Colors.yellow, Colors.green, Colors.blue],
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
        backgroundColor: Colors.orangeAccent,
        child: Icon(Icons.lightbulb_outline, color: Colors.white),
        tooltip: 'Get Hint',
      ),
    );
  }

  Widget _buildCoinDisplay(int coinsEarned) {
    return Column(
      children: [
        Image.asset(
          'images/coins.png',
          width: 130,
          height: 130,
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/coin.png',
              width: 35,
              height: 35,
            ),
            SizedBox(width: 10),
            Text(
              '$coinsEarned',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required void Function() onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTargetColorBox(Color targetColor, int targetColorNumber) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: targetColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          targetColorNumber.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ));
  }
}

class AnimatedText extends StatefulWidget {
  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.yellow[200],
      end: Colors.yellow[400],
    ).animate(_controller);

    _sizeAnimation = Tween<double>(
      begin: 22,
      end: 28,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          'Tap to claim!',
          style: TextStyle(
            color: _colorAnimation.value,
            fontSize: _sizeAnimation.value,
            fontWeight: FontWeight.bold,
            fontFamily: 'Quicksand',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
