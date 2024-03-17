import 'dart:convert';
import 'package:http/http.dart' as http;

class StockDataService {
  final String apiKey;

  StockDataService(this.apiKey);

  Future<List<Stock>> getAggregateBars(
      String ticker, String timespan, String from, String to) async {
    final url = Uri.parse(
        'https://api.polygon.io/v2/aggs/ticker/$ticker/range/1/$timespan/$from/$to?apiKey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> barsJson = json.decode(response.body)['results'];
      return barsJson.map((json) => Stock.fromJson(ticker, json)).toList();
    } else {
      // Here we are printing the status code and response body to the console
      print('Request failed with status: ${response.statusCode}.');
      print('Response body: ${response.body}');
      throw Exception('Failed to load stock data');
    }
  }
}

class Stock {
  final String ticker;
  final double price;
  final double change;

  Stock({required this.ticker, required this.price, required this.change});

  factory Stock.fromJson(String ticker, Map<String, dynamic> json) {
    return Stock(
      ticker: ticker,
      price: json['c'].toDouble(),
      change: ((json['c'] - json['o']) / json['o']) * 100,
    );
  }
}
