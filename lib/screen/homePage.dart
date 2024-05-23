import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:qtrade_app/screen/s&p500TradingPage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../widgets/customBottomNavigationBar.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference guidesCollection =
      FirebaseFirestore.instance.collection('investment_guides');

  Map<String, double> currentPrices = {};
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    fetchCurrentPrices();
  }

  Future<void> fetchCurrentPrices() async {
    // Fetch the current prices for the stocks in the portfolio
    DocumentSnapshot userSnapshot = await firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    var holdings = userSnapshot['holding_shares'] as List<dynamic>? ?? [];

    for (var holding in holdings) {
      String ticker = holding['hs_tickerSymbol'];
      double currentPrice = await getCurrentMarketPrice(ticker);
      setState(() {
        currentPrices[ticker] = currentPrice;
      });
    }

    setState(() {
      isLoading = false; // Update the loading state
    });
  }

  Future<double> getCurrentMarketPrice(String tickerSymbol) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/detailed_stock_info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticker': tickerSymbol}),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return double.tryParse(data['currentClose'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStockData() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/stocks_info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tickers': ['GOOG', 'AAPL', 'AMZN']
      }), // Example tickers
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((stock) => {
                'ticker': stock['ticker'],
                'companyName': stock['companyName'],
                'currentPrice': stock['currentPrice'],
                'changePercent': stock['changePercent'],
              })
          .toList();
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user found. Please login.',
            style: GoogleFonts.robotoCondensed(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 188, 208, 225),
              Color.fromARGB(255, 168, 185, 229)
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: FutureBuilder<DocumentSnapshot>(
            future: firestore.collection('users').doc(user.uid).get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Something went wrong"));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("User not found."));
              }

              Map<String, dynamic> userData =
                  snapshot.data!.data() as Map<String, dynamic>;
              String fullName = userData['fullName'] ?? 'User';
              double assetPortfolio =
                  (userData['assetPortfolio'] as num).toDouble();

              // Calculate total buy-in and current value
              double totalBuyInValue = 0;
              double totalCurrentValue = 0;

              for (var holding in userData['holding_shares']) {
                double buyInPrice = holding['hs_buyInPrice'] != null
                    ? double.parse(holding['hs_buyInPrice'].toString())
                    : 0.0;
                double quantity = holding['hs_quantity'] != null
                    ? double.parse(holding['hs_quantity'].toString())
                    : 0.0;
                double currentPrice =
                    currentPrices[holding['hs_tickerSymbol']] != null
                        ? currentPrices[holding['hs_tickerSymbol']]!
                        : 0.0;

                totalBuyInValue += buyInPrice * quantity;
                totalCurrentValue += currentPrice * quantity;
              }

              double changePercentage = 0;
              if (totalBuyInValue != 0) {
                changePercentage =
                    ((totalCurrentValue - totalBuyInValue) / totalBuyInValue) *
                        100;
              }

              IconData indicatorIcon;
              Color indicatorColor;

              if (changePercentage > 0) {
                indicatorIcon = Icons.arrow_upward;
                indicatorColor = Colors.green;
              } else if (changePercentage < 0) {
                indicatorIcon = Icons.arrow_downward;
                indicatorColor = Colors.red;
              } else {
                indicatorIcon = Icons.horizontal_rule;
                indicatorColor = Colors.grey;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Welcome, $fullName.',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Color(0xFFeeeef7), // Match the screenshot color
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Your total asset portfolio',
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 18,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '\$${assetPortfolio.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                if (isLoading)
                                  SpinKitThreeBounce(
                                    color: Color.fromARGB(255, 168, 138, 245),
                                    size: 20.0,
                                  )
                                else ...[
                                  Icon(indicatorIcon, color: indicatorColor),
                                  Text(
                                    '${changePercentage.toStringAsFixed(2)}%',
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 18,
                                      color: indicatorColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SP500TradingPage())),
                              child: Text('Invest now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0xFF0D0828), // Background color
                                foregroundColor: Colors.white, // Text color
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Stocks',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchStockData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text("Something went wrong");
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text("No Stock Data Found");
                            }

                            return Column(
                              children: snapshot.data!.map((stock) {
                                return StockTile(
                                  stockName: stock['companyName'],
                                  stockPrice:
                                      '\$${stock['currentPrice'].toStringAsFixed(2)}',
                                  priceChange:
                                      '${stock['changePercent'].toStringAsFixed(2)}%',
                                  iconColor: stock['changePercent'] >= 0
                                      ? Colors.green
                                      : Colors.red,
                                );
                              }).toList(),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SP500TradingPage()),
                              );
                            },
                            child: Text(
                              'See All',
                              style: GoogleFonts.robotoCondensed(
                                color: Color(
                                    0xFF0D0828), // Adjust to match the screenshot
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Investment Guide',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: guidesCollection.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text("Something went wrong");
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Text("No Investment Guides Found");
                            }

                            // Randomize and get three documents
                            var allGuides = snapshot.data!.docs;
                            allGuides.shuffle(Random());
                            var randomGuides = allGuides.take(3).toList();

                            return Column(
                              children: randomGuides.map((doc) {
                                var guideData =
                                    doc.data() as Map<String, dynamic>;
                                return InvestmentGuideItem(
                                  title: guideData['title'],
                                  content: guideData['content'],
                                );
                              }).toList(),
                            );
                          },
                        ), // ... More content
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation bar tap
        },
      ),
    );
  }
}

class StockTile extends StatelessWidget {
  final String stockName;
  final String stockPrice;
  final String priceChange;
  final Color iconColor;

  StockTile({
    required this.stockName,
    required this.stockPrice,
    required this.priceChange,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withOpacity(0.2),
        ),
        child: Icon(Icons.show_chart, color: iconColor),
      ),
      title: Text(
        stockName,
        style: GoogleFonts.robotoCondensed(),
      ),
      subtitle: Text(
        priceChange,
        style: GoogleFonts.robotoCondensed(color: iconColor),
      ),
      trailing: Text(
        stockPrice,
        style: GoogleFonts.robotoCondensed(fontSize: 16),
      ),
    );
  }
}

class InvestmentGuideItem extends StatelessWidget {
  final String title;
  final String content;

  const InvestmentGuideItem({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.robotoCondensed(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              content,
              style: GoogleFonts.robotoCondensed(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
