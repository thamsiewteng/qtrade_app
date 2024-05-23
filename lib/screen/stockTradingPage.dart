import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qtrade_app/widgets/customBottomNavigationBar.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StockTradingPage extends StatefulWidget {
  final String tickerSymbol;

  const StockTradingPage({Key? key, required this.tickerSymbol})
      : super(key: key);

  @override
  _StockTradingPageState createState() => _StockTradingPageState();
}

List<Candle> connectTradingPeriods(List<Candle> candles) {
  List<Candle> connectedCandles = [];
  for (int i = 0; i < candles.length - 1; i++) {
    connectedCandles.add(candles[i]);
    DateTime currentDateTime = candles[i].datetime;
    DateTime nextDateTime = candles[i + 1].datetime;

    // Check if the next candle is on a different day
    if (currentDateTime.day != nextDateTime.day) {
      // Add a connecting candle between the last closing price and the next opening price
      connectedCandles.add(Candle(
        open: candles[i].close,
        high: candles[i].close,
        low: candles[i].close,
        close: candles[i].close,
        datetime: DateTime(currentDateTime.year, currentDateTime.month,
            currentDateTime.day, 23, 59),
      ));
      connectedCandles.add(Candle(
        open: candles[i + 1].open,
        high: candles[i + 1].open,
        low: candles[i + 1].open,
        close: candles[i + 1].open,
        datetime: DateTime(
            nextDateTime.year, nextDateTime.month, nextDateTime.day, 0, 0),
      ));
    }
  }
  connectedCandles.add(candles.last); // Add the last candle
  return connectedCandles;
}

class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final TrackballBehavior trackballBehavior;
  final String selectedPeriod;

  const CandlestickChart({
    Key? key,
    required this.candles,
    required this.trackballBehavior,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double yAxisMinimum = candles.map((candle) => candle.low).reduce(min);
    double yAxisMaximum = candles.map((candle) => candle.high).reduce(max);

    double yAxisPadding = (yAxisMaximum - yAxisMinimum) * 0.1;
    yAxisMinimum -= yAxisPadding;
    yAxisMaximum += yAxisPadding;

    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          zoomMode: ZoomMode.x,
          maximumZoomLevel: 0.1,
        ),
        primaryXAxis: NumericAxis(
          majorGridLines: MajorGridLines(width: 1),
          minorGridLines: MinorGridLines(width: 0.5),
          title: AxisTitle(text: 'Trading Periods'),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
          minimum: yAxisMinimum,
          maximum: yAxisMaximum,
          majorGridLines: MajorGridLines(width: 1),
          minorGridLines: MinorGridLines(width: 0.5),
          interval: (yAxisMaximum - yAxisMinimum) / 5,
        ),
        series: <CandleSeries>[
          CandleSeries<Candle, int>(
            dataSource: candles,
            xValueMapper: (Candle candle, int index) => index,
            lowValueMapper: (Candle candle, _) => candle.low,
            highValueMapper: (Candle candle, _) => candle.high,
            openValueMapper: (Candle candle, _) => candle.open,
            closeValueMapper: (Candle candle, _) => candle.close,
            enableTooltip: true,
            bearColor: Colors.red,
            bullColor: Colors.green,
          )
        ],
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineType: TrackballLineType.vertical,
          tooltipSettings: InteractiveTooltip(
            enable: true,
            color: Colors.white,
            borderWidth: 1,
            borderColor: Colors.black,
            textStyle: TextStyle(color: Colors.black),
            format:
                'Open: \$point.open\nHigh: \$point.high\nLow: \$point.low\nClose: \$point.close\nDate: ${DateFormat.yMMMd().format(DateTime.now())}',
          ),
        ),
      ),
    );
  }
}

class LineChart extends StatelessWidget {
  final List<Candle> candles;
  final TrackballBehavior trackballBehavior;
  final String selectedPeriod;

