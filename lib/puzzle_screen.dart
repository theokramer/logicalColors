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
  double pi = 3.1415926535897932;
  final int _coinsEarned = 30; // Coins earned after level completion
  bool showBanner = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 300));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
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
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      icon: Icons.home,
                      color: Colors.deepOrangeAccent,
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
                      color: Colors.deepOrangeAccent,
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
                      color: Colors.deepOrangeAccent,
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
                      color: Colors.deepOrangeAccent,
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
                  color: Colors.black26,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Orbitron',
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        _buildTargetColorBox(puzzle.targetColor, puzzle.targetColorNumber),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Moves left',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
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
              SizedBox(height: 50),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: puzzle.size,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
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
                                  puzzle.addCoins(_coinsEarned);
                                  widget.currentLevel += 1;
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
                              colors: [tileColor.withOpacity(0.85), tileColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: isHintTile
                                ? Border.all(color: Colors.yellowAccent, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
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
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.2),
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
                    if (showBanner)
            Container(
              color: Colors.black.withOpacity(0.4), // Dark overlay with opacity
              child: Center(
                child: Text("")
              ),
            ),


          showBanner ? 
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 170.0),
                            child: Container(
                                            color: Colors.deepPurple,
                                            padding: EdgeInsets.symmetric(vertical: 30),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(width: 20),
                                                Text(
                                                  'Level Complete!',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 35,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Orbitron',
                                                  ),
                                                ),
                                                
                                              ],
                                            ),
                                          ),
                          ),
                          SizedBox(height: 30,),
                          _buildCoinDisplay(_coinsEarned),
                          SizedBox(height: 10,),
                          GestureDetector(child: AnimatedText(), onTap: () {
                            Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => PuzzleModel(
                            size: widget.currentLevel < 5 ? 2 : 3,
                            level: widget.currentLevel < 5 ? widget.currentLevel : widget.currentLevel - 3),
                        child: PuzzleScreen(currentLevel: widget.currentLevel,),
                      ),
                    ),
                  );
                          },),
          ],) : Text(""),
                    
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 7,
            minBlastForce: 5,
            maxBlastForce: 10,
            particleDrag: 0.03,
            emissionFrequency: 0.3,
            numberOfParticles: 20,
            gravity: 0.1,
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
        backgroundColor: Colors.deepOrangeAccent,
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
          width: 150,
          height: 150,
        ),
        SizedBox(width: 100),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
          'images/coin.png',
          width: 30,
          height: 30,
        ),
        SizedBox(width: 10,),
            Text(
              '$coinsEarned',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
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
            blurRadius: 6,
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: targetColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          targetColorNumber.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.2),
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
  late Animation<Color?> _animation;
  late Animation<double?> _animation2;

  @override
  void initState() {
    super.initState();
    
    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true); // Repeat animation

    // Define the color animation
    _animation = ColorTween(
      begin: Colors.white54,
      end: Colors.white,
    ).animate(_controller);

        _animation2 = Tween<double>(
      begin: 25,
      end: 26,
    ).animate(_controller);

        // Define the color animation
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          'Tap to claim',
          style: TextStyle(
            color: _animation.value,
            fontSize: _animation2.value,
            fontWeight: FontWeight.w900,
            fontFamily: 'Orbitron',
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