import 'dart:ffi';
import 'dart:math';

import 'package:color_puzzle/action_Button.dart';
import 'package:color_puzzle/custom_info_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'roadmap_screen.dart';
import 'shop_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

int selectedLevel = 1;
int aHints = 3;
int aRems = 5;

class PuzzleScreen extends StatefulWidget {


  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final int _coinsEarned = 10;
  bool showBanner = false;
  bool showCoinAnimation = false;
  bool animationStarted = false;
  bool denyClick = false;
  double pi = 3.1415926535897932;
  bool isRemoveTileMode = false;
  final Random _random = Random();

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
                    Positioned(
          top: 16,
          left: 16,
          child: CustomInfoButton(
            value: '$coins',
            targetColor: -1, // No target color needed here
            movesLeft: -1, // No moves left needed here
            iconPath: 'images/coins.png', // Path to your coin icon
            backgroundColor: Colors.blueGrey[400]!,
            textColor: Colors.white,
          ),
        ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.settings, color: Colors.grey),
                      onSelected: (String value) {
                        switch (value) {
                          case 'home':
                            Navigator.of(context).pushReplacement(
                              FadePageRoute(
                                page: ChangeNotifierProvider.value(
                                  value: puzzle,
                                  child: RoadMapScreen(),
                                ),
                              ),
                            );
                            break;
                          case 'shop':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShopScreen(),
                              ),
                            );
                            break;
                          case 'refresh':
                            if (coins >= 10) {
                          coins -= 10;
                          puzzle.refreshGrid(puzzle.maxMoves, puzzle.size);
                        } else {
                          _showSnackbar(context, "Not enough coins to use Refresh.");
                          return;
                        }
                            break;
                          case 'next':
                            if (coins >= 100){
                              coins -= 100;
                        //Watch Ad, when following level isn't unlocked
                        print(currentWorld);
                        print(selectedLevel);
                                
                                if (selectedLevel >= 69 && worlds[currentWorld+1].maxLevel == 0) {
                                  puzzle.updateWorldLevel(currentWorld + 1, 1);
                                }
                                if (selectedLevel < 100) {
                                  puzzle.updateWorldLevel(currentWorld, selectedLevel + 1);
                                    selectedLevel += 1;
                                      denyClick = false;
                                }
      Navigator.of(context).pushReplacement(
        FadePageRoute(
          page: ChangeNotifierProvider(
            create: (_) => PuzzleModel(
              size: puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2,
              level: puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
              colorMapping: {
    1: worlds[currentWorld - 1].colors[0],
    2: worlds[currentWorld - 1].colors[1] ,
    3: worlds[currentWorld - 1].colors[2],
  }
            ),
            child: selectedLevel < 100 ? PuzzleScreen() : RoadMapScreen(), 
          ),
        ),
      );
                      }
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        _buildPopupMenuItem('home', 'Home', Icons.home, Colors.orangeAccent),
                        _buildPopupMenuItem('shop', 'Shop', Icons.shopping_cart, Colors.orangeAccent),
                        _buildPopupMenuItem('refresh', 'New Level - 10 Coins', Icons.refresh, Colors.orangeAccent),
                        _buildPopupMenuItem('next', 'Skip Level - 100 Coins', Icons.skip_next, Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Level ${selectedLevel}',
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand',
                ),
              ),
              SizedBox(height: 20),
              Positioned(
          top: 64, // Adjust depending on level position
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomInfoButton(
                value: '', // No value needed here
                targetColor: puzzle.targetColorNumber, // Target color
                movesLeft: -1, // No moves left needed here
                iconPath: '', // No icon needed
                backgroundColor: Colors.grey[100]!,
                textColor: Colors.black,
                isLarge: true, // Increase size
              ),
              
              CustomInfoButton(
                value: '', // No value needed here
                targetColor: -1, // No target color needed here
                movesLeft: (puzzle.maxMoves - puzzle.moves), // Number of moves left
                iconPath: '', // No icon needed
                backgroundColor: Colors.grey[100]!,
                textColor: Colors.black,
                isLarge: true, // Increase size
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
                          if (!animationStarted && !showBanner && !denyClick) {

if (isRemoveTileMode) {
                              // Remove the tile
                              puzzle.clickTile(x, y, false, true);
                              _showSnackbar(context, "Tile removed.");
                              setState(() {
                                isRemoveTileMode = false; // Exit remove mode after removing a tile
                              });
                            } else {
                                puzzle.clickTile(x, y, false, false);
                            }


                          if (puzzle.isGridFilledWithTargetColor()) {
                            denyClick = true;
                            _confettiController.play();
                            HapticFeedback.heavyImpact();
                            _animationController.forward().then((_) {
                              Future.delayed(Duration(milliseconds: 300), () {
                                _animationController.reverse().then((_) {
                                  Future.delayed(Duration(milliseconds: 500), () {
                                  setState(() {
                                    showBanner = true;
                                  });});
                                });
                              });
                            });
                            
                          } else {
                            HapticFeedback.selectionClick();
                          }
                          }
                          
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
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
            ],
          ),

          Positioned(
  bottom: 32,
  left: 16,
  right: 16,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CustomActionButton(
        icon: Icons.help_outline,
        onPressed: () {
          if(aHints > 0) {
            bool hintUsed = puzzle.getHint();
              if (hintUsed) {
                _showSnackbar(context, "You made a mistake and have been reset to the last correct state.");
              } else {
                Future.delayed(Duration(milliseconds: 500), () {
                  puzzle.clearHint();
                });
              }
          } else {
            if (coins < 50) {
                _showSnackbar(context, "Not enough coins to use Hint.");
                return;
              } else {
                bool hintUsed = puzzle.getHint();
              if (hintUsed) {
                _showSnackbar(context, "You made a mistake and have been reset to the last correct state.");
              } else {
                Future.delayed(Duration(milliseconds: 500), () {
                  puzzle.clearHint();
                });
              }
              }
          }
            
              
              
        },
        count: aHints, // Number of hints available
        gradientColors: [Colors.green, Colors.greenAccent],
        iconColor: Colors.white,
        badgeColor: const Color.fromARGB(255, 40, 27, 27),
      ),
      
      CustomActionButton(
        icon: Icons.remove_circle_outline,
        onPressed: () {
          setState(() {
            if (aRems > 0) {
              aRems -= 1;

            } else {
              coins -= 30;
            }
                 isRemoveTileMode = true;     
                    });
        },
        count: aRems, // Number of removes available
        gradientColors: [Color.fromARGB(255, 255, 68, 0), Colors.orangeAccent],
        iconColor: Colors.white,
        badgeColor: const Color.fromARGB(255, 40, 27, 27),
      ),
      CustomActionButton(
        icon: Icons.undo,
        onPressed: () {
          // Your logic here

              puzzle.undoMove();
              
            
         
        },
        count: -1, // Number of swaps available
        gradientColors: [Color.fromARGB(255, 176, 2, 124), Color.fromARGB(255, 255, 0, 81)],
        iconColor: Colors.white,
        badgeColor: const Color.fromARGB(255, 40, 27, 27),
      ),
            CustomActionButton(
        icon: Icons.refresh,
        onPressed: () {
          puzzle.grid = puzzle.savedGrid.map((row) => List<int>.from(row)).toList();
                        puzzle.resetMoves();
                        puzzle.moveWhereError = -1;
                        puzzle.clicks = puzzle.savedClicks.map((click) => List<int>.from(click)).toList();
                        puzzle.undoStack.clear();
        },
        count: -1, // Number of refreshes available
        gradientColors: [Color.fromARGB(255, 63, 3, 165), Colors.deepPurpleAccent],
        iconColor: Colors.white,
        badgeColor: const Color.fromARGB(255, 40, 27, 27),
      ),
    ],
  ),
),



          
          if (showBanner && !animationStarted)
  Positioned.fill(
    child: Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.6),
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
                      animationStarted ? Container(height: 200,) :
                      _buildCoinDisplay(_coinsEarned),
                      SizedBox(height: 20),
                      GestureDetector(
  onTap: () {
    if (animationStarted) {

    } else {
      setState(() {
        
      animationStarted = true;
      showCoinAnimation = true;
      if (selectedLevel < 100) {
        puzzle.updateWorldLevel(currentWorld, selectedLevel + 1);
                                    selectedLevel += 1;
                                      denyClick = false;
                                }

      if (selectedLevel >= 69 && worlds[currentWorld+1].maxLevel == 0) {
                                  puzzle.updateWorldLevel(currentWorld + 1, 1);
                                }
      
    });

    // Delay navigation to ensure the coin animation completes
    Future.delayed(Duration(milliseconds: 800), () {
      puzzle.addCoins(_coinsEarned);
      denyClick = false;
      
      print(puzzle.getSizeAndMaxMoves(selectedLevel));
      Navigator.of(context).pushReplacement(
        FadePageRoute(
          page: ChangeNotifierProvider(
            create: (_) => PuzzleModel(
              size: puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2,
              level: puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
              colorMapping: {
    1: worlds[currentWorld - 1].colors[0],
    2: worlds[currentWorld - 1].colors[1] ,
    3: worlds[currentWorld - 1].colors[2],
  }
            ),
            child: selectedLevel < 100 ? PuzzleScreen() : RoadMapScreen(), 
          ),
        ),
      );
    });
    }
    
  },
  child: animationStarted ? Text("") : AnimatedText(),
)

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
if (animationStarted && showCoinAnimation)
  CoinAnimation(
    start: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
    end: Offset(50, 75),
    numberOfCoins: _coinsEarned,
  ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 5,
            minBlastForce: _random.nextInt(7) + 2,
            maxBlastForce: _random.nextInt(30) + 10,
            emissionFrequency: 1,
            numberOfParticles: _random.nextInt(15) + 5,
            gravity: 0.15,
            colors: [Colors.pink, Colors.orange, Colors.yellow, Colors.green, Colors.blue],
          ),
        
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildPopupMenuItem(String value, String text, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildCoinDisplay(int coinsEarned) {
    return Container(
      height: 200,
      child: Column(
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
      ),
    );
  }

   Widget _buildActionIconButton({required IconData icon, required Color color, required void Function() onPressed, required int count}) {
  return Column(
    children: [
      Container(
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
      ),
      SizedBox(height: 4),
      Text(
        count.toString(),
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}



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
      duration: const Duration(milliseconds: 700),
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
          'Tap to claim',
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


class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var opacityAnimation = animation.drive(tween);
            return FadeTransition(opacity: opacityAnimation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500), // Dauer der Animation
        );
}



class CoinAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final int numberOfCoins;

  CoinAnimation({
    required this.start,
    required this.end,
    required this.numberOfCoins,
  });

  @override
  _CoinAnimationState createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _positionAnimation;
  late List<Widget> _coins;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500), // Duration for the entire animation
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _coins = List.generate(
      widget.numberOfCoins,
      (index) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double scale = _scaleAnimation.value;
          final double progress = _positionAnimation.value;
          final double dx = widget.start.dx + progress * (widget.end.dx - widget.start.dx);
          final double dy = widget.start.dy + progress * (widget.end.dy - widget.start.dy);

          return Positioned(
            left: dx - (12 * scale), // Center the coin correctly based on scale
            top: dy - (12 * scale), // Center the coin correctly based on scale
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'images/coins.png',
                width: 24,
                height: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: _coins,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}