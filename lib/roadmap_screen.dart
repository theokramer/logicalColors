import 'package:flutter/material.dart';

class RoadMapScreen extends StatelessWidget {
  final int currentLevel;

  RoadMapScreen({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Road Map'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: RoadMapBody(currentLevel: currentLevel),
    );
  }
}

class RoadMapBody extends StatelessWidget {
  final int currentLevel;

  RoadMapBody({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              int level = index + 1;
              bool isUnlocked = level <= currentLevel;
              return LevelBubble(level: level, isUnlocked: isUnlocked);
            },
            childCount: 100,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Current Level: $currentLevel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LevelBubble extends StatelessWidget {
  final int level;
  final bool isUnlocked;

  LevelBubble({required this.level, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          Navigator.of(context).pushNamed('/puzzle', arguments: level);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? Colors.green : Colors.grey,
          border: Border.all(color: Colors.black, width: 2.0),
        ),
        child: Center(
          child: Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
