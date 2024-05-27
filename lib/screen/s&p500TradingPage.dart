import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qtrade_app/screen/stockTradingPage.dart';
import 'package:qtrade_app/widgets/customBottomNavigationBar.dart';

class SP500TradingPage extends StatefulWidget {
  @override
  _SP500TradingPageState createState() => _SP500TradingPageState();
}

class _SP500TradingPageState extends State<SP500TradingPage> {
  late Future<List<String>> futureTickers;
  late Future<List<String>> futureCompanyNames;
  late Future<List<StockInfo>> futureStocks;
  List<String> allTickers = [];
  List<String> allCompanyNames = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureStocks = fetchStockData();
    futureTickers = fetchTickers();
    futureCompanyNames = fetchCompanyNames();
  }

  Future<List<StockInfo>> fetchStockData() async {
    return await StockService().fetchStocks();
  }

  Future<List<String>> fetchTickers() async {
    var collection = FirebaseFirestore.instance.collection('s&p500');
    var tickersSnapshot = await collection.doc('tickers').get();
    if (tickersSnapshot.exists && tickersSnapshot.data() != null) {
      allTickers = List.from(tickersSnapshot.data()!['symbols']);
      return allTickers;
    } else {
      throw Exception('Failed to load tickers');
    }
  }

  Future<List<String>> fetchCompanyNames() async {
    var collection = FirebaseFirestore.instance.collection('s&p500');
    var companyNamesSnapshot = await collection.doc('companyName').get();
    if (companyNamesSnapshot.exists && companyNamesSnapshot.data() != null) {
      allCompanyNames = List.from(companyNamesSnapshot.data()!['companyNames']);
      return allCompanyNames;
    } else {
      throw Exception('Failed to load company names');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color(0xFF0D0828),
        elevation: 0,
        title: Text(
          'S&P 500 Trading',
          style: GoogleFonts.robotoCondensed(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Material(
                elevation: 4.0,
                shadowColor: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    } else {
                      var searchText = textEditingValue.text.toLowerCase();
                      return allCompanyNames.where((allCompanyNames) =>
                          allCompanyNames.toLowerCase().startsWith(searchText));
                    }
                  },
                  onSelected: (String selection) {
                    debugPrint('You selected: $selection');
                    int index = allCompanyNames.indexWhere((name) =>
                        name.trim().toLowerCase() ==
                        selection.trim().toLowerCase());
                    if (index != -1) {
                      debugPrint('Index found: $index');
                      String tickerSymbol = allTickers[index];
                      debugPrint(
                          'Ticker symbol for selected company is: $tickerSymbol');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StockTradingPage(tickerSymbol: tickerSymbol),
                        ),
                      );
                    } else {
                      debugPrint(
                          'Index not found for the company name: $selection');
                    }
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      style: GoogleFonts.robotoCondensed(),
                      decoration: InputDecoration(
                        hintText: 'Search assets',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<StockInfo>>(
                future: futureStocks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No stock data available'));
                  } else {
                    var filteredStocks = snapshot.data!
                        .where((stock) =>
                            stock.ticker.toLowerCase().contains(
                                searchController.text.toLowerCase()) ||
                            stock.companyName
                                .toLowerCase()
                                .contains(searchController.text.toLowerCase()))
                        .toList();

                    return ListView.builder(
                      itemCount: filteredStocks.length,
                      itemBuilder: (context, index) {
                        var stock = filteredStocks[index];
                        var trendImage = stock.changePercent >= 0
                            ? 'assets/images/trend_up.png'
                            : 'assets/images/trend_down.png';

                        return GestureDetector(
                          onTap: () {
                            debugPrint('filteredStocks[index].ticker');
                            debugPrint(filteredStocks[index].ticker);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StockTradingPage(
                                    tickerSymbol: filteredStocks[index].ticker),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            elevation: 4.0,
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stock.companyName,
                                          style: GoogleFonts.robotoCondensed(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Image.asset(
                                    trendImage,
                                    height: 20.0,
                                  ),
                                  SizedBox(width: 10),
                                  RichText(
                                    textAlign: TextAlign.right,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '\$${stock.currentPrice.toStringAsFixed(2)}\n',
                                          style: GoogleFonts.robotoCondensed(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
                                          style: GoogleFonts.robotoCondensed(
                                            color: stock.changePercent >= 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }
}

class StockService {
  Future<List<StockInfo>> fetchStocks() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/stocks_info'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, List<String>>{
        'tickers': [
          "AAPL",
          "MMM",
          "AOS",
          "GOOGL",
          "AMZN",
          "MSFT",
          "MCD",
          "NFLX",
          "BIG",
        ]
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> stockDataList = jsonDecode(response.body);
      return stockDataList
          .map((stockData) => StockInfo.fromJson(stockData))
          .toList();
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  Future<List<String>> fetchCompanyNames() async {
    var collection = FirebaseFirestore.instance.collection('s&p500');
    var docSnapshot = await collection.doc('companyName').get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      List<String> companyNames =
          List.from(docSnapshot.data()!['companyNames']);
      return companyNames;
    } else {
      throw Exception('Failed to load company names');
    }
  }

  Future<List<String>> fetchTickers() async {
    var collection = FirebaseFirestore.instance.collection('s&p500');
    var docSnapshot = await collection.doc('tickers').get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      List<String> tickers = List.from(docSnapshot.data()!['tickers']);
      return tickers;
    } else {
      throw Exception('Failed to load tickers');
    }
  }
}

class StockInfo {
  final String ticker;
  final String companyName;
  final double currentPrice;
  final double changePercent;

  StockInfo({
    required this.ticker,
    required this.companyName,
    required this.currentPrice,
    required this.changePercent,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      ticker: json['ticker'],
      companyName: json['companyName'],
      currentPrice: json['currentPrice'].toDouble(),
      changePercent: json['changePercent'].toDouble(),
    );
  }
}
