import 'dart:ffi';
import 'dart:math';

import 'package:color_puzzle/action_Button.dart';
import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/custom_info_button.dart';
import 'package:color_puzzle/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'roadmap_screen.dart';
import 'shop_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'dart:async';


int selectedLevel = 1;
int aHints = 1;
int aRems = 2;
bool tutorialActive = true;
enum TutorialStep { none, step1, step2, completed }

TutorialStep currentTutorialStep = TutorialStep.step1;
 
class PuzzleScreen extends StatefulWidget {


  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool showBanner = false;
  bool showCoinAnimation = false;
  bool animationStarted = false;
  bool denyClick = true;
  double pi = 3.1415926535897932;
  bool isRemoveTileMode = false;
  final Random _random = Random();
  bool showStartBanner = true;
  int getsLightBulb = 0;
  

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(Duration(seconds: 2), () {
      setState(() {
        showStartBanner = false;
        denyClick = false;
      });
    });
      //_showLevelStartInfo();
    });
  }

    Future<void> handleBuyHint() async {
    if (await CoinManager.loadCoins() >= 200) {

        await CoinManager.subtractCoins(200);
        setState(() {
            aHints += 5;
        });
        
        

    } else {
    }
    Navigator.pop(context);
  }

      Future<void> handleBuyRem() async {
    if (await CoinManager.loadCoins() >= 200) {
      await CoinManager.subtractCoins(200);
      setState(() {
        aRems += 5;
        
      });
    } else {
      // Handle not enough coins
    }
    Navigator.pop(context);
  }

  void handleWatchAdForHints() {
    // Implement your ad logic here
    setState(() {
      aHints += 5;
    });
  }

    void handleWatchAdForRems() {
    // Implement your ad logic here
    setState(() {
      aRems += 5;
    });
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
    Future.microtask(() => context.read<CoinProvider>().loadCoins());

    return Scaffold(
      backgroundColor: Colors.blue[50], // Playful background color

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
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                              FadePageRoute(
                                page: ChangeNotifierProvider.value(
                                  value: puzzle,
                                  child: ShopScreen(),
                                ),
                              ),
                            );
                      },
                      child: Container(
                        height: 65,
                        width: 150,
                        child: Stack(
                          children: [
                            Positioned(
                                      top: 16,
                                      left: 16,
                                      child: Consumer<CoinProvider>(
              builder: (context, coinProvider, child) {
                return CustomInfoButton(
                  value: '${coinProvider.coins}', // Verwende die Coins aus dem Provider
                  targetColor: -1,
                  movesLeft: -1,
                  iconPath: 'images/coins.png',
                  backgroundColor: Colors.blueGrey[400]!,
                  textColor: Colors.white,
                );
              },
            ),
                                    ),
                          ],
                        ),
                      ),
                    ),
                    Consumer<CoinProvider>(
                      builder: (context, coinProvider, child) {
                        return PopupMenuButton<String>(
                          offset: Offset(-10, 50),
                          enabled: !denyClick,
                          icon: Icon(Icons.settings, color: Colors.grey),
                          onSelected: 
                          (String value) {
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
                                  FadePageRoute(
                                    page: ChangeNotifierProvider.value(
                                      value: puzzle,
                                      child: ShopScreen(),
                                    ),
                                  ),
                                );
                                break;
                              case 'refresh':
                                if (coinProvider.coins >= 10 || worlds[currentWorld-1].maxLevel > selectedLevel) {
                              if(worlds[currentWorld-1].maxLevel <= selectedLevel) {
                                coinProvider.subtractCoins(10);
                              }
                              puzzle.refreshGrid(puzzle.maxMoves, puzzle.size);
                            } else {
                              //_showSnackbar(context, "Not enough coins to use Refresh.");
                              return;
                            }
                                break;
                              case 'next':
                                if (coinProvider.coins >= 100 || worlds[currentWorld-1].maxLevel > selectedLevel){
                                  if(worlds[currentWorld-1].maxLevel <= selectedLevel) {
                                    coinProvider.subtractCoins(100);
                                  }
                            //Watch Ad, when following level isn't unlocked
                                    
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
                          itemBuilder:  (BuildContext context) => <PopupMenuEntry<String>>[
                            _buildPopupMenuItem('home', 'Home', Icons.home, Colors.indigo),
                            _buildPopupMenuItem('shop', 'Shop', Icons.shopping_cart, Colors.indigo),
                            _buildPopupMenuItem('refresh', 'New Level ${worlds[currentWorld-1].maxLevel <= selectedLevel ? '– 10 Coins' : ""}', Icons.refresh, Colors.indigo),
                            _buildPopupMenuItem('next', 'Skip Level ${worlds[currentWorld-1].maxLevel <= selectedLevel ? '– 100 Coins' : ""}', Icons.skip_next, Colors.indigo),
                          ] ,
                        );
                      }
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
              Container(
                height: 100,
                child: Stack(
                  children: [
                    Positioned(
                              top: 40, // Adjust depending on level position
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
                              //_showSnackbar(context, "Tile removed.");
                              setState(() {
                                isRemoveTileMode = false; // Exit remove mode after removing a tile
                              });
                            } else {
                                puzzle.clickTile(x, y, false, false);
                            }


                          if (puzzle.isGridFilledWithTargetColor()) {
                            denyClick = true;
                            if(worlds[currentWorld].maxLevel >= selectedLevel) {
                              getsLightBulb = -1;
                            } else {
                                getsLightBulb = _random.nextInt(15) + 1;
                            }

                            _confettiController.play();
                            HapticFeedback.heavyImpact();
                            _animationController.forward().then((_) {
                              Future.delayed(Duration(milliseconds: tutorialActive ? 600 : 300), () {
                                _animationController.reverse().then((_) {
                                  Future.delayed(Duration(milliseconds: tutorialActive ? 1000 : 500), () {
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
                          duration: Duration(milliseconds: 400),
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
              tutorialActive ? CustomOverlay(message: currentTutorialStep == TutorialStep.step1 ? 'Click on the tile to change its color' : currentTutorialStep == TutorialStep.step2 ? 'When clicking on a tile, you also change the color of its neighbours' : "Fill the Grid with the Color indicated!", onClose: () {},) : SizedBox(),
            ],
          ),

          Column(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomActionButton(
            icon: Icons.lightbulb,
            onPressed: () async {
                  if (aHints > 0) {
            bool hintUsed =await puzzle.getHint();
            if (hintUsed) {
              // Your hint used logic here
            } else {
              Future.delayed(Duration(milliseconds: 500), () {
                puzzle.clearHint();
              });
            }
          } else {
            showGadgetPopup(
                context,
                'Hinweise',
                handleBuyHint,
                handleWatchAdForHints,
                [Colors.amber, Colors.orange]
              );
          }
              
              
            },
            count: aHints, // Number of hints available
            gradientColors: [Colors.amber, Colors.orange],
            iconColor: Colors.white,
          ),
          CustomActionButton(
            icon: Icons.colorize,
            onPressed: () {
              if(!denyClick) {
                
            if (aRems > 0) {
              setState(() {
              aRems -= 1;
              isRemoveTileMode = true;
              });
            } else {
              showGadgetPopup(
                context,
                'Colorizer',
                handleBuyRem,
                handleWatchAdForRems,
                [Color.fromARGB(255, 176, 2, 124), Color.fromARGB(255, 255, 0, 81)]
              );
            }
            
          
              }
            },
            count: aRems, // Number of removes available
            gradientColors: [Color.fromARGB(255, 176, 2, 124), Color.fromARGB(255, 255, 0, 81)],
            iconColor: Colors.white,
          ),
          CustomActionButton(
            icon: Icons.undo,
            onPressed: () {
              if(!denyClick) {
                puzzle.undoMove();
              }
            },
            count: -1, // Infinite undo available
            gradientColors: [Color.fromARGB(255, 255, 68, 0), Colors.orangeAccent],
            
            iconColor: Colors.white,
          ),
          CustomActionButton(
            icon: Icons.refresh,
            onPressed: () {
              if(!denyClick) {
                puzzle.grid = puzzle.savedGrid.map((row) => List<int>.from(row)).toList();
              puzzle.resetMoves();
              puzzle.moveWhereError = -1;
              puzzle.clicks = puzzle.savedClicks.map((click) => List<int>.from(click)).toList();
              puzzle.undoStack.clear();
              }
            },
            count: -1, // Infinite refresh available
            gradientColors: [Color.fromARGB(255, 63, 3, 165), Colors.deepPurpleAccent],
            iconColor: Colors.white,
          ),
        ],
      ),
    ),
  ],
),


          
if (showBanner && !animationStarted)
  Positioned.fill(
    child: Stack(
      children: [
        // Background overlay with a subtle dark tint
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main banner with rounded corners and light shadow
                GestureDetector(
                  onTap: () {
                    // Button action
                          if (!animationStarted) {
                            setState(() {
                              animationStarted = true;
                              showCoinAnimation = true;
                              if (selectedLevel < 100) {
                                puzzle.updateWorldLevel(currentWorld, selectedLevel + 1);
                                selectedLevel += 1;
                                denyClick = false;
                              }
                              if (selectedLevel >= 69 && worlds[currentWorld + 1].maxLevel == 0) {
                                puzzle.updateWorldLevel(currentWorld + 1, 1);
                              }
                            });

                            // Delay navigation to ensure coin animation completes
                            Future.delayed(Duration(milliseconds: 800), () {
                              puzzle.addCoins(puzzle.coinsEarned);
                              if(getsLightBulb == 1) {
                                setState(() {
                                  aHints += 1;
                                });
                              }
                              if(getsLightBulb == 2) {
                                setState(() {
                                  aRems += 1;
                                });
                              }
                              denyClick = false;

                              Navigator.of(context).pushReplacement(
                                FadePageRoute(
                                  page: ChangeNotifierProvider(
                                    create: (_) => PuzzleModel(
                                      size: puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2,
                                      level: puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
                                      colorMapping: {
                                        1: worlds[currentWorld - 1].colors[0],
                                        2: worlds[currentWorld - 1].colors[1],
                                        3: worlds[currentWorld - 1].colors[2],
                                      },
                                    ),
                                    child: selectedLevel < 100 ? PuzzleScreen() : RoadMapScreen(),
                                  ),
                                ),
                              );
                            });
                          }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title text
                        Text(
                          'Level Complete!',
                          style: TextStyle(
                            color: Colors.blueGrey[800],
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                        SizedBox(height: 15),
                        // Coin display or animation
                        Row(mainAxisAlignment: getsLightBulb == 1 || getsLightBulb == 2 ?MainAxisAlignment.spaceAround : MainAxisAlignment.center,
                          children: [
                          animationStarted
                            ? SizedBox(height: 100)
                            : _buildCoinDisplay(puzzle.coinsEarned),
                            getsLightBulb == 1 || getsLightBulb == 2 ? Row( children: [(Icon(getsLightBulb == 1 ? Icons.lightbulb : Icons.colorize, color: Colors.amber, size: 80) ), SizedBox(width: 30),
          Text(
            '1',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),]): SizedBox(),
                        ],),
                          
                        SizedBox(height: 20),
                        // Continue button
                        GestureDetector(
                          onTap: () {
                            
                            if (!animationStarted) {
                            setState(() {
                              animationStarted = true;
                              showCoinAnimation = true;
                              if (selectedLevel < 100) {
                                puzzle.updateWorldLevel(currentWorld, selectedLevel + 1);
                                selectedLevel += 1;
                                denyClick = false;
                              }
                              if (selectedLevel >= 69 && worlds[currentWorld + 1].maxLevel == 0) {
                                puzzle.updateWorldLevel(currentWorld + 1, 1);
                              }
                            });

                            // Delay navigation to ensure coin animation completes
                            Future.delayed(Duration(milliseconds: 800), () {
                              puzzle.addCoins(puzzle.coinsEarned);
                              switch(currentTutorialStep) {
                              
                              case TutorialStep.none:

                              case TutorialStep.step1:
                                currentTutorialStep = TutorialStep.step2;
                              case TutorialStep.step2:
                                currentTutorialStep = TutorialStep.completed;
                              case TutorialStep.completed:
                                tutorialActive = false;
                            }
                              if(getsLightBulb == 1) {
                                setState(() {
                                  aHints += 1;
                                });
                              }
                              if(getsLightBulb == 2) {
                                setState(() {
                                  aRems += 1;
                                });
                              }
                              denyClick = false;

                              Navigator.of(context).pushReplacement(
                                FadePageRoute(
                                  page: ChangeNotifierProvider(
                                    create: (_) => PuzzleModel(
                                      size: puzzle.getSizeAndMaxMoves(selectedLevel)["size"] ?? 2,
                                      level: puzzle.getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
                                      colorMapping: {
                                        1: worlds[currentWorld - 1].colors[0],
                                        2: worlds[currentWorld - 1].colors[1],
                                        3: worlds[currentWorld - 1].colors[2],
                                      },
                                    ),
                                    child: selectedLevel < 100 ? PuzzleScreen() : RoadMapScreen(),
                                  ),
                                ),
                              );
                            });
                          }
                          },
                          child: Container(height: 60, child: AnimatedText())
                          /*ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Next Level',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ), */
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),

// Confetti effect
if (animationStarted && showCoinAnimation)
  CoinAnimation(
    start: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
    end: Offset(50, 75),
    numberOfCoins: puzzle.coinsEarned,
  ),

ConfettiWidget(
  confettiController: _confettiController,
  blastDirectionality: BlastDirectionality.explosive, // Adjusts the direction
  minBlastForce: 5,
  maxBlastForce: 20,
  emissionFrequency: 0.3,
  numberOfParticles: 15,
  gravity: 0.1,
  colors: [Colors.lightBlueAccent, Colors.lightGreen, Colors.pinkAccent, Colors.yellow],
),

        if (showStartBanner)
            Center(
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                contentPadding: EdgeInsets.all(20),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level ${selectedLevel}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomInfoButton(
                          value: '', // No value needed here
                          targetColor: puzzle.targetColorNumber, // Target color
                          movesLeft: -1, // No moves left needed here
                          iconPath: '', // No icon needed
                          backgroundColor: Colors.grey[200]!,
                          textColor: Colors.black,
                          isLarge: true, // Increase size
                        ),
                        CustomInfoButton(
                          value: '', // No value needed here
                          targetColor: -1, // No target color needed here
                          movesLeft: puzzle.maxMoves, // Number of moves
                          iconPath: '', // No icon needed
                          backgroundColor: Colors.grey[200]!,
                          textColor: Colors.black,
                          isLarge: true, // Increase size
                        ),
                        CustomInfoButton(
                          value: '${puzzle.size}x${puzzle.size}', // Display grid size
                          targetColor: -1, // No target color needed here
                          movesLeft: -1, // No moves left needed here
                          iconPath: '', // No icon needed
                          backgroundColor: Colors.grey[200]!,
                          textColor: Colors.black,
                          isLarge: true, // Increase size
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLevelStartInfo() {
    final puzzle = Provider.of<PuzzleModel>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level ${selectedLevel}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomInfoButton(
                    value: '', 
                    targetColor: puzzle.targetColorNumber, 
                    movesLeft: -1, 
                    iconPath: '', 
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: true,
                  ),
                  CustomInfoButton(
                    value: '', 
                    targetColor: -1, 
                    movesLeft: puzzle.maxMoves, 
                    iconPath: '', 
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: true,
                  ),
                  CustomInfoButton(
                    value: '${puzzle.size}x${puzzle.size}', 
                    targetColor: -1, 
                    movesLeft: -1, 
                    iconPath: '', 
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.black,
                    isLarge: true,
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

void showGadgetPopup(BuildContext context, String gadgetName, Function onBuyPressed, Function onWatchAdPressed, List<Color> gradientColors) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.blueGrey[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          
          padding: EdgeInsets.all(25),
          height: 400, // Höhe angepasst
          width: MediaQuery.of(context).size.width * 0.75, // Breite angepasst
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mehr $gadgetName erhalten',
                style: TextStyle(
                  color: Colors.white, // Farbe angepasst
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                  fontSize: 22, // Größe angepasst
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    gadgetName == "Colorizer" ? Icons.colorize : Icons.lightbulb,
                    size: 60, // Größe des Icons
                    color: gradientColors.first, // Farbe des Icons
                  ),
                  SizedBox(width: 25,),
              Text(
                'x6', // Anzahl der Aktionen
                style: TextStyle(
                  color: gradientColors.first,
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

                ],
              ),
              
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      onWatchAdPressed();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.play_circle_fill),
                    label: Text(
                      'Werbung',
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: gradientColors.first, // Farbe angepasst
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15,),
                  Consumer<CoinProvider>(
                    builder: (context, coinProvider, child)  {
                      return ElevatedButton.icon(
                        onPressed: () {
                          coinProvider.coins >= 200 ? onBuyPressed() : Navigator.of(context).popAndPushNamed("/shop");
                        },
                        icon: Icon(Icons.monetization_on),
                        label: Text(
                          '200 Coins',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: gradientColors.first, // Farbe angepasst
                          foregroundColor: Colors.white,
                        ),
                      );
                    }
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget buildTutorialOverlay() {
  switch (currentTutorialStep) {
    case TutorialStep.step1:
      return Center(
        child: AlertDialog(
          title: Text("Step 1: Tap the Tile"),
          content: Text("Tap the tile to change its color."),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  showStartBanner = false;
                  denyClick = false;
                });
              },
              child: Text("Got it!"),
            ),
          ],
        ),
      );
    case TutorialStep.step2:
      return Center(
        child: AlertDialog(
          title: Text("Step 2: Tap the Correct Tile"),
          content: Text("Tap the correct tile to change its color, including neighboring tiles."),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  showStartBanner = false;
                  denyClick = false;
                });
              },
              child: Text("Next"),
            ),
          ],
        ),
      );
    default:
      return SizedBox.shrink();
  }
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
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
        'images/coins.png',
        width: 80,
        height: 80,
      ),
          SizedBox(width: 30),
          Text(
            '$coinsEarned',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
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
      begin: Colors.indigo[300],
      end: Colors.indigo[500],
    ).animate(_controller);

    _sizeAnimation = Tween<double>(
      begin: 25,
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