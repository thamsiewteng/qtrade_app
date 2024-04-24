import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:qtrade_app/screen/backtestDetailsPage.dart';

class DeployedAlgoDetailsPage extends StatelessWidget {
  final String documentId;

  DeployedAlgoDetailsPage({required this.documentId});

  Future<List<Map<String, dynamic>>> fetchBacktestHistory(
      List<DocumentReference> backtestReferences) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> backtestData = [];

    // You should ensure that backtestReferences is not null before iterating
    if (backtestReferences != null) {
      for (var ref in backtestReferences) {
        var doc = await ref.get();
        if (doc.data() != null) {
          backtestData.add(doc.data() as Map<String, dynamic>);
        }
      }
    }

    return backtestData;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'Deploy Result',
          style: GoogleFonts.robotoCondensed(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
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
        child: FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('deployed_algo').doc(documentId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return Center(child: Text('Document does not exist'));
            }

            var backtestdata = snapshot.data!.data() as Map<String, dynamic>;
            List<DocumentReference> backtestRefs = (backtestdata[
                    'deploy_backtest'] as List)
                .map((item) => item as DocumentReference)
                .toList(); // Make sure to check for null before this operation.

            var data = snapshot.data!.data() as Map<String, dynamic>;
            String graphDataString = data['deploy_graph'];
            Map<String, dynamic> graphData =
                graphDataString != null ? jsonDecode(graphDataString) : {};

            List<String> dates = List<String>.from(graphData['dates']);

            List<double> actual = graphData['actual'] != null
                ? List<double>.from(
                    graphData['actual'].map((x) => x.toDouble()).toList())
                : [];
            List<double> predicted = graphData['predicted'] != null
                ? List<double>.from(
                    graphData['predicted'].map((x) => x.toDouble()).toList())
                : [];

            List<FlSpot> actualDataPoints = List.generate(actual.length,
                (index) => FlSpot(index.toDouble(), actual[index]));
            List<FlSpot> predictedDataPoints = List.generate(predicted.length,
                (index) => FlSpot(index.toDouble(), predicted[index]));

            final minY = actual.reduce(math.min) * 0.9;
            final maxY = actual.reduce(math.max) * 1.1;
            final pointsPerMonth = 30; // Adjust this value as needed

            final screenWidth = MediaQuery.of(context).size.width;
            final graphWidth = screenWidth *
                2; // Adjust the scaling factor as needed to fit the graph
            final double topPadding =
                20; // Additional top padding for the highest price
            final maxYWithPadding = maxY + topPadding;

            final String deployName = data['deploy_algoName'];
            final String deployAlgoID = data['deploy_algoID'];
            final String deployTicker = data['deploy_stockTicker'];

            DateTime deployDate = (data['deploy_date'] as Timestamp).toDate();

            // Format the dates

            String formattedDeployedDate = formatDateWithTimezone(deployDate,
                pattern: 'dd/MM/yyyy HH:mm:ss', isUtc: true);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Actual vs Predicted',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: graphWidth,
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: _leftTitleWidgets,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: _leftTitleWidgets,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8.0,
                                        child: Text(
                                          value % pointsPerMonth == 0
                                              ? _getMonthLabel(value ~/
                                                  pointsPerMonth.toInt())
                                              : '',
                                          style: TextStyle(
                                            color: Color(0xff67727d),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    },
                                    interval: pointsPerMonth.toDouble(),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                    color: const Color(0xff37434d), width: 1),
                              ),
                              minX: 0,
                              maxX: actual.length.toDouble() - 1,
                              minY: minY,
                              maxY: maxYWithPadding,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: actualDataPoints,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: predictedDataPoints,
                                  isCurved: true,
                                  color: Colors.orange,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  //tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedSpots) {
                                    String?
                                        dateText; // Variable to store the date text
                                    return touchedSpots.map((barSpot) {
                                      final String date =
                                          dates[barSpot.spotIndex.toInt()];
                                      final bool isTouchedActual =
                                          barSpot.barIndex == 0;

                                      // Build the text for the tooltip item.
                                      String tooltipText;
                                      if (dateText == null) {
                                        // First tooltip item, add the date.
                                        tooltipText = 'Date: $date\n';
                                        dateText =
                                            date; // Remember that we've added the date.
                                      } else {
                                        // Not the first, just add an empty string.
                                        tooltipText = '';
                                      }
                                      tooltipText += isTouchedActual
                                          ? 'Actual: ${barSpot.y.toStringAsFixed(2)}'
                                          : 'Predicted: ${barSpot.y.toStringAsFixed(2)}';

                                      // Now build and return the tooltip item.
                                      return LineTooltipItem(
                                        tooltipText,
                                        TextStyle(
                                          color: isTouchedActual
                                              ? Colors.white
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                                touchCallback: (FlTouchEvent event,
                                    LineTouchResponse? touchResponse) {},
                                handleBuiltInTouches: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Indicator(
                          color: Colors.blue,
                          text: 'Actual',
                          isSquare: false,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Indicator(
                          color: Colors.orange,
                          text: 'Predicted',
                          isSquare: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 5,
                      shadowColor: Colors.grey.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deployed Algorithm',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text('Algorithm Name: $deployName',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 16,
                                )),
                            Text('Ticker: $deployTicker',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 16,
                                )),
                            Text('Deploy Date: $formattedDeployedDate',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 16,
                                )),
                            SizedBox(height: 20),
                            Text('Performance Metrics',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(
                                height: 10), // Spacing between text and grid
                            GridView.count(
                              shrinkWrap: true,
                              physics:
                                  NeverScrollableScrollPhysics(), // to disable GridView's scrolling
                              crossAxisCount:
                                  2, // Creates a grid with 2 columns
                              childAspectRatio: 3 /
                                  2, // Adjust this value as needed, 3 is width, 1 is height
                              crossAxisSpacing:
                                  10, // Spacing between the cards horizontally
                              mainAxisSpacing:
                                  10, // Spacing between the cards vertically

                              children: <Widget>[
                                PerformanceMetricCard(
                                  title: 'MAE(Mean Absolute Error)',
                                  value: data['deploy_MAE'],
                                  lowThreshold: 5,
                                  highThreshold: 10,
                                ),
                                PerformanceMetricCard(
                                  title: 'MSE(Mean Squared Error)',
                                  value: data['deploy_MSE'],
                                  lowThreshold: 10,
                                  highThreshold: 40,
                                ),
                                PerformanceMetricCard(
                                  title: 'R² (R-Squared)',
                                  value: data['deploy_R2'],
                                  lowThreshold: 0.7,
                                  highThreshold: 0.9,
                                ),
                                PerformanceMetricCard(
                                  title:
                                      'MAPE (Mean Absolute Percentage Error)',
                                  value: data['deploy_MAPE'],
                                  lowThreshold: 5,
                                  highThreshold: 15,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Analysis Card
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 5,
                      shadowColor: Colors.grey.withOpacity(0.5),
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analysis Metrics',
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  )),
                              SizedBox(height: 10),
                              AnalysisMetricCard(
                                title: 'EPS',
                                value: data['deploy_EPS'] ?? 0,
                                goodThreshold: 2, // EPS greater than 2 is good
                                badThreshold: 1, // EPS less than 1 is bad
                              ),
                              AnalysisMetricCard(
                                title: 'Beta',
                                value: data['deploy_beta'] ?? 0,
                                goodThreshold:
                                    1, // Beta less than 1 is good (less volatility)
                                badThreshold:
                                    2, // Beta greater than 2 is bad (more volatility)
                              ),
                              AnalysisMetricCard(
                                title: 'PE Ratio',
                                value: data['deploy_peRatio'] ?? 0,
                                goodThreshold:
                                    15, // PE Ratio less than 15 is good
                                badThreshold:
                                    25, // PE Ratio greater than 25 is bad
                              ),
                              AnalysisMetricCard(
                                title: 'Market Cap',
                                value:
                                    formatMarketCap(data['deploy_marketCap']) ??
                                        0,
                                goodThreshold:
                                    200e9, // Market Cap greater than 200 billion is good
                                badThreshold:
                                    10e9, // Market Cap less than 10 billion is bad
                              ),
                              AnalysisMetricCard(
                                title: 'Volatility',
                                value: data['deploy_volatility'] ?? 0,
                                goodThreshold:
                                    0.5, // Volatility less than 0.5% is good
                                badThreshold:
                                    2, // Volatility greater than 2% is bad
                              ),
                              AnalysisMetricCard(
                                title: 'Trend Insight',
                                value: data['deploy_trendInsight'] ?? '',
                                goodThreshold:
                                    'Uptrend', // Trend insight of 'Uptrend' is good
                                badThreshold:
                                    'Downtrend', // Trend insight of 'Downtrend' is bad
                              ),
                              // ... Add more AnalysisMetricCard widgets if needed ...
                            ],
                          )),
                    ),
                  ),
                  //Backtest history title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Backtest History',
                          style: GoogleFonts.robotoCondensed(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchBacktestHistory(backtestRefs),
                    builder: (context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return Center(
                            child: Text('No backtest data available'));
                      } else {
                        List<Map<String, dynamic>> backtests =
                            snapshot.data ?? [];
                        if (backtests.isEmpty) {
                          return Center(
                              child: Text('No backtest data available'));
                        } else {
                          return Column(
                            children: backtests
                                .asMap()
                                .entries
                                .map((entry) => buildBacktestCard(context,
                                    entry.value, entry.key, deployTicker))
                                .toList(),
                          );
                        }
                      }
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 16.0), // Right padding
                      child: ElevatedButton(
                        onPressed: () {
                          _showBacktestDialog(context, data['deploy_startDate'],
                              data['deploy_date'], deployTicker, deployAlgoID);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Backtest now',
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0D0828), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Button border radius
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instructions'),
          content: Text('Select a start date and end date for backtesting.'),
          actions: <Widget>[
            TextButton(
              child: Text('Got it'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget buildBacktestCard(BuildContext context,
      Map<String, dynamic> backtestData, int index, String stockTicker) {
    DateTime btDate = (backtestData['bt_date'] as Timestamp).toDate();
    DateTime btStartDate =
        DateTime.tryParse(backtestData['bt_startDate']) ?? DateTime.now();
    DateTime btEndDate =
        DateTime.tryParse(backtestData['bt_endDate']) ?? DateTime.now();

    // Format the dates
    String formattedBtDate = DateFormat('dd/MM/yyyy').format(btDate);
    String formattedStartDate = DateFormat('dd/MM/yyyy').format(btStartDate);
    String formattedEndDate = DateFormat('dd/MM/yyyy').format(btEndDate);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BacktestDetailsPage(
              backtestData: backtestData, stockTicker: stockTicker),
        ));
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          title: Text('Backtest ${index + 1}',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Period: $formattedStartDate - $formattedEndDate'),
          trailing: Text(formattedBtDate),
        ),
      ),
    );
  }

  String formatDateWithTimezone(DateTime date,
      {String? pattern, bool isUtc = false}) {
    DateFormat formatter = DateFormat(pattern ?? 'dd/MM/yyyy HH:mm:ss');
    DateTime localDate = isUtc ? date.toLocal() : date;
    return formatter.format(localDate);
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd – kk:mm').format(date);
  }

  void _showBacktestDialog(
      BuildContext context,
      Timestamp deployStartDateTimestamp,
      Timestamp deployEndDateTimestamp,
      String stockTicker,
      String deployAlgoID) {
    // Convert Timestamp to DateTime and adjust for local timezone
    DateTime deployStartDate = deployStartDateTimestamp.toDate().toLocal();
    DateTime deployEndDate = deployEndDateTimestamp.toDate().toLocal();

    // Assuming the backtestStartDate and backtestEndDate are initialized somewhere in your state
    DateTime backtestStartDate =
        deployStartDate; // Or some default start date within the allowed range
    DateTime backtestEndDate =
        deployEndDate; // Or the deployEndDate if it is before today

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Backtest Period',
              style: GoogleFonts.robotoCondensed(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Start Date Picker ListTile
              ListTile(
                title: Text('Start Date:',
                    style: GoogleFonts.robotoCondensed(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Text(formatDateWithTimezone(backtestStartDate,
                    pattern: 'yyyy-MM-dd', isUtc: true)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedStartDate = await showDatePicker(
                    context: context,
                    initialDate: backtestStartDate,
                    firstDate: deployStartDate,
                    lastDate: backtestEndDate,
                  );
                  if (pickedStartDate != null &&
                      pickedStartDate != backtestStartDate) {
                    backtestStartDate = pickedStartDate;
                    // Update your state here
                  }
                },
              ),
              // End Date Picker ListTile
              ListTile(
                title: Text('End Date:',
                    style: GoogleFonts.robotoCondensed(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Text(formatDateWithTimezone(backtestEndDate,
                    pattern: 'yyyy-MM-dd', isUtc: true)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedEndDate = await showDatePicker(
                    context: context,
                    initialDate: backtestEndDate,
                    firstDate: backtestStartDate,
                    lastDate: deployEndDate,
                  );
                  if (pickedEndDate != null &&
                      pickedEndDate != backtestEndDate) {
                    backtestEndDate = pickedEndDate;
                    // Update your state here
                  }
                },
              ),
              // Add your help icon button and other UI components as needed
            ],
          ),
          actions: <Widget>[
            // Cancel button
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Confirm button
            TextButton(
              child: Text('Backtest Now'),
              onPressed: () async {
                debugPrint('selectedalgo: $deployAlgoID');

                debugPrint('stockTicker: $stockTicker');
                debugPrint('startDate: $deployStartDate');
                debugPrint('backtestStartDate: $backtestStartDate');
                debugPrint('backtestEndDate: $backtestEndDate');

                var url = Uri.parse(
                    'http://10.0.2.2:5000/predict/${deployAlgoID}'); // Replace with your actual backend URL
                var headers = {'Content-Type': 'application/json'};
                var requestBody = jsonEncode({
                  'stockSymbol':
                      stockTicker, // Assuming the stock symbol is always 'AMZN'
                  'startDate': formatDateWithTimezone(deployStartDate,
                      pattern: 'yyyy-MM-dd',
                      isUtc:
                          false), // This should probably be dynamic but is hardcoded for now
                  'backtestStartDate': formatDateWithTimezone(backtestStartDate,
                      pattern: 'yyyy-MM-dd', isUtc: false),
                  'backtestEndDate': formatDateWithTimezone(backtestEndDate,
                      pattern: 'yyyy-MM-dd', isUtc: false),
                });

                try {
                  var response =
                      await http.post(url, headers: headers, body: requestBody);
                  if (response.statusCode == 200) {
                    final Map<String, dynamic> responseData =
                        json.decode(response.body);

                    DocumentReference newAlgoRef = await FirebaseFirestore
                        .instance
                        .collection('backtest_algo')
                        .add({
                      'bt_startDate': formatDateWithTimezone(backtestStartDate,
                          pattern: 'yyyy-MM-dd', isUtc: false),
                      'bt_endDate': formatDateWithTimezone(backtestEndDate,
                          pattern: 'yyyy-MM-dd', isUtc: false),
                      'bt_annualReturn': responseData["annual_return"],
                      'bt_totalTrade': responseData["total_trades"],
                      'bt_winRate': responseData["win_rate"],
                      'bt_lossRate': responseData["loss_rate"],
                      'bt_drawdown': responseData["drawdown"],
                      'bt_sharpeRatio': responseData["sharpe_ratio"],
                      'bt_finalPortfolio':
                          responseData["final_portfolio_value"],
                      'bt_date': FieldValue.serverTimestamp(),
                    });

                    print(
                        'Response data added to database with ID: ${newAlgoRef.id}');

                    // Get the ID of the newly added backtest result
                    String backtestResultId = newAlgoRef.id;
                    print(
                        'New backtest result added with ID: $backtestResultId');

                    // Now, update the deployed_algo document with the new backtest reference
                    DocumentReference backtestResultRef = FirebaseFirestore
                        .instance
                        .collection('backtest_algo')
                        .doc(backtestResultId);

// Now, update the deployed_algo document with the new backtest reference
                    var deployedAlgoRef = FirebaseFirestore.instance
                        .collection('deployed_algo')
                        .doc(documentId);
                    await deployedAlgoRef.update({
                      'deploy_backtest':
                          FieldValue.arrayUnion([backtestResultRef])
                    });

                    print('deploy_backtest field updated with new reference.');
                  } else {
                    print(
                        'Request failed with status: ${response.statusCode}.');
                  }
                } catch (e) {
                  print('An error occurred: $e');
                }

                Navigator.of(context)
                    .pop(); // Close the dialog after sending the request
              },
            ),
          ],
        );
      },
    );
  }
}

