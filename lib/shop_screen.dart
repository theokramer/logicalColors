import 'package:color_puzzle/hints_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'custom_info_button.dart'; // Dein CustomInfoButton
import 'coin_manager.dart'; // Dein CoinManager

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  void addCoins(int amount) async {
    await context
        .read<CoinProvider>()
        .addCoins(amount); // Verwende den Provider
  }

  void addHints(int amount) async {
    await context
        .read<HintsProvider>()
        .addHints(amount); // Verwende den Provider
  }

  void addRems(int amount) async {
    await context.read<RemsProvider>().addRems(amount); // Verwende den Provider
  }

  void subtractCoins(int amount) async {
    await context
        .read<CoinProvider>()
        .subtractCoins(amount); // Verwende den Provider
  }

  void buy(Map<String, dynamic> item) async {
    int type = item['type'] as int;
    int value = int.parse(item['title'] as String);
    int costs = 0;
    if (item['price'] == "Gratis" || type == 2) {
      costs = 0;
    } else {
      costs = int.parse(item['price'] as String);
    }

    if (type == 2) {
      addCoins(value);
    }
    if (type == 0 && await CoinManager.loadCoins() > costs) {
      addHints(value);
      subtractCoins(costs);
    }
    if (type == 1 && await CoinManager.loadCoins() > costs) {
      addRems(value);
      subtractCoins(costs);
    }
  }

  Future<void> handleBuyHint() async {
    if (context.read<CoinProvider>().coins >= 200) {
      await context.read<CoinProvider>().subtractCoins(200);
      setState(() {
        // Hier sollten eventuell weitere Änderungen am Zustand vorgenommen werden
      });
    } else {
      // Nicht genügend Coins
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => context.read<CoinProvider>().loadCoins());

    return Scaffold(
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Shop',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          SizedBox(
            height: 65,
            width: 100,
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 0,
                  child: Consumer<CoinProvider>(
                    builder: (context, coinProvider, child) {
                      return CustomInfoButton(
                        value:
                            '${coinProvider.coins}', // Verwende die Coins aus dem Provider
                        targetColor: -1,
                        movesLeft: -1,
                        iconPath: 'images/coins.png',
                        backgroundColor: Colors.blueGrey[400]!,
                        textColor: Colors.white,
                        isLarge: 2,
                        originShop: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: Colors.indigo[800],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildEnhancedBundleSection(),
            const SizedBox(height: 20),
            _buildNoAdsBundleSection(),
            const SizedBox(height: 20),
            Expanded(child: _buildShopItemsGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBundleSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.ads_click,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entfernt Vollbildwerbung. Werbungen für Belohnungen sind weiterhin verfügbar.',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Image.asset(
                    "images/coins.png",
                    height: 35,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "10000",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Column(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 35,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "20",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Column(
                children: [
                  Icon(Icons.colorize, size: 35, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "20",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 4.0,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('"Keine Werbung"-Bundle'),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        // Funktionalität zum Aktivieren des Bundles
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: const Text(
                        'EUR 2.99',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleItem(String iconPath, String quantity) {
    return Column(
      children: [
        Image.asset(
          iconPath,
          height: 30,
        ),
        const SizedBox(height: 8),
        Text(
          quantity,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildShopItemsGrid() {
    final items = [
      //{'title': '1', 'price': 'Gratis!', 'type': 0},
      {'title': '3', 'price': '200', 'type': 0},
      {'title': '5', 'price': '200', 'type': 1},
      {'title': '200', 'price': 'Werbung', 'type': 2},
      {'title': '2000', 'price': '0.99€', 'type': 2},
      {'title': '5000', 'price': '1.99€', 'type': 2},
      {'title': '10000', 'price': '2.99€', 'type': 2},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
            onTap: () {
              buy(item); // Rufe die Kauf-Funktion mit dem Artikel auf
            },
            child: _buildShopItemCard(item['title'] as String,
                item['price'] as String, item['type'] as int));
      },
    );
  }

  Widget _buildShopItemCard(String title, String price, int type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo[600],
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            type == 0
                ? const Icon(
                    Icons.lightbulb,
                    size: 40,
                    color: Colors.white,
                  )
                : type == 1
                    ? const Icon(
                        Icons.colorize,
                        size: 40,
                        color: Colors.white,
                      )
                    : Image.asset("images/coins.png", height: 40),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[300],
                  ),
                  textAlign: TextAlign.center,
                ),
                (type == 0 || type == 1) && price != 'Gratis!'
                    ? const SizedBox(
                        width: 8,
                      )
                    : const SizedBox(),
                (type == 0 || type == 1) && price != 'Gratis!'
                    ? Image.asset("images/coins.png", height: 15)
                    : const SizedBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAdsBundleSection() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.purple[700],
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keine Werbung',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Entfernt Vollbildwerbung. Werbungen für\nBelohnungen sind weiterhin verfügbar.',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Funktionalität zum Aktivieren des Bundles
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
            ),
            child: const Text(
              'EUR 0.99',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
