import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BacktestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> backtestData;
  final String stockTicker; // Declare the variable in the class

  // Modify the constructor to accept the new argument
  BacktestDetailsPage({
    Key? key,
    required this.backtestData,
    required this.stockTicker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Data parsing and formatting, make sure to use your actual keys from the map
    DateTime startDate = DateTime.parse(backtestData['bt_startDate']);
    DateTime endDate = DateTime.parse(backtestData['bt_endDate']);
    double finalPortfolioValue = backtestData['bt_finalPortfolio'];
    double sharpRatio = backtestData['bt_sharpeRatio'];
    double drawdown = backtestData['bt_drawdown'];
    double annualReturn = backtestData['bt_annualReturn'];
    int totalTrades = backtestData['bt_totalTrade'];
    double winRate = backtestData['bt_winRate'] != null
        ? (backtestData['bt_winRate'] as num).toDouble() * 100
        : 0.0;
    double lossRate = backtestData['bt_lossRate'] != null
        ? (backtestData['bt_lossRate'] as num).toDouble() * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        title: Text('Backtest Result',
            style: GoogleFonts.robotoCondensed(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Card(
                        color: Colors.white, // White background color
                        margin: EdgeInsets.all(8.0), // Margin around the card
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 8.0,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 40), // Adjusted for button space
                              Text(
                                stockTicker,
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'Initial Portfolio Value: 10,000',
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              MetricCard(
                                title: 'Final Portfolio Value',
                                value: finalPortfolioValue.toStringAsFixed(2),
                                color: getColorForFinalPortfolioValue(
                                    finalPortfolioValue),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Sharpe Ratio',
                                      value: sharpRatio.toStringAsFixed(2),
                                      color: getColorForSharpeRatio(sharpRatio),
                                    ),
                                  ),
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Drawdown',
                                      value: drawdown.toStringAsFixed(2),
                                      color: getColorForDrawdown(drawdown),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Annual Return',
                                      value: annualReturn.toStringAsFixed(2),
                                      color:
                                          getColorForAnnualReturn(annualReturn),
                                    ),
                                  ),
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Total Trades',
                                      value: totalTrades.toStringAsFixed(0),
                                      color: Color.fromARGB(255, 196, 212,
                                          237), // Default color for integer value
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Win Rate',
                                      value: winRate.toStringAsFixed(2),
                                      color: getColorForWinRate(winRate),
                                    ),
                                  ),
                                  Expanded(
                                    child: MetricCard(
                                      title: 'Loss Rate',
                                      value: lossRate.toStringAsFixed(2),
                                      color: getColorForLossRate(lossRate),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.help_outline),
                          onPressed: () {
                            showExplanationDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Explanation of Terms'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Sharpe Ratio: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'A measure of risk-adjusted return.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Drawdown: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'The peak-to-trough decline during a specific period.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Annual Return: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'The yearly profit or loss percentage.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Total Trades: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'The total number of trades executed.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Win Rate: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'The percentage of profitable trades.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Loss Rate: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'The percentage of unprofitable trades.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Final Portfolio Value: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'The total value of the portfolio at the end of the backtest.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color getColorForFinalPortfolioValue(double value) {
    if (value > 10000) return Color.fromARGB(255, 189, 225, 188);
    if (value < 10000) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }

  Color getColorForSharpeRatio(double value) {
    if (value > 1) return Color.fromARGB(255, 189, 225, 188);
    if (value < 0) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }

  Color getColorForDrawdown(double value) {
    if (value < 10) return Color.fromARGB(255, 189, 225, 188);
    if (value > 20) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }

  Color getColorForAnnualReturn(double value) {
    if (value > 0) return Color.fromARGB(255, 189, 225, 188);
    if (value < 0) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }

  Color getColorForWinRate(double value) {
    if (value > 50) return Color.fromARGB(255, 189, 225, 188);
    if (value < 50) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }

  Color getColorForLossRate(double value) {
    if (value < 50) return Color.fromARGB(255, 189, 225, 188);
    if (value > 50) return Color.fromARGB(255, 237, 196, 196);
    return Color.fromARGB(255, 231, 237, 196);
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const MetricCard(
      {Key? key, required this.title, required this.value, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: color,
        margin: EdgeInsets.all(8.0), // Set your desired color for the card here
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the value
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 16, fontWeight: FontWeight.normal),
              ),
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.robotoCondensed(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatPercentage(double? value) {
  if (value == null) return 'N/A';
  return '${(value * 100).toStringAsFixed(2)}%';
}
