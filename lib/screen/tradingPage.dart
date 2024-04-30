import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    checkAndExecuteTransactions(context);
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
    if (!isUSEquityMarketOpen()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Market is not open")));
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    var userData = await userRef.get();
    List<dynamic> transactionIds =
        userData.data()?['paperTrading_transactionID'] ?? [];

    for (var transactionId in transactionIds) {
      var transactionRef = FirebaseFirestore.instance
          .collection('paper_trading_transaction')
          .doc(transactionId);
      var transaction = await transactionRef.get();
      if (transaction.exists && transaction['pt_orderStatus'] == 'pending') {
        double currentPrice =
            await getCurrentMarketPrice(transaction['pt_stockSymbol']);
        if (transaction['pt_orderType'] == 'Market Order' ||
            (transaction['pt_orderType'] == 'LMT Order' &&
                currentPrice <= transaction['pt_pricePerShare'])) {
          await executeTransaction(
              transactionRef,
              transaction.data() as Map<String, dynamic>,
              userRef,
              currentPrice);
        }
      }
    }
  }

  Future<void> executeTransaction(
      DocumentReference transactionRef,
      Map<String, dynamic> transaction,
      DocumentReference userRef,
      double executedPrice) async {
    await transactionRef.update(
        {'pt_orderStatus': 'executed', 'pt_executedPrice': executedPrice});

    // Append to user's holding shares
    Map<String, dynamic> newHolding = {
      'hs_buyInPrice': executedPrice,
      'hs_purchaseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'hs_quantity': transaction['pt_quantity'],
      'hs_tickerSymbol': transaction['pt_stockSymbol']
    };

    await userRef.update({
      'holding_shares': FieldValue.arrayUnion([newHolding])
    });
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
                return Center(
                  child: Card(
                    margin: EdgeInsets.all(16),
                    color: Color(0xFFeeeef7),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your total asset portfolio',
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '\$${snapshot.data?['assetPortfolio']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SP500TradingPage(),
                                ),
                              );
                            },
                            child: Text('Invest now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0D0828),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
