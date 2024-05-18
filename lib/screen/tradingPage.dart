import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:qtrade_app/screen/s&p500TradingPage.dart';
import '../widgets/customBottomNavigationBar.dart';
import 'package:http/http.dart' as http;

class TradingPage extends StatefulWidget {
  @override
  _TradingPageState createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, double> portfolioDistribution = {};
  bool isPositionsSelected = true; // Toggle state

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    checkAndExecuteTransactions(context);
    fetchPortfolioDistribution();
  }

  bool isUSEquityMarketOpen() {
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    var now = tz.TZDateTime.now(tz.local);
    var marketOpen =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 30);
    var marketClose =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 16, 0);

    return now.weekday <= 5 &&
        now.isAfter(marketOpen) &&
        now.isBefore(marketClose);
  }

  Future<double> getCurrentMarketPrice(String tickerSymbol) async {
    final url = Uri.parse('http://10.0.2.2:5000/detailed_stock_info');
    final response = await http.post(url,
        body: jsonEncode({'ticker': tickerSymbol}),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return double.tryParse(data['currentClose'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  Future<void> checkAndExecuteTransactions(BuildContext context) async {
    print("jj");
    print(isUSEquityMarketOpen());
    // if (!isUSEquityMarketOpen()) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text("Market is not open")));
    //   return;
    // }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    var userData = await userRef.get();
    var transactionRefs =
        userData.data()?['paperTrading_transactionID'] as List<dynamic>? ?? [];

    for (var transactionRef in transactionRefs) {
      DocumentReference transRef = transactionRef is String
          ? FirebaseFirestore.instance
              .collection('paper_trading_transaction')
              .doc(transactionRef)
          : transactionRef as DocumentReference;

      var transaction = await transRef.get();
      if (transaction.exists && transaction['pt_orderStatus'] == 'pending') {
        double currentPrice =
            await getCurrentMarketPrice(transaction['pt_stockSymbol']);

        if (transaction['pt_transactionType'] == 'buy') {
          bool shouldExecute = transaction['pt_orderType'] == 'Market Order' ||
              (transaction['pt_orderType'] == 'LMT Order' &&
                  currentPrice <= transaction['pt_pricePerShare']);

          if (shouldExecute) {
            await executeBuyTransaction(
                transRef,
                transaction.data() as Map<String, dynamic>,
                userRef,
                currentPrice);
          }
        } else if (transaction['pt_transactionType'] == 'sell') {
          bool shouldExecute = transaction['pt_orderType'] == 'Market Order' ||
              (transaction['pt_orderType'] == 'LMT Order' &&
                  currentPrice >= transaction['pt_pricePerShare']);

          if (shouldExecute) {
            await executeSellTransaction(
                transRef,
                transaction.data() as Map<String, dynamic>,
                userRef,
                currentPrice);
          }
        }
      }
    }
  }

  Future<void> executeBuyTransaction(
      DocumentReference transactionRef,
      Map<String, dynamic> transaction,
      DocumentReference userRef,
      double executedPrice) async {
    // Convert quantity to double
    double quantity = (transaction['pt_quantity'] as num).toDouble();
    double totalCost = executedPrice * quantity;

    await transactionRef.update(
        {'pt_orderStatus': 'executed', 'pt_executedPrice': executedPrice});
    DocumentSnapshot userData = await userRef.get();

    // Convert asset portfolio to double
    double currentAssetPortfolio =
        (userData['assetPortfolio'] as num).toDouble();

    // Calculate new asset portfolio value
    double newAssetPortfolio = currentAssetPortfolio - totalCost;

    // Get the current holdings
    List<dynamic> holdings =
        (userData['holding_shares'] as List<dynamic>) ?? [];

    bool stockExists = false;

    // Update the quantity and buy-in price if the stock already exists in holdings
    for (var holding in holdings) {
      if (holding['hs_tickerSymbol'] == transaction['pt_stockSymbol']) {
        double existingQuantity = (holding['hs_quantity'] as num).toDouble();
        double existingBuyInPrice =
            (holding['hs_buyInPrice'] as num).toDouble();
        double newQuantity = existingQuantity + quantity;

        // Calculate the new average buy-in price
        double newBuyInPrice =
            ((existingBuyInPrice * existingQuantity) + totalCost) / newQuantity;

        holding['hs_quantity'] = newQuantity;
        holding['hs_buyInPrice'] = newBuyInPrice;
        stockExists = true;
        break;
      }
    }

    if (!stockExists) {
      // Append the new holding if the stock doesn't exist in the current holdings
      Map<String, dynamic> newHolding = {
        'hs_buyInPrice': executedPrice,
        'hs_purchaseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'hs_quantity': transaction['pt_quantity'],
        'hs_tickerSymbol': transaction['pt_stockSymbol']
      };
      holdings.add(newHolding);
    }

    await userRef.update(
        {'holding_shares': holdings, 'assetPortfolio': newAssetPortfolio});

    fetchPortfolioDistribution();
  }

  Future<void> executeSellTransaction(
      DocumentReference transactionRef,
      Map<String, dynamic> transaction,
      DocumentReference userRef,
      double executedPrice) async {
    // Convert quantity to double
    double quantity = (transaction['pt_quantity'] as num).toDouble();
    double totalRevenue = executedPrice * quantity;

    await transactionRef.update(
        {'pt_orderStatus': 'executed', 'pt_executedPrice': executedPrice});
    DocumentSnapshot userData = await userRef.get();

    // Convert asset portfolio to double
    double currentAssetPortfolio =
        (userData['assetPortfolio'] as num).toDouble();

    // Calculate new asset portfolio value
    double newAssetPortfolio = currentAssetPortfolio + totalRevenue;

    // Get the current holdings
    List<dynamic> holdings =
        (userData['holding_shares'] as List<dynamic>) ?? [];

    bool stockExists = false;

    // Update the quantity if the stock already exists in holdings
    for (var holding in holdings) {
      if (holding['hs_tickerSymbol'] == transaction['pt_stockSymbol']) {
        double existingQuantity = (holding['hs_quantity'] as num).toDouble();
        if (existingQuantity < quantity) {
          throw Exception("Not enough shares to sell.");
        }

        double newQuantity = existingQuantity - quantity;

        if (newQuantity == 0) {
          // Remove the stock if all shares are sold
          holdings.remove(holding);
        } else {
          holding['hs_quantity'] = newQuantity;
        }

        stockExists = true;
        break;
      }
    }

    if (!stockExists) {
      throw Exception("Stock not found in holdings.");
    }

    await userRef.update(
        {'holding_shares': holdings, 'assetPortfolio': newAssetPortfolio});

    fetchPortfolioDistribution();
  }

  Future<void> fetchPortfolioDistribution() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    // Safely cast the data to Map<String, dynamic>
    Map<String, dynamic>? data = userData.data() as Map<String, dynamic>?;

    if (data != null) {
      // Safely cast the holding shares as List<dynamic>
      List<dynamic>? holdings = data['holding_shares'] as List<dynamic>?;
      if (holdings != null && holdings.isNotEmpty) {
        Map<String, double> stockValues = {};
        double totalValue = 0.0;

        for (var holding in holdings) {
          if (holding is Map<String, dynamic>) {
            double buyInPrice = (holding['hs_buyInPrice'] as num).toDouble();
            double quantity = (holding['hs_quantity'] as num).toDouble();
            double value = buyInPrice * quantity;
            totalValue += value;
            String tickerSymbol = holding['hs_tickerSymbol'] as String;
            stockValues[tickerSymbol] =
                (stockValues[tickerSymbol] ?? 0) + value;
          }
        }

        if (totalValue > 0) {
          // Compute the percentage for each stock in the portfolio
          Map<String, double> portfolioDistribution =
              stockValues.map((key, value) {
            return MapEntry(key, (value / totalValue) * 100);
          });

          setState(() {
            this.portfolioDistribution = portfolioDistribution;
          });
        } else {
          // Handle cases where there are holdings but no calculable values
          setState(() {
            portfolioDistribution = {};
          });
        }
      } else {
        // Handle cases where there are no holdings
        setState(() {
          portfolioDistribution = {};
        });
      }
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
        title: Text(
          'Trading',
          style: GoogleFonts.robotoCondensed(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 188, 208, 225),
              Color.fromARGB(255, 168, 185, 229),
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
              } else {
                var holdings =
                    snapshot.data?['holding_shares'] as List<dynamic>? ?? [];
                return Column(
                  children: [
                    OverviewCard(
                        assetPortfolio: snapshot.data?['assetPortfolio']),
                    PieChartSample2(
                        portfolioDistribution: portfolioDistribution),
                    TogglePositionsOrdersWidget(
                      holdings: holdings,
                      refreshTransactions: () =>
                          checkAndExecuteTransactions(context),
                      // refreshHoldings: () => fetchPortfolioDistribution(),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }
}

class PieChartSample2 extends StatelessWidget {
  final Map<String, double> portfolioDistribution;

  PieChartSample2({required this.portfolioDistribution});

  final List<Color> customColors = [
    Color(0xFF97D3CB),
    Color(0xFFF17961),
    Color(0xFFFECE8C),
    Color(0xFFAC9F7C),
    Color.fromARGB(255, 151, 152, 211),
    Color.fromARGB(255, 211, 151, 180),
    Color.fromARGB(255, 151, 211, 158),
  ];

  // Method to get color by index
  Color getColorByIndex(int index) {
    return customColors[index % customColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (portfolioDistribution.isEmpty) {
      double screenWidth = MediaQuery.of(context).size.width;
      return Container(
        width: screenWidth - 30,
        margin:
            EdgeInsets.symmetric(horizontal: 16), // Adjust horizontal margin
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.all(16), // Outer padding for the entire card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 5), // Spacing above the title
                  child: Text(
                    'Portfolio Distribution',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'No data available for portfolio distribution',
                    textAlign:
                        TextAlign.center, // This centers the text horizontally
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 13,
                      color: const Color.fromARGB(210, 0, 0, 0),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    final List<PieChartSectionData> sections =
        portfolioDistribution.entries.map((entry) {
      final colorIndex = portfolioDistribution.keys.toList().indexOf(entry.key);
      final color = getColorByIndex(colorIndex);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value).toStringAsFixed(2)}%',
        titleStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 60,
        showTitle: true,
        titlePositionPercentageOffset:
            0.55, // Adjust the position of the title as needed
      );
    }).toList();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16), // Outer padding for the entire card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 5), // Spacing above the title
              child: Text(
                'Portfolio Distribution',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: 8), // Padding around the pie chart
              height: 220, // Adjust size as necessary
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: sections,
                  sectionsSpace: 2, // Optional: add space between sections
                ),
              ),
            ),
            // Adding a legend
            Padding(
              padding:
                  const EdgeInsets.only(top: 2), // Padding above the legend
              child: Wrap(
                spacing: 10, // Horizontal spacing between legend items
                runSpacing:
                    10, // Vertical spacing between lines of legend items
                children: portfolioDistribution.entries.map((entry) {
                  final colorIndex =
                      portfolioDistribution.keys.toList().indexOf(entry.key);
                  final color = getColorByIndex(colorIndex);
                  return Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: color),
                        SizedBox(width: 6),
                        Text(
                            '${entry.key}: ${(entry.value).toStringAsFixed(2)}%'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  final dynamic assetPortfolio;
  OverviewCard({this.assetPortfolio});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      color: Color(0xFFeeeef7),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your total asset portfolio',
                style: GoogleFonts.robotoCondensed(
                    fontSize: 18, color: Colors.black54)),
            SizedBox(height: 10),
            Text('\$${assetPortfolio.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SP500TradingPage())),
              child: Text('Invest now'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D0828),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class HoldingsDetailsCard extends StatelessWidget {
  final List<dynamic> holdings;

  HoldingsDetailsCard({Key? key, required this.holdings}) : super(key: key);

  Future<double> getCurrentMarketPrice(String tickerSymbol) async {
    final url = Uri.parse('http://10.0.2.2:5000/detailed_stock_info');
    final response = await http.post(url,
        body: jsonEncode({'ticker': tickerSymbol}),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return double.tryParse(data['currentClose'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  @override
  Widget build(BuildContext context) {
    double rowHeight = 72.0;
    double cardHeight =
        holdings.isEmpty ? rowHeight : min(holdings.length, 5) * rowHeight;

    return Card(
      margin: EdgeInsets.all(16),
      child: SizedBox(
        height: cardHeight,
        child: holdings.isEmpty
            ? Center(
                child: Text(
                  'No holdings data available',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
            : ListView.builder(
                itemCount: holdings.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<double>(
                    future: getCurrentMarketPrice(
                        holdings[index]['hs_tickerSymbol']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          title: Text(
                              '${holdings[index]['hs_tickerSymbol']} loading...'),
                        );
                      }
                      if (snapshot.hasError) {
                        return ListTile(
                          title: Text(
                              '${holdings[index]['hs_tickerSymbol']} error loading price'),
                          subtitle: Text('Error: ${snapshot.error}'),
                        );
                      }
                      double currentPrice = snapshot.data ?? 0.0;
                      double marketValue =
                          currentPrice * holdings[index]['hs_quantity'];
                      double buyInPrice = double.parse(
                          holdings[index]['hs_buyInPrice'].toString());
                      double pl = (currentPrice - buyInPrice) *
                          holdings[index]['hs_quantity'];

                      return ListTile(
                        title: Text('${holdings[index]['hs_tickerSymbol']}'),
                        subtitle: Text(
                            'Quantity: ${holdings[index]['hs_quantity'].toStringAsFixed(0)} at \$${holdings[index]['hs_buyInPrice'].toStringAsFixed(2)}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('MV: \$${marketValue.toStringAsFixed(2)}'),
                            Text(
                              'Today\'s P/L: \$${pl.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: pl >= 0 ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class TodaysOrdersCard extends StatefulWidget {
  @override
  _TodaysOrdersCardState createState() => _TodaysOrdersCardState();
}

class _TodaysOrdersCardState extends State<TodaysOrdersCard> {
  List<dynamic> orders = [];
  Set<String> longPressedOrders = Set<String>();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> cancelOrder(String orderId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user found');
      return;
    }

    try {
      DocumentReference transactionRef = FirebaseFirestore.instance
          .collection('paper_trading_transaction')
          .doc(orderId);

      await transactionRef.update({'pt_orderStatus': 'canceled'});

      // Refresh orders
      fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order canceled successfully')),
      );
    } catch (e) {
      print('Error canceling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order')),
      );
    }
  }

  Future<void> fetchOrders() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user found');
      return;
    }

    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userData.exists) {
        print('User data does not exist');
        return;
      }

      List<dynamic> transactionRefs = (userData.data()
                  as Map<String, dynamic>?)?['paperTrading_transactionID']
              as List<dynamic>? ??
          [];
      if (transactionRefs.isEmpty) {
        print('No transaction references found');
        return;
      }

      List<Future<DocumentSnapshot<Object?>>> transactionFutures =
          transactionRefs.map((ref) {
        if (ref is DocumentReference) {
          return ref.get() as Future<DocumentSnapshot<Object?>>;
        } else {
          print("Invalid reference format");
          return Future.value(null as DocumentSnapshot<Object?>);
        }
      }).toList();

      List<DocumentSnapshot<Object?>> transactions =
          await Future.wait(transactionFutures);
      transactions.removeWhere((element) => element == null);

      List<dynamic> pendingOrders = transactions
          .where((doc) =>
              doc.exists &&
              (doc.data() as Map<String, dynamic>)['pt_orderStatus'] ==
                  'pending')
          .map((doc) {
        var docData = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'stockSymbol': docData['pt_stockSymbol'],
          'quantity': docData['pt_quantity'],
          'price': docData['pt_pricePerShare'],
          'orderType': docData['pt_orderType'],
          'transactionType': docData['pt_transactionType'],
          'orderStatus': docData['pt_orderStatus'],
        };
      }).toList();

      if (pendingOrders.isEmpty) {
        print('No pending orders found');
      } else {
        setState(() {
          orders = pendingOrders;
        });
        print('Pending orders updated successfully: ${pendingOrders.length}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: SizedBox(
        height: orders.isEmpty
            ? 80.0
            : 80.0 *
                min(orders.length,
                    5), // Set minimum height or adjust based on items
        child: orders.isEmpty
            ? Center(
                child: Text(
                  'No orders found today',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
            : ListView(
                children: orders.map((order) {
                  Color textColor = order['transactionType'] == 'buy'
                      ? Colors.green
                      : Colors.red;
                  String orderId = order['id'];
                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        longPressedOrders.add(orderId);
                      });
                    },
                    onTap: () {
                      setState(() {
                        longPressedOrders.remove(orderId);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          Container(
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(order['stockSymbol']),
                                  SizedBox(width: 10),
                                  Text(
                                      '(${order['transactionType']})'
                                          .toUpperCase(),
                                      style: TextStyle(color: textColor)),
                                ],
                              ),
                              subtitle: Text(
                                  'Order Type: ${order['orderType']}\nQuantity: ${order['quantity']} at \$${order['price'].toStringAsFixed(2)}'),
                              trailing: Text(order['orderStatus'].toUpperCase(),
                                  style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 207, 127, 8))),
                            ),
                          ),
                          if (longPressedOrders.contains(orderId))
                            Positioned(
                              top: -10,
                              right: -10,
                              child: IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: orderId != null
                                    ? () => cancelOrder(orderId)
                                    : null, // Disable the button if order ID is null
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class TogglePositionsOrdersWidget extends StatefulWidget {
  final List<dynamic> holdings;
  final Function refreshTransactions;

  TogglePositionsOrdersWidget({
    required this.holdings,
    required this.refreshTransactions,
  });

  @override
  _TogglePositionsOrdersWidgetState createState() =>
      _TogglePositionsOrdersWidgetState();
}

class _TogglePositionsOrdersWidgetState
    extends State<TogglePositionsOrdersWidget> {
  bool showPositions = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16), // Add some margin around the card
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Positions',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Today's Orders",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
              isSelected: [showPositions, !showPositions],
              onPressed: (int index) {
                setState(() {
                  showPositions = index == 0;
                  widget.refreshTransactions();
                });
              },
              borderColor: Color(0xFF0D0828),
              selectedBorderColor: Color(0xFF0D0828),
              selectedColor: Colors.white,
              fillColor: Color(0xFF0D0828),
            ),
          ),
          Divider(
              color: Colors.grey[300],
              thickness: 1), // Optional divider for better visual separation
          showPositions
              ? HoldingsDetailsCard(holdings: widget.holdings)
              : TodaysOrdersCard(),
        ],
      ),
    );
  }
}
