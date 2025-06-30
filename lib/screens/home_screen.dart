import 'package:flutter/material.dart';
import 'package:trashure/models/colours.dart';
import '../widgets/bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color backgroundColor = AppColour.background;
  final Color navBarColor = AppColour.primaryGreen;

  final List<Map<String, String>> listings = const [
    {
      'title': 'Earpiece',
      'price': '\$2',
      'user': 'John',
      'image': 'images/earpiece.png',
    },
    {
      'title': 'HP Laptop',
      'price': '\$400',
      'user': 'Stacy',
      'image': 'images/laptop.png',
    },
    {
      'title': 'Logitech mouse',
      'price': '\$40',
      'user': 'Steven',
      'image': 'images/mouse.png',
    },
    {
      'title': 'Laptop bag',
      'price': '\$20',
      'user': 'Samuel',
      'image': 'images/laptopbag.png',
    },
    {
      'title': 'Blue Bag',
      'price': '\$1',
      'user': 'Amy',
      'image': 'images/bluebag.png',
    },
    {
      'title': 'iPhone X',
      'price': '\$500',
      'user': 'Jake',
      'image': 'images/phone.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(Icons.search, size: 28),
                    ),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final item = listings[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          item['image']!,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title']!,
                                style: const TextStyle(fontSize: 16)),
                            Text(item['price']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(item['user']!,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
