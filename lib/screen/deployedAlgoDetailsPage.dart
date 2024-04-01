import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math' as math;

class DeployedAlgoDetailsPage extends StatelessWidget {
  final String documentId;

  DeployedAlgoDetailsPage({required this.documentId});

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'Details',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white,
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

            var data = snapshot.data!.data() as Map<String, dynamic>;
            String graphDataString = data['deploy_graph'];
            Map<String, dynamic> graphData = jsonDecode(graphDataString);

            List<String> dates = List<String>.from(graphData['dates']);

            List<double> actual = List<double>.from(
                graphData['actual'].map((x) => x.toDouble()).toList());
            List<double> predicted = List<double>.from(
                graphData['predicted'].map((x) => x.toDouble()).toList());

            List<FlSpot> actualDataPoints = List.generate(actual.length,
                (index) => FlSpot(index.toDouble(), actual[index]));
            List<FlSpot> predictedDataPoints = List.generate(predicted.length,
                (index) => FlSpot(index.toDouble(), predicted[index]));

            final minY = actual.reduce(math.min) * 0.9;
            final maxY = actual.reduce(math.max) * 1.1;
            final pointsPerMonth = 30; // Adjust this value as needed

// Before returning SingleChildScrollView, calculate the scaling for the graph width
            final screenWidth = MediaQuery.of(context).size.width;
            final graphWidth = screenWidth *
                2; // Adjust the scaling factor as needed to fit the graph
            final double topPadding =
                20; // Additional top padding for the highest price
            final maxYWithPadding = maxY + topPadding;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Test Set: Actual vs Predicted',
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
                            color: Colors
                                .white, // Set the background color for the chart area
                            borderRadius: BorderRadius.circular(
                                15), // Optional for rounded corners
                          ),
                          padding: const EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ), // This will hide the top titles
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
                                        // children: <TextSpan>[
                                        //   if (isTouchedActual) // Add the circle only for the actual value
                                        //     TextSpan(
                                        //       text: ' ● ',
                                        //       style: TextStyle(
                                        //         fontSize: 14,
                                        //         color: Colors
                                        //             .blue, // Circle color for actual value
                                        //       ),
                                        //     ),
                                        //   if (!isTouchedActual) // Add the circle only for the predicted value
                                        //     TextSpan(
                                        //       text: ' ● ',
                                        //       style: TextStyle(
                                        //         fontSize: 14,
                                        //         color: Colors
                                        //             .orange, // Circle color for predicted value
                                        //       ),
                                        //     ),
                                        // ],
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
                            // _buildPerformanceMetricsCard(data),
                            Text('Performance Metrics',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(height: 10),
                            performanceMetricItem(
                                'MAE: ', data['deploy_MAE'].toStringAsFixed(2)),
                            performanceMetricItem(
                                'MSE: ', data['deploy_MSE'].toStringAsFixed(2)),
                            performanceMetricItem(
                                'R²: ', data['deploy_R2'].toStringAsFixed(2)),
                            performanceMetricItem('MAPE: ',
                                data['deploy_MAPE'].toStringAsFixed(2)),
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
                            Text('Analysis',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(height: 10),
                            // ... Add additional metrics here ...
                            performanceMetricItem(
                                'EPS: ', data['deploy_EPS'].toString()),
                            performanceMetricItem(
                                'Beta: ', data['deploy_beta'].toString()),
                            performanceMetricItem('PE Ratio: ',
                                data['deploy_peRatio'].toString()),
                            performanceMetricItem('Market Cap: ',
                                formatMarketCap(data['deploy_marketCap'])),

                            performanceMetricItem('Volatility: ',
                                "${(double.parse(data['deploy_stockVolatility']) * 100).toStringAsFixed(2)}%"),
                            performanceMetricItem(
                                'Trend Insight: ', data['deploy_trendInsight']),
                          ],
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

  // void _showPerformanceMetricsExplanation(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Performance Metrics"),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text(
  //                   "1. MAE (Mean Absolute Error): ..."), // Your explanations here
  //               Text("2. MSE (Mean Squared Error): ..."),
  //               Text("3. R²: ..."),
  //               Text("4. MAPE (Mean Absolute Percentage Error): ..."),
  //               // Add more explanations as needed
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Widget _buildPerformanceMetricsCard(Map<String, dynamic> data) {
  //   return Card(
  //     elevation: 5,
  //     shadowColor: Colors.grey.withOpacity(0.5),
  //     margin: const EdgeInsets.all(16),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Performance Metrics',
  //                 style: GoogleFonts.robotoCondensed(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               IconButton(icon: Icon(Icons.help_outline), onPressed: () => ()
  //                   // _showPerformanceMetricsExplanation(
  //                   //     context as BuildContext),
  //                   )
  //             ],
  //           ),
  //           // Metrics are displayed here...
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget performanceMetricItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
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
