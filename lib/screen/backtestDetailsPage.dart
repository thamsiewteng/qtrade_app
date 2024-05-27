import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qtrade_app/screen/deployedAlgoDetailsPage.dart';

class BacktestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> backtestData;
  final String stockTicker;

  BacktestDetailsPage({
    Key? key,
    required this.backtestData,
    required this.stockTicker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime startDate =
        DateTime.tryParse(backtestData['bt_startDate'] ?? '') ?? DateTime.now();
    DateTime endDate =
        DateTime.tryParse(backtestData['bt_endDate'] ?? '') ?? DateTime.now();
    double finalPortfolioValue = backtestData['bt_finalPortfolio'] != null
        ? (backtestData['bt_finalPortfolio'] as num).toDouble()
        : 0.0;
    double sharpeRatio = backtestData['bt_sharpeRatio'] != null
        ? (backtestData['bt_sharpeRatio'] as num).toDouble()
        : 0.0;
    double drawdown = backtestData['bt_drawdown'] != null
        ? (backtestData['bt_drawdown'] as num).toDouble()
        : 0.0;
    double annualReturn = backtestData['bt_annualReturn'] != null
        ? (backtestData['bt_annualReturn'] as num).toDouble()
        : 0.0;
    int totalTrades = backtestData['bt_totalTrade'] != null
        ? (backtestData['bt_totalTrade'] as num).toInt()
        : 0;
    double winRate = backtestData['bt_winRate'] != null
        ? (backtestData['bt_winRate'] as num).toDouble() * 100
        : 0.0;
    double lossRate = backtestData['bt_lossRate'] != null
        ? (backtestData['bt_lossRate'] as num).toDouble() * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color(0xFF0D0828),
        title: Text('Backtest Result',
            style: GoogleFonts.robotoCondensed(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: ConstrainedBox(
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
                              color: Color(0xFFE5F7F9), // Light green color
                              valueColor: getColorForFinalPortfolioValue(
                                  finalPortfolioValue),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: MetricCard(
                                    title: 'Sharpe Ratio',
                                    value: sharpeRatio.toStringAsFixed(2),
                                    color:
                                        Color(0xFFE5F7F9), // Light pink color
                                    valueColor:
                                        getColorForSharpeRatio(sharpeRatio),
                                  ),
                                ),
                                Expanded(
                                  child: MetricCard(
                                    title: 'Drawdown',
                                    value: drawdown.toStringAsFixed(2),
                                    color:
                                        Color(0xFFE5F7F9), // Light green color
                                    valueColor: getColorForDrawdown(drawdown),
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
                                    color: Color(0xFFE5F7F9),
                                    valueColor:
                                        getColorForAnnualReturn(annualReturn),
                                  ),
                                ),
                                Expanded(
                                  child: MetricCard(
                                    title: 'Total Trades',
                                    value: totalTrades.toString(),
                                    color:
                                        Color(0xFFE5F7F9), // Light blue color
                                    valueColor: Colors
                                        .black, // Default color for integer value
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
                                    color:
                                        Color(0xFFE5F7F9), // Light green color
                                    valueColor: getColorForWinRate(winRate),
                                  ),
                                ),
                                Expanded(
                                  child: MetricCard(
                                    title: 'Loss Rate',
                                    value: lossRate.toStringAsFixed(2),
                                    color: Color(0xFFE5F7F9),
                                    valueColor: getColorForLossRate(lossRate),
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
    if (value > 10000) return Colors.green;
    if (value < 10000) return Colors.red;
    return Colors.black;
  }

  Color getColorForSharpeRatio(double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Colors.black;
  }

  Color getColorForDrawdown(double value) {
    if (value < 10) return Colors.green;
    if (value > 20) return Colors.red;
    return Colors.black;
  }

  Color getColorForAnnualReturn(double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Colors.black;
  }

  Color getColorForWinRate(double value) {
    if (value > 50) return Colors.green;
    if (value < 50) return Colors.red;
    return Colors.black;
  }

  Color getColorForLossRate(double value) {
    if (value < 50) return Colors.green;
    if (value > 50) return Colors.red;
    return Colors.black;
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color valueColor;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 5,
        color: color,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: color.darker(0.2), // Darker border color
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the value
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.robotoCondensed(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: valueColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