  const LineChart({
    Key? key,
    required this.candles,
    required this.trackballBehavior,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double yAxisMinimum = candles.map((candle) => candle.low).reduce(min);
    double yAxisMaximum = candles.map((candle) => candle.high).reduce(max);

    double yAxisPadding = (yAxisMaximum - yAxisMinimum) * 0.1;
    yAxisMinimum -= yAxisPadding;
    yAxisMaximum += yAxisPadding;

    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          zoomMode: ZoomMode.x,
          maximumZoomLevel: 0.1,
        ),
        primaryXAxis: NumericAxis(
          majorGridLines: MajorGridLines(width: 1),
          minorGridLines: MinorGridLines(width: 0.5),
          title: AxisTitle(text: 'Trading Periods'),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
          minimum: yAxisMinimum,
          maximum: yAxisMaximum,
          majorGridLines: MajorGridLines(width: 1),
          minorGridLines: MinorGridLines(width: 0.5),
          interval: (yAxisMaximum - yAxisMinimum) / 5,
        ),
        series: <LineSeries<Candle, int>>[
          LineSeries<Candle, int>(
            dataSource: candles,
            xValueMapper: (Candle candle, int index) => index,
            yValueMapper: (Candle candle, _) => candle.close,
            enableTooltip: true,
            color: Colors.blue,
          ),
        ],
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineType: TrackballLineType.vertical,
          tooltipSettings: InteractiveTooltip(
            enable: true,
            color: Colors.white,
            borderWidth: 1,
            borderColor: Colors.black,
            textStyle: TextStyle(color: Colors.black),
            format: 'Date: ${DateFormat.yMMMd().format(DateTime.now())}',
          ),
        ),
      ),
    );
  }
}

class StockInfoWidget extends StatefulWidget {
  final StockInfo info;

  const StockInfoWidget({Key? key, required this.info}) : super(key: key);

  @override
  _StockInfoWidgetState createState() => _StockInfoWidgetState();
}

class _StockInfoWidgetState extends State<StockInfoWidget> {
  bool isExpanded =
      false; // This state controls the visibility of additional info

  @override
  Widget build(BuildContext context) {
    String changePercentSign = widget.info.changePercent > 0 ? '+' : '';
    Color changePercentColor =
        widget.info.changePercent > 0 ? Colors.green : Colors.red;

    return Column(
      children: [
        Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: IntrinsicWidth(
              // Wraps content within its natural width
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded; // Toggle the expanded state
                      });
                    },
                  ),
                  Text(
                    widget.info.companyName,
                    style: GoogleFonts.robotoCondensed(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Text(
                    '($changePercentSign${widget.info.changePercent.toStringAsFixed(2)}%)',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: changePercentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(
                    title: 'High',
                    value: '\$${widget.info.high.toStringAsFixed(2)}'),
                _InfoTile(
                    title: 'Low',
                    value: '\$${widget.info.low.toStringAsFixed(2)}'),
                _InfoTile(
                    title: 'Average',
                    value:
                        '\$${((widget.info.high + widget.info.low) / 2).toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          _buildAdditionalStockInfo(widget.info),
        ],
      ],
    );
  }

  Widget _buildAdditionalStockInfo(StockInfo info) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(
                  title: 'Open',
                  value: '${info.open.toStringAsFixed(2)}',
                ),
                _InfoTile(
                  title: 'Current Close',
                  value: '${info.currentClose.toStringAsFixed(2)}',
                ),
                _InfoTile(
                  title: 'Previous Close',
                  value: '${info.previousClose.toStringAsFixed(2)}',
                ),
                _InfoTile(
                  title: 'Volume',
                  value: _formatNumber(info.volume),
                ),
              ],
            ),
            SizedBox(height: 8), // Spacing between rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoTile(
                  title: 'MarketCap',
                  value: _formatNumber(info.marketCap),
                ),
                _InfoTile(
                  title: 'Beta',
                  value: '${info.beta.toStringAsFixed(2)}',
                ),
                _InfoTile(
                  title: 'EPS',
                  value: '${info.eps.toStringAsFixed(2)}',
                ),
                _InfoTile(
                  title: 'PE Ratio',
                  value: '${info.peRatio.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int number) {
  return NumberFormat.compact().format(number);
}

