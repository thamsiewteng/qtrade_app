import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qtrade_app/screen/backtestDetailsPage.dart';
import 'package:qtrade_app/services/notification_provider.dart';

class DeployedAlgoDetailsPage extends StatefulWidget {
  final String documentId;

  DeployedAlgoDetailsPage({required this.documentId});

  @override
  _DeployedAlgoDetailsPageState createState() =>
      _DeployedAlgoDetailsPageState();
}

enum BacktestStatus { idle, inProgress, success, failure }

class _DeployedAlgoDetailsPageState extends State<DeployedAlgoDetailsPage> {
  BacktestStatus _backtestStatus = BacktestStatus.idle;
  String? _backtestMessage;

  Future<List<Map<String, dynamic>>> fetchBacktestHistory(
      List<DocumentReference> backtestReferences) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> backtestData = [];

    if (backtestReferences.isNotEmpty) {
      for (var ref in backtestReferences) {
        var doc = await ref.get();
        if (doc.data() != null) {
          backtestData.add(doc.data() as Map<String, dynamic>);
        }
      }
    }

    return backtestData;
  }

  void _showPerformanceExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Performance Metrics Explanation',
              style: GoogleFonts.robotoCondensed(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          content: Text(
            'MAE (Mean Absolute Error):\nThe average of the absolute differences between predicted and actual values.\n\n'
            'MSE (Mean Squared Error):\nThe average of the squared differences between predicted and actual values. Larger errors have a greater effect.\n\n'
            'R² (R-Squared):\nThe proportion of the variance in the dependent variable that is predictable from the independent variables. Closer to 1 means better fit.\n\n'
            'MAPE (Mean Absolute Percentage Error):\nThe average of the absolute percentage differences between predicted and actual values.',
            style: GoogleFonts.robotoCondensed(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close',
                  style: GoogleFonts.robotoCondensed(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAnalysisExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Analysis Metrics Explanation',
              style: GoogleFonts.robotoCondensed(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.robotoCondensed(
                    fontSize: 16, color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: 'EPS (Earnings Per Share):\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'The portion of a company\'s profit allocated to each outstanding share of common stock.\n\n',
                  ),
                  TextSpan(
                    text: 'Beta:\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'A measure of a stock\'s volatility in relation to the overall market. A beta less than 1 indicates lower volatility than the market.\n\n',
                  ),
                  TextSpan(
                    text: 'PE Ratio (Price to Earnings Ratio):\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'A valuation ratio of a company\'s current share price compared to its per-share earnings.\n\n',
                  ),
                  TextSpan(
                    text: 'Market Cap (Market Capitalization):\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'The total market value of a company\'s outstanding shares. It is calculated by multiplying the stock price by the total number of outstanding shares.\n\n',
                  ),
                  TextSpan(
                    text: 'Volatility:\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'The degree of variation of a trading price series over time. Lower volatility means the stock price is more stable.\n\n',
                  ),
                  TextSpan(
                    text: 'Trend Insight:\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'The overall direction of the market or a stock. An uptrend indicates the stock is generally moving higher, while a downtrend indicates it is moving lower.',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close',
                  style: GoogleFonts.robotoCondensed(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void refreshBacktestHistory() {
    setState(() {});
  }

  Future<void> _startBacktest({
    required String deployAlgoID,
    required String stockTicker,
    required DateTime backtestStartDate,
    required DateTime backtestEndDate,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backtesting...'),
      ),
    );

    var url = Uri.parse('http://10.0.2.2:5000/predict/$deployAlgoID');
    var headers = {'Content-Type': 'application/json'};
    var requestBody = jsonEncode({
      'stockSymbol': stockTicker,
      'startDate': formatDateWithTimezone(backtestStartDate,
          pattern: 'yyyy-MM-dd', isUtc: false),
      'backtestStartDate': formatDateWithTimezone(backtestStartDate,
          pattern: 'yyyy-MM-dd', isUtc: false),
      'backtestEndDate': formatDateWithTimezone(backtestEndDate,
          pattern: 'yyyy-MM-dd', isUtc: false),
    });

    try {
      var response = await http.post(url, headers: headers, body: requestBody);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        DocumentReference newAlgoRef =
            await FirebaseFirestore.instance.collection('backtest_algo').add({
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
          'bt_finalPortfolio': responseData["final_portfolio_value"],
          'bt_date': FieldValue.serverTimestamp(),
        });

        print('Response data added to database with ID: ${newAlgoRef.id}');

        String backtestResultId = newAlgoRef.id;
        print('New backtest result added with ID: $backtestResultId');

        DocumentReference backtestResultRef = FirebaseFirestore.instance
            .collection('backtest_algo')
            .doc(backtestResultId);

        var deployedAlgoRef = FirebaseFirestore.instance
            .collection('deployed_algo')
            .doc(widget.documentId);
        await deployedAlgoRef.update({
          'deploy_backtest': FieldValue.arrayUnion([backtestResultRef])
        });

        print('deploy_backtest field updated with new reference.');

        Provider.of<NotificationProvider>(context, listen: false)
            .showLocalNotification('Backtest Complete',
                'Backtest for $stockTicker completed successfully.');
        refreshBacktestHistory();
      } else {
        print('Request failed with status: ${response.statusCode}.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Backtest failed with status: ${response.statusCode}.'),
          ),
        );
      }
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color(0xFF0D0828),
        elevation: 0,
        title: Text(
          'Deploy Result',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: firestore
              .collection('deployed_algo')
              .doc(widget.documentId)
              .get(),
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
            List<DocumentReference> backtestRefs =
                (backtestdata['deploy_backtest'] as List)
                    .map((item) => item as DocumentReference)
                    .toList();

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
            final pointsPerMonth = 30;

            final screenWidth = MediaQuery.of(context).size.width;
            final graphWidth = screenWidth * 2;
            final double topPadding = 20;
            final maxYWithPadding = maxY + topPadding;

            final String deployName = data['deploy_algoName'];
            final String deployAlgoID = data['deploy_algoID'];
            final String deployTicker = data['deploy_stockTicker'];

            DateTime deployDate = (data['deploy_date'] as Timestamp).toDate();
            String formattedDeployedDate = formatDateWithTimezone(deployDate,
                pattern: 'dd/MM/yyyy hh:mm:ss a',
                isUtc: false,
                timezone: 'UTC+8');

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      child: Card(
                        elevation: 5,
                        shadowColor: Colors.grey.withOpacity(0.5),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 176, 168, 229),
                                Color(0xFFDADAE6)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$formattedDeployedDate',
                                    style: GoogleFonts.robotoCondensed(
                                        fontSize: 16, color: Colors.black)),
                                Center(
                                  child: Column(
                                    children: [
                                      Text('$deployTicker',
                                          style: GoogleFonts.robotoCondensed(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('$deployName',
                                            style: GoogleFonts.robotoCondensed(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation:
                          10, // Increased elevation for a more pronounced shadow
                      shadowColor:
                          Colors.grey.withOpacity(0.8), // Darker shadow
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Scroll horizontally to view the full graph',
                                style: GoogleFonts.robotoCondensed(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: graphWidth,
                                child: AspectRatio(
                                  aspectRatio: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10.0), // Add top padding here
                                    child: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 50,
                                              getTitlesWidget: (value, meta) {
                                                return _leftTitleWidgets(
                                                    value, meta);
                                              },
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 50,
                                              getTitlesWidget: (value, meta) {
                                                return _leftTitleWidgets(
                                                    value, meta);
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 32,
                                              getTitlesWidget: (value, meta) {
                                                int index = value.toInt();
                                                if (index < 0 ||
                                                    index >= dates.length)
                                                  return Container();
                                                String formattedDate =
                                                    DateFormat('MMM dd').format(
                                                        DateTime.parse(
                                                            dates[index]));
                                                return SideTitleWidget(
                                                  axisSide: meta.axisSide,
                                                  space: 8.0,
                                                  child: Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      color: Color(0xff67727d),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              },
                                              interval: (dates.length / 6)
                                                  .ceilToDouble(),
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                              color: const Color(0xff37434d),
                                              width: 1),
                                        ),
                                        minX: 0,
                                        maxX: (dates.length - 1).toDouble(),
                                        minY: minY,
                                        maxY: maxYWithPadding,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: actualDataPoints,
                                            isCurved: true,
                                            color: const Color.fromARGB(
                                                255, 44, 33, 243),
                                            barWidth: 2,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(show: false),
                                            belowBarData:
                                                BarAreaData(show: false),
                                          ),
                                          LineChartBarData(
                                            spots: predictedDataPoints,
                                            isCurved: true,
                                            color: const Color.fromARGB(
                                                255, 255, 13, 0),
                                            barWidth: 2,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(show: false),
                                            belowBarData:
                                                BarAreaData(show: false),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          touchTooltipData:
                                              LineTouchTooltipData(
                                            getTooltipItems: (List<LineBarSpot>
                                                touchedSpots) {
                                              return touchedSpots
                                                  .map((barSpot) {
                                                String date = dates[
                                                    barSpot.spotIndex.toInt()];
                                                String tooltipText =
                                                    'Date: $date\n';
                                                tooltipText += barSpot
                                                            .barIndex ==
                                                        0
                                                    ? 'Actual: ${barSpot.y.toStringAsFixed(2)}'
                                                    : 'Predicted: ${barSpot.y.toStringAsFixed(2)}';
                                                return LineTooltipItem(
                                                  tooltipText,
                                                  TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }).toList();
                                            },
                                          ),
                                          touchCallback: (FlTouchEvent event,
                                              LineTouchResponse?
                                                  touchResponse) {},
                                          handleBuiltInTouches: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                          color: const Color.fromARGB(255, 44, 33, 243),
                          text: 'Actual',
                          isSquare: false,
                        ),
                        SizedBox(width: 10),
                        Indicator(
                          color: const Color.fromARGB(255, 255, 13, 0),
                          text: 'Predicted',
                          isSquare: false,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Performance Metrics',
                                style: GoogleFonts.robotoCondensed(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.help_outline),
                              onPressed: () {
                                _showPerformanceExplanationDialog(context);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: <Widget>[
                            PerformanceMetricCard(
                              title: 'MAE (Mean Absolute Error)',
                              value: data['deploy_MAE'],
                              lowThreshold: 5,
                              highThreshold: 10,
                              cardColor: Color(0xFFE0E8FC), // Light purple
                            ),
                            PerformanceMetricCard(
                              title: 'MSE (Mean Squared Error)',
                              value: data['deploy_MSE'],
                              lowThreshold: 10,
                              highThreshold: 40,
                              cardColor: Color(0xFFFFE5BC), // Light yellow
                            ),
                            PerformanceMetricCard(
                              title: 'R² (R-Squared)',
                              value: data['deploy_R2'],
                              lowThreshold: 0.7,
                              highThreshold: 0.9,
                              cardColor: Color(0xFFFFE2E5), // Light pink
                            ),
                            PerformanceMetricCard(
                              title: 'MAPE (Mean Absolute Percentage Error)',
                              value: data['deploy_MAPE'],
                              lowThreshold: 5,
                              highThreshold: 15,
                              cardColor: Color(0xFFE5F7F9), // Light blue
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Analysis Metrics',
                                style: GoogleFonts.robotoCondensed(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.help_outline),
                              onPressed: () {
                                _showAnalysisExplanationDialog(context);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Table(
                          columnWidths: {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              children: [
                                Column(
                                  children: [
                                    AnalysisMetricCard(
                                      title: 'EPS',
                                      value: data['deploy_EPS'] ?? 0,
                                      goodThreshold: 2,
                                      badThreshold: 1,
                                      cardColor:
                                          Color(0xFFE0E8FC), // Light purple
                                    ),
                                    AnalysisMetricCard(
                                      title: 'Market Cap',
                                      value: formatMarketCap(
                                              data['deploy_marketCap']) ??
                                          0,
                                      goodThreshold: 200e9,
                                      badThreshold: 10e9,
                                      cardColor:
                                          Color(0xFFE5F7F9), // Light blue
                                    ),
                                    AnalysisMetricCard(
                                      title: 'Beta',
                                      value: data['deploy_beta'] ?? 0,
                                      goodThreshold: 1,
                                      badThreshold: 2,
                                      cardColor:
                                          Color(0xFFFFE5BC), // Light yellow
                                    ),
                                  ],
                                ),
                                AnalysisMetricCard(
                                  title: 'PE Ratio',
                                  value: data['deploy_peRatio'] ?? 0,
                                  goodThreshold: 15,
                                  badThreshold: 25,
                                  cardColor: Color(0xFFFFE2E5), // Light pink
                                  imagePath:
                                      'assets/images/peratio.png', // Add appropriate image path here
                                  isTall: true,
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                AnalysisMetricCard(
                                  title: 'Volatility',
                                  value: data['deploy_volatility'] ?? 0,
                                  goodThreshold: 0.5,
                                  badThreshold: 2,
                                  cardColor: Color(0xFFE0E8FC), // Light purple
                                  imagePath:
                                      'assets/images/volatility.png', // Add appropriate image path here
                                  isTall: true,
                                ),
                                Column(
                                  children: [
                                    AnalysisMetricCard(
                                      title: 'Trend Insight (7 days)',
                                      value:
                                          data['deploy_trendInsight7D'] ?? '',
                                      goodThreshold: 'Uptrend',
                                      badThreshold: 'Downtrend',
                                      cardColor:
                                          Color(0xFFFFE5BC), // Light yellow
                                      isTrend: true,
                                    ),
                                    AnalysisMetricCard(
                                      title: 'Trend Insight (30 days)',
                                      value:
                                          data['deploy_trendInsight30D'] ?? '',
                                      goodThreshold: 'Uptrend',
                                      badThreshold: 'Downtrend',
                                      cardColor:
                                          Color(0xFFFFE2E5), // Light pink
                                      isTrend: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
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
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            color: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.grey.withOpacity(0.5),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Center(
                                child: Text(
                                  'No backtest data available',
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        List<Map<String, dynamic>> backtests =
                            snapshot.data ?? [];
                        return Column(
                          children: backtests
                              .asMap()
                              .entries
                              .map((entry) => buildBacktestCard(context,
                                  entry.value, entry.key, deployTicker))
                              .toList(),
                        );
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return BacktestDialog(
                                deployStartDateTimestamp:
                                    data['deploy_startDate'],
                                deployEndDateTimestamp: data['deploy_date'],
                                stockTicker: deployTicker,
                                deployAlgoID: deployAlgoID,
                                documentId: widget.documentId,
                                isBacktest: false,
                              );
                            },
                          );

                          if (result != null && result['isBacktest']) {
                            final backtestStartDate =
                                result['backtestStartDate'];
                            final backtestEndDate = result['backtestEndDate'];
                            await _startBacktest(
                              deployAlgoID: deployAlgoID,
                              stockTicker: deployTicker,
                              backtestStartDate: backtestStartDate,
                              backtestEndDate: backtestEndDate,
                            );
                          }
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
                          backgroundColor: Color(0xFF0D0828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  )
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
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.5),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          title: Text('Backtest ${index + 1}',
              style: GoogleFonts.robotoCondensed(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text('Period: $formattedStartDate - $formattedEndDate',
              style: GoogleFonts.robotoCondensed(
                  fontSize: 14, fontWeight: FontWeight.normal)),
          trailing: Text(formattedBtDate,
              style: GoogleFonts.robotoCondensed(
                  fontSize: 14, fontWeight: FontWeight.normal)),
        ),
      ),
    );
  }

  String formatDateWithTimezone(DateTime date,
      {String? pattern, bool isUtc = false, String timezone = 'UTC+8'}) {
    DateFormat formatter = DateFormat(pattern ?? 'dd/MM/yyyy hh:mm:ss a');
    DateTime localDate = isUtc ? date.toUtc() : date;
    if (timezone == 'UTC+8') {
      localDate = localDate.add(Duration(hours: 8));
    }
    return formatter.format(localDate);
  }
}

class BacktestDialog extends StatefulWidget {
  final Timestamp deployStartDateTimestamp;
  final Timestamp deployEndDateTimestamp;
  final String stockTicker;
  final String deployAlgoID;
  final String documentId;
  bool isBacktest;

  BacktestDialog({
    required this.deployStartDateTimestamp,
    required this.deployEndDateTimestamp,
    required this.stockTicker,
    required this.deployAlgoID,
    required this.documentId,
    required this.isBacktest,
  });

  @override
  _BacktestDialogState createState() => _BacktestDialogState();
}

class _BacktestDialogState extends State<BacktestDialog> {
  late DateTime deployStartDate;
  late DateTime deployEndDate;
  late DateTime backtestStartDate;
  late DateTime backtestEndDate;

  @override
  void initState() {
    super.initState();
    deployStartDate = widget.deployStartDateTimestamp.toDate().toLocal();
    deployEndDate = widget.deployEndDateTimestamp.toDate().toLocal();
    backtestStartDate = deployStartDate;
    backtestEndDate = deployEndDate;
  }

  String formatDateWithTimezone(DateTime date,
      {String? pattern, bool isUtc = false, String timezone = 'UTC+8'}) {
    DateFormat formatter = DateFormat(pattern ?? 'dd/MM/yyyy hh:mm:ss a');
    DateTime localDate = isUtc ? date.toUtc() : date;
    if (timezone == 'UTC+8') {
      localDate = localDate.add(Duration(hours: 8));
    }
    return formatter.format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Backtest Period',
          style: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.bold, fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
                setState(() {
                  backtestStartDate = pickedStartDate;
                });
              }
            },
          ),
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
              if (pickedEndDate != null && pickedEndDate != backtestEndDate) {
                setState(() {
                  backtestEndDate = pickedEndDate;
                });
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop({
                'isBacktest': false,
              }); // Return false on cancel
            }
          },
        ),
        TextButton(
          child: Text('Backtest Now'),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop({
                'isBacktest': true,
                'backtestStartDate': backtestStartDate,
                'backtestEndDate': backtestEndDate,
              }); // Return true with dates on backtest now
            }
          },
        ),
      ],
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
            style: GoogleFonts.robotoCondensed(
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
  final Color cardColor;

  PerformanceMetricCard({
    required this.title,
    required this.value,
    required this.lowThreshold,
    required this.highThreshold,
    required this.cardColor,
  });

  Color _determineValueColor() {
    if (value <= lowThreshold) {
      return Colors.green;
    } else if (value > highThreshold) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: cardColor.darker(0.2), // Darker border color
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.robotoCondensed(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${value.toStringAsFixed(2)}%',
                  style: GoogleFonts.robotoCondensed(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _determineValueColor()),
                ),
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
  final Color cardColor;
  final String? imagePath;
  final bool isTall;
  final bool isTrend;

  AnalysisMetricCard({
    required this.title,
    required this.value,
    required this.goodThreshold,
    required this.badThreshold,
    required this.cardColor,
    this.imagePath,
    this.isTall = false,
    this.isTrend = false,
  });

  Color _determineValueColor() {
    if (value is num) {
      num numValue = value as num;
      num numGoodThreshold = goodThreshold as num;
      num numBadThreshold = badThreshold as num;
      if (numValue <= numGoodThreshold) {
        return Colors.green;
      } else if (numValue >= numBadThreshold) {
        return Colors.red;
      } else {
        return Colors.green;
      }
    } else if (value is String) {
      return value == goodThreshold ? Colors.green : Colors.red;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    String displayValue;
    if (value is num) {
      displayValue = (value as num).toStringAsFixed(3);
    } else {
      displayValue = value.toString();
    }
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: cardColor.darker(0.2), // Darker border color
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(title,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: isTall
                ? null
                : isTrend
                    ? null
                    : Text(displayValue,
                        style: GoogleFonts.robotoCondensed(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _determineValueColor())),
          ),
          if (isTall && imagePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: 60, // Adjust the width as needed
                      height: 90, // Adjust the height as needed
                      child: Image.asset(imagePath!),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Center(
                    child: Text(displayValue,
                        style: GoogleFonts.robotoCondensed(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _determineValueColor())),
                  ),
                ],
              ),
            ),
          if (isTrend)
            Center(
              child: Text(displayValue,
                  style: GoogleFonts.robotoCondensed(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _determineValueColor())),
            ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darker([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
