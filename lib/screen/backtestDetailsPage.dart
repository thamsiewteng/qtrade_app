import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qtrade_app/screen/algorithmDetailsPage.dart';

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
    // String stockSymbol = backtestData['stockSymbol'];
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
                  // ... Your other widgets ...

                  // Wrapping in a Card with a white background
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
                          SizedBox(height: 20),
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
                          MetricCard(
                            title: 'Final Portfolio Value',
                            value: finalPortfolioValue.toStringAsFixed(2),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Sharpe Ratio',
                                  value: sharpRatio.toStringAsFixed(2),
                                ),
                              ),
                              Expanded(
                                child: MetricCard(
                                  title: 'Drawdown',
                                  value: drawdown.toStringAsFixed(2),
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
                                ),
                              ),
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Trades',
                                  value: totalTrades.toStringAsFixed(0),
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
                                ),
                              ),
                              Expanded(
                                child: MetricCard(
                                  title: 'Loss Rate',
                                  value: lossRate.toStringAsFixed(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

class MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const MetricCard({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Color.fromARGB(255, 197, 200, 231),
        margin: EdgeInsets.all(8.0), // Set your desired color for the card here
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 16, fontWeight: FontWeight.normal),
              ),
              Text(
                value,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
