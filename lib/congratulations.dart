import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'puzzle_screen.dart';

class CongratulationsScreen extends StatefulWidget {
  final int currentLevel;

  CongratulationsScreen({required this.currentLevel});

  @override
  _CongratulationsScreenState createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen>
    with SingleTickerProviderStateMixin {
  late int _nextLevel;
  late AnimationController _controller;
  late Animation<double> _animation;
  final int _coinsEarned = 30;

  @override
  void initState() {
    super.initState();
    _nextLevel = widget.currentLevel;
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Congratulations!',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Center(
                  child: Text(
                    'You completed level ${widget.currentLevel - 1}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0, // Reduced shadow blur
                          color: Colors.black.withOpacity(0.2), // Subtle shadow color
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 40),
              _buildCoinDisplay(),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => PuzzleModel(
                            size: _nextLevel < 5 ? 2 : 3,
                            level: _nextLevel < 5 ? _nextLevel : _nextLevel - 3),
                        child: PuzzleScreen(),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Start Next Game',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'images/coins.png', // Replace with your coin image path
          width: 40,
          height: 40,
        ),
        SizedBox(width: 10),
        Text(
          '+$_coinsEarned Coins',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 2.0, // Reduced shadow blur
                color: Colors.black.withOpacity(0.2), // Subtle shadow color
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
