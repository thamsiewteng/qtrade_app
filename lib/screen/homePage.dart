import 'package:flutter/material.dart';
import '/../services/stockDataService.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StockDataService _service =
      StockDataService('Va6ZpCSsBaQBm4Iik2WF3rXxEGK5UWkO');
  final List<String> _tickers = ['AAPL', 'AMZN', 'TSLA'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stock Data"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _tickers.length,
        itemBuilder: (context, index) {
          return FutureBuilder<List<Stock>>(
            future: _service.getAggregateBars(
                _tickers[index], 'day', '2024-01-01', '2024-01-02'),
            builder:
                (BuildContext context, AsyncSnapshot<List<Stock>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return ListTile(
                  title: Text('Error'),
                  subtitle: Text(snapshot.error.toString()),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                // Ensure we have data and it's not empty before accessing the last element
                Stock stock = snapshot.data!.last;
                return ListTile(
                  title: Text(stock.ticker),
                  subtitle: Text('\$${stock.price.toStringAsFixed(2)}'),
                  trailing: Text('${stock.change.toStringAsFixed(2)}%'),
                );
              } else {
                return ListTile(
                  title: Text('No data'),
                  subtitle:
                      Text('No data available for ticker ${_tickers[index]}.'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