Widget _InfoTile({required String title, required String value}) {
  return Column(
    children: [
      Text(title,
          style: GoogleFonts.robotoCondensed(fontSize: 16, color: Colors.grey)),
      SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.robotoCondensed(
              fontSize: 18, fontWeight: FontWeight.bold)),
    ],
  );
}

class _StockTradingPageState extends State<StockTradingPage> {
  late Future<List<Candle>> candleData;
  late Future<StockInfo> stockInfo;
  late TrackballBehavior _trackballBehavior;
  String selectedPeriod = '1h';
  String selectedInterval = '1m';
  double currentPrice = 0;

  bool showCandleChart = true;
  bool isCandlestickChart = true; // Added to manage chart type
  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: TrackballLineType.vertical,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: Colors.white,
        borderWidth: 1,
        borderColor: Colors.black,
        textStyle: TextStyle(color: Colors.black),
      ),
    );
    fetchData();
  }

  void fetchData() {
    candleData = fetchCandlestickData(
        widget.tickerSymbol, selectedPeriod, selectedInterval);
    stockInfo = fetchStockInfo(widget.tickerSymbol);
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
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'S&P 500 Trading',
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
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              FutureBuilder<StockInfo>(
                future: fetchStockInfo(widget.tickerSymbol),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    currentPrice = snapshot.data!.currentClose;
                    return StockInfoWidget(info: snapshot.data!);
                  } else {
                    return Text('No stock information available');
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <String, String>{
                    '1h': '1m',
                    '6h': '5m',
                    '24h': '15m',
                    '7d': '1h',
                    '30d': '1h'
                  }.entries.map((entry) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedPeriod = entry.key;
                          selectedInterval = entry.value;
                          fetchData(); // Fetch data with new period and interval
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPeriod == entry.key
                            ? Color(0xFF0D0828)
                            : Colors.white,
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: selectedPeriod == entry.key
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Toggle button for chart type
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ToggleButtons(
                          borderRadius: BorderRadius.circular(10),
                          selectedBorderColor: Color(0xFF0D0828),
                          selectedColor: Colors.white,
                          fillColor: Color(0xFF0D0828),
                          color: Colors.black,
                          borderWidth: 1,
                          borderColor: Color(0xFF0D0828),
                          constraints: BoxConstraints(
                            minHeight: 40,
                            minWidth: 150, // Adjust this to fit the text
                          ),
                          isSelected: [isCandlestickChart, !isCandlestickChart],
                          onPressed: (index) {
                            setState(() {
                              isCandlestickChart = index == 0;
                            });
                          },
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Candlestick Chart',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isCandlestickChart
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Line Graph',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: !isCandlestickChart
                                      ? Colors.white
                                      : Colors.black,
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

              SizedBox(
                height: 500, // Assign a fixed height for the chart
                child: FutureBuilder<List<Candle>>(
                  future: candleData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      List<Candle> candles = snapshot.data!;

                      if (isCandlestickChart) {
                        return CandlestickChart(
                          candles: candles,
                          trackballBehavior: _trackballBehavior,
                          selectedPeriod: selectedPeriod,
                        );
                      } else {
                        return LineChart(
                          candles: candles,
                          trackballBehavior: _trackballBehavior,
                          selectedPeriod: selectedPeriod,
                        );
                      }
                    } else {
                      return Center(child: Text('No candle data available'));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Set your desired horizontal padding
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          try {
                            double assetPortfolio = await fetchAssetPortfolio();
                            _showBuyDialog(context, widget.tickerSymbol,
                                currentPrice, assetPortfolio);
                          } catch (e) {
                            print("Failed to fetch asset portfolio: $e");
                            // Optionally, handle this case in your UI, e.g., by showing an error message
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color.fromARGB(
                              255, 180, 228, 166), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // Button border radius
                          ),
                          padding: EdgeInsets.all(
                              8.0), // Inner padding for TextButton
                        ),
                        child: Text(
                          'Buy',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          try {
                            String? userId = getCurrentUserId();
                            if (userId != null) {
                              int sellableShares = await fetchUserHoldings(
                                  userId, widget.tickerSymbol);
                              if (sellableShares > 0) {
                                _showSellDialog(context, widget.tickerSymbol,
                                    currentPrice, sellableShares);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'You do not have any shares to sell.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('No user found, please login.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            print("Failed to fetch user holdings: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to fetch user holdings: $e'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 242, 184, 184),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(8.0),
                        ),
                        child: Text(
                          'Sell',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
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

String? getCurrentUserId() {
  User? user = FirebaseAuth.instance.currentUser;
  return user
      ?.uid; // This will return the user ID or null if no user is signed in
}

Future<List<Candle>> fetchCandlestickData(
    String tickerSymbol, String period, String interval) async {
  try {
    final url = Uri.parse('http://10.0.2.2:5000/candlestick_data');
    final headers = {"Content-Type": "application/json"};
    final body = json.encode(
        {"ticker": tickerSymbol, "period": period, "interval": interval});
//1h 1m
//6h 30m
//24h 1h
//7d 1h
//30d 1d/1h

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // print(response.body);
      List<dynamic> data = json.decode(response.body);
      return data.map((candleData) => Candle.fromJson(candleData)).toList();
    } else {
      throw Exception(
          'Failed to load candlestick data. Status code: ${response.statusCode}');
    }
  } on Exception catch (e) {
    // Handle the exception by logging or displaying an error message
    print('Error fetching candlestick data: $e');
    rethrow; // This will allow the FutureBuilder to catch the error and handle it
  }
}

Future<StockInfo> fetchStockInfo(String tickerSymbol) async {
  final url = Uri.parse('http://10.0.2.2:5000/detailed_stock_info');
  final headers = {"Content-Type": "application/json"};
  final body = json.encode({"ticker": tickerSymbol});

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    Map<String, dynamic> data = json.decode(response.body);
    return StockInfo.fromJson(data);
  } else {
    throw Exception(
        'Failed to load detailed stock information. Status code: ${response.statusCode}');
  }
}

Future<void> handleBuy(String userId, String tickerSymbol, double price,
    int quantity, String orderType) async {
  try {
    // Create a transaction record
    DocumentReference transactionRef = await FirebaseFirestore.instance
        .collection('paper_trading_transaction')
        .add({
      'pt_stockSymbol': tickerSymbol,
      'pt_pricePerShare': price,
      'pt_quantity': quantity,
      'pt_orderType': orderType,
      'pt_date': DateTime.now().toUtc().add(Duration(hours: 8)).toString(),
      'pt_orderStatus': 'pending',
      'pt_transactionType': 'buy'
    });

    // Update the user's document with the transaction reference
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'paperTrading_transactionID': FieldValue.arrayUnion([transactionRef])
    });

    // Optionally, update other user fields or handle further business logic
  } catch (e) {
    print("An error occurred while processing the transaction: $e");
  }
}

Future<void> handleSell(
  String userId,
  String tickerSymbol,
  double price,
  int quantity,
  String orderType,
  double currentPrice,
) async {
  try {
    if (orderType == 'Market Order') {
      price = currentPrice; // Use current price for market order
    }

    DocumentReference transactionRef = await FirebaseFirestore.instance
        .collection('paper_trading_transaction')
        .add({
      'pt_stockSymbol': tickerSymbol,
      'pt_pricePerShare': price,
      'pt_quantity': quantity,
      'pt_orderType': orderType,
      'pt_date': DateTime.now().toUtc().add(Duration(hours: 8)).toString(),
      'pt_orderStatus': 'pending',
      'pt_transactionType': 'sell'
    });

    // Update the user's document with the transaction reference
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'paperTrading_transactionID': FieldValue.arrayUnion([transactionRef])
    });

    // Optionally, you can handle further business logic here if needed
  } catch (e) {
    print("An error occurred while processing the transaction: $e");
  }
}

Future<double> fetchAssetPortfolio() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      var portfolio =
          (userDoc.data() as Map<String, dynamic>)['assetPortfolio'];
      return (portfolio is int)
          ? portfolio.toDouble()
          : (portfolio as double? ?? 0.0);
    } else {
      return 0.0; // Or handle the absence of data appropriately
    }
  } else {
    throw Exception("No user logged in");
  }
}

Future<int> fetchUserHoldings(String userId, String tickerSymbol) async {
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (userDoc.exists) {
    var holdings = (userDoc.data() as Map<String, dynamic>)['holding_shares']
        as List<dynamic>;
    for (var holding in holdings) {
      if (holding['hs_tickerSymbol'] == tickerSymbol) {
        print(holding['hs_quantity']);
        return (holding['hs_quantity'] as num).toInt();
      }
    }
  }
  return 0; // User does not hold any shares of the tickerSymbol
}

class Candle {
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime datetime;

  Candle(
      {required this.open,
      required this.high,
      required this.low,
      required this.close,
      required this.datetime});

  factory Candle.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat("yyyy-MM-dd HH:mm");
    return Candle(
      open: json['open'],
      high: json['high'],
      low: json['low'],
      close: json['close'],
      datetime: dateFormat.parse(json['datetime']),
    );
  }
}