String formatMarketCap(num value) {
  if (value >= 1e12) {
    return (value / 1e12).toStringAsFixed(3) + 'T';
  } else if (value >= 1e9) {
    return (value / 1e9).toStringAsFixed(3) + 'B';
  } else if (value >= 1e6) {
    return (value / 1e6).toStringAsFixed(3) + 'M';
  } else if (value >= 1e3) {
    return (value / 1e3).toStringAsFixed(3) + 'K';
  } else {
    return value.toString();
  }
}

String _getMonthLabel(int value) {
  List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[value % months.length];
}

Widget _leftTitleWidgets(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(right: 6.0),
    child: Text(
      value.toStringAsFixed(2),
      style: TextStyle(
        color: Color(0xff67727d),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.right,
    ),
  );
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    this.textColor = const Color(0xff505050),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
}

class PerformanceMetricCard extends StatelessWidget {
  final String title;
  final double value;
  final double lowThreshold;
  final double highThreshold;

  PerformanceMetricCard({
    required this.title,
    required this.value,
    required this.lowThreshold,
    required this.highThreshold,
  });

  Color _determineColor() {
    if (value <= lowThreshold) {
      return Color.fromARGB(255, 180, 228, 166);
    } else if (value > highThreshold) {
      return Color.fromARGB(255, 242, 184, 184);
    } else {
      return Color.fromARGB(255, 239, 242, 184);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _determineColor(),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Adjust the padding as needed
        child: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // Centers the children widgets vertically
          crossAxisAlignment: CrossAxisAlignment
              .start, // Aligns the children widgets at the start horizontally
          children: [
            Text(title,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            Expanded(
              child: Center(
                // This will center the value text in the remaining space
                child: Text('${value.toStringAsFixed(2)}%',
                    style: GoogleFonts.robotoCondensed(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisMetricCard<T> extends StatelessWidget {
  final String title;
  final T value;
  final T goodThreshold;
  final T badThreshold;

  AnalysisMetricCard({
    required this.title,
    required this.value,
    required this.goodThreshold,
    required this.badThreshold,
  });

  Color _determineColor() {
    // Handle String values
    if (value is String) {
      return value == goodThreshold
          ? Color.fromARGB(255, 180, 228, 166)
          : (value == badThreshold
              ? Color.fromARGB(255, 242, 184, 184)
              : Color.fromARGB(255, 239, 242, 184));
    }
    // Handle numeric values
    if (value is num) {
      num numValue = value as num;
      num numGoodThreshold = goodThreshold as num;
      num numBadThreshold = badThreshold as num;
      if (numValue <= numGoodThreshold) {
        return Color.fromARGB(255, 180, 228, 166);
      } else if (numValue >= numBadThreshold) {
        return Color.fromARGB(255, 242, 184, 184);
      }
    }
    return Color.fromARGB(255, 239, 242, 184);
  }

  @override
  Widget build(BuildContext context) {
    // Format the display value based on the type
    String displayValue;
    if (value is num) {
      // If value is a number, format to two decimal places
      displayValue = (value as num).toStringAsFixed(3);
    } else {
      // Otherwise, call toString (for non-numeric values)
      displayValue = value.toString();
    }
    return Card(
      color: _determineColor(),
      child: ListTile(
        title: Text(title,
            style: GoogleFonts.robotoCondensed(
                fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: Text(displayValue,
            style: GoogleFonts.robotoCondensed(fontSize: 18)),
      ),
    );
  }
}