class StockInfo {
  final double beta;
  final String companyName;
  final double eps;
  final double high;
  final double low;
  final int marketCap;
  final double open;
  final double peRatio;
  final double previousClose;
  final String ticker;
  final int volume;
  final double changePercent;
  final double currentClose;

  StockInfo({
    required this.beta,
    required this.companyName,
    required this.eps,
    required this.high,
    required this.low,
    required this.marketCap,
    required this.open,
    required this.peRatio,
    required this.previousClose,
    required this.ticker,
    required this.volume,
    required this.changePercent,
    required this.currentClose,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      beta: json['beta'],
      companyName: json['companyName'],
      eps: json['eps'],
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      marketCap: json['marketCap'],
      open: json['open'].toDouble(),
      peRatio: json['peRatio'].toDouble(),
      previousClose: json['previousClose'].toDouble(),
      ticker: json['ticker'],
      volume: json['volume'],
      changePercent: json['changePercent'].toDouble(),
      currentClose: json['currentClose'].toDouble(),
    );
  }
}

InputDecoration getDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
  );
}

void _showBuyDialog(BuildContext context, String tickerSymbol,
    double currentPrice, double totalAssetPortfolio) {
  TextEditingController symbolController =
      TextEditingController(text: tickerSymbol);
  TextEditingController priceController =
      TextEditingController(text: currentPrice.toStringAsFixed(2));
  TextEditingController quantityController = TextEditingController(text: '1');
  TextEditingController amountController =
      TextEditingController(text: currentPrice.toStringAsFixed(2));
  TextEditingController buyableController = TextEditingController();

  // Calculate initial buyable amount
  int initialBuyable = (totalAssetPortfolio / currentPrice).floor();
  buyableController.text = initialBuyable.toString();

  void updateAmount() {
    double price = double.tryParse(priceController.text) ?? 0.0;
    int quantity = int.tryParse(quantityController.text) ?? 0;
    double amount = price * quantity;
    int buyable = (totalAssetPortfolio / price).floor();

    amountController.text = amount.toStringAsFixed(2); // Format to two decimals
    buyableController.text = buyable.toString(); // Update buyable amount
    if (quantity > buyable) {
      quantityController.text = buyable
          .toString(); // Adjust quantity if it exceeds the buyable amount
      amountController.text =
          (price * buyable).toStringAsFixed(2); // Adjust total amount
    }
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      String dropdownValue = 'LMT Order'; // Default to LMT Order
      bool isPriceEnabled = true; // Price is enabled by default

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('S&P 500 Stock Paper Trading',
                        style: GoogleFonts.robotoCondensed(
                            fontWeight: FontWeight.bold, fontSize: 20.0)),
                    SizedBox(height: 20.0),
                    TextFormField(
                      enabled: false,
                      controller: symbolController,
                      decoration: getDecoration('Symbol'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      decoration: getDecoration('Types').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.help_outline),
                          onPressed: () => _showOrderTypeDialog(context),
                        ),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            dropdownValue = newValue;
                            isPriceEnabled = newValue ==
                                'LMT Order'; // Enable price only for LMT Order
                            if (!isPriceEnabled) {
                              priceController.text = currentPrice
                                  .toStringAsFixed(2); // Reset to current price
                              updateAmount();
                            }
                          });
                        }
                      },
                      items: <String>['LMT Order', 'Market Order']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    IncrementDecrementField(
                      label: 'Price',
                      controller: priceController,
                      onChanged: (value) {
                        updateAmount();
                      },
                      isPrice: true,
                      isEnabled: isPriceEnabled,
                    ),
                    SizedBox(height: 16),
                    IncrementDecrementField(
                      label: 'Quantity',
                      controller: quantityController,
                      onChanged: (value) {
                        updateAmount();
                      },
                      isPrice: false,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      enabled: false,
                      decoration: getDecoration('Amount'),
                      controller: amountController,
                    ),
                    //SizedBox(height: 16),
                    SizedBox(
                        height:
                            4), // Add some space between the text and disclaimer
                    Text(
                      'A transaction fee of 0.2% is applied to each buy and sell order.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black, // Lighter color for the disclaimer
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black), // Default text style
                          children: <TextSpan>[
                            TextSpan(text: 'Buyable: '), // The label in black
                            TextSpan(
                              text:
                                  '$initialBuyable shares', // The value in green
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        String? userId = getCurrentUserId();
                        if (userId != null) {
                          handleBuy(
                                  userId,
                                  symbolController.text,
                                  double.parse(priceController.text),
                                  int.parse(quantityController.text),
                                  dropdownValue)
                              .then((_) {
                            Navigator.pop(context); // Close the dialog first
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Your order has been placed successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to place order: $error'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          });
                        } else {
                          print("No user found, please login.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No user found, please login.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text('Buy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 180, 228, 166),
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _showSellDialog(BuildContext context, String tickerSymbol,
    double currentPrice, int sellableShares) {
  TextEditingController symbolController =
      TextEditingController(text: tickerSymbol);
  TextEditingController priceController =
      TextEditingController(text: currentPrice.toStringAsFixed(2));
  TextEditingController quantityController = TextEditingController(text: '1');
  TextEditingController amountController =
      TextEditingController(text: currentPrice.toStringAsFixed(2));
  TextEditingController sellableController =
      TextEditingController(text: sellableShares.toString());

  void updateAmount() {
    double price = double.tryParse(priceController.text) ?? 0.0;
    int quantity = int.tryParse(quantityController.text) ?? 0;
    double amount = price * quantity;

    amountController.text = amount.toStringAsFixed(2); // Format to two decimals
    if (quantity > sellableShares) {
      quantityController.text = sellableShares
          .toString(); // Adjust quantity if it exceeds the sellable shares
      amountController.text =
          (price * sellableShares).toStringAsFixed(2); // Adjust total amount
    }
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      String dropdownValue = 'LMT Order'; // Default to LMT Order
      bool isPriceEnabled = true; // Price is enabled by default

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('S&P 500 Stock Paper Trading',
                        style: GoogleFonts.robotoCondensed(
                            fontWeight: FontWeight.bold, fontSize: 20.0)),
                    SizedBox(height: 20.0),
                    TextFormField(
                      enabled: false,
                      controller: symbolController,
                      decoration: getDecoration('Symbol'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      decoration: getDecoration('Types').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.help_outline),
                          onPressed: () => _showOrderTypeDialog(context),
                        ),
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            dropdownValue = newValue;
                            isPriceEnabled = newValue ==
                                'LMT Order'; // Enable price only for LMT Order
                            if (!isPriceEnabled) {
                              priceController.text = currentPrice
                                  .toStringAsFixed(2); // Reset to current price
                              updateAmount();
                            }
                          });
                        }
                      },
                      items: <String>['LMT Order', 'Market Order']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    IncrementDecrementField(
                      label: 'Price',
                      controller: priceController,
                      onChanged: (value) {
                        updateAmount();
                      },
                      isPrice: true,
                      isEnabled: isPriceEnabled,
                    ),
                    SizedBox(height: 16),
                    IncrementDecrementField(
                      label: 'Quantity',
                      controller: quantityController,
                      onChanged: (value) {
                        updateAmount();
                      },
                      isPrice: false,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      enabled: false,
                      decoration: getDecoration('Amount'),
                      controller: amountController,
                    ),
                    SizedBox(
                        height:
                            4), // Add some space between the text and disclaimer
                    Text(
                      'A transaction fee of 0.2% is applied to each buy and sell order.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black, // Lighter color for the disclaimer
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black), // Default text style
                          children: <TextSpan>[
                            TextSpan(text: 'Sellable: '), // The label in black
                            TextSpan(
                              text:
                                  '$sellableShares shares', // The value in green
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        String? userId = getCurrentUserId();
                        if (userId != null) {
                          handleSell(
                            userId,
                            symbolController.text,
                            double.parse(priceController.text),
                            int.parse(quantityController.text),
                            dropdownValue,
                            currentPrice,
                          ).then((_) {
                            Navigator.pop(context); // Close the dialog first
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Your sell order has been placed successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to place sell order: $error'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          });
                        } else {
                          print("No user found, please login.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No user found, please login.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text('Sell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 242, 184, 184),
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _showOrderTypeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Order Type Description',
          style: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'LMT Order',
                style: GoogleFonts.robotoCondensed(),
              ),
              Text(
                'Enhanced limit orders can be placed at a specified price. Trading hours: 09:30-12:00 & 13:00-16:00, excluding Saturdays, Sundays, and public holidays.',
                style: GoogleFonts.robotoCondensed(),
              ),
              SizedBox(height: 8),
              Text(
                'Market Order',
                style: GoogleFonts.robotoCondensed(),
              ),
              Text(
                'A market order is used to buy or sell at the market price rather than at a specified price.',
                style: GoogleFonts.robotoCondensed(),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Close',
              style: GoogleFonts.robotoCondensed(),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class IncrementDecrementField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final Function(double) onChanged;
  final bool isPrice; // Determines if it handles price or quantity
  final bool isEnabled; // Determines if the field is enabled or disabled

  IncrementDecrementField({
    Key? key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.isPrice = false,
    this.isEnabled = true, // By default, the field is enabled
  }) : super(key: key);

  @override
  _IncrementDecrementFieldState createState() =>
      _IncrementDecrementFieldState();
}

class _IncrementDecrementFieldState extends State<IncrementDecrementField> {
  late double currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = double.tryParse(widget.controller.text) ?? 0;
  }

  void _increment() {
    if (!widget.isEnabled) return; // Prevent increment when disabled
    setState(() {
      currentValue += 1;
      widget.controller.text = widget.isPrice
          ? currentValue.toStringAsFixed(2)
          : currentValue.toInt().toString(); // No decimal for quantity
      widget.onChanged(currentValue);
    });
  }

  void _decrement() {
    if (!widget.isEnabled) return; // Prevent decrement when disabled
    setState(() {
      if (currentValue > 0) {
        currentValue -= 1;
        widget.controller.text = widget.isPrice
            ? currentValue.toStringAsFixed(2)
            : currentValue.toInt().toString(); // No decimal for quantity
        widget.onChanged(currentValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: widget.isEnabled, // Use isEnabled to enable/disable the field
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: _decrement,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _increment,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
      keyboardType: widget.isPrice
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
    );
  }
}
