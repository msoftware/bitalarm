import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class API {
  static Future<Map<String, double>> getETHWalletValue(String address) async {
    String endpoint = 'https://api.ethplorer.io/getAddressInfo/$address?apiKey=freekey';
    Map<String, double> values = {};
    Map<String, dynamic> data =  await JSON.decode((await http.get(endpoint)).body);
    if (data['ETH'] != null && data['ETH'].containsKey('balance')) {
      values['ETH'] = data['ETH']['balance'];
    }
    List<Object> tokens = data['tokens'];
    if (tokens == null) {
      return values;
    }
    tokens.forEach((Object token) {
      int decimals = token['tokenInfo']['decimals'] is num ? token['tokenInfo']['decimals'] : int.parse(token['tokenInfo']['decimals'], radix: 10);
      values[token['tokenInfo']['symbol']] = (token['balance'] / pow(10, decimals));
    });
    return values;
  }

  static Future<double> getGenericWalletValue(String symbol, String address) async {
    String endpoint = "https://api.blockcypher.com/v1/${symbol.toLowerCase()}/main/addrs/$address/balance";
    if (symbol == 'BCH') {
      endpoint = 'https://blockdozer.com/insight-api/addr/$address/balance';
      String res = (await http.get(endpoint)).body;
      return double.parse(res) / pow(10, 8);
    } else {
      Map<String, dynamic> data = await JSON.decode((await http.get(endpoint)).body);
      return data['balance'] / pow(10, 8);
    }
  }

  static Future<double> getADAWalletValue(String address) async {
    String endpoint = 'https://cardanoexplorer.com/api/addresses/summary/$address';
    Map<String, dynamic> data = await JSON.decode((await http.get(endpoint)).body);
    double amount = double.parse(data['Right']['caBalance']['getCoin']);
    return amount / pow(10, 6);
  }

  static Future<List<Object>> getPrices({List<String> filter = const [], String currency = 'USD'}) async {
    String endpoint = 'https://api.coinmarketcap.com/v1/ticker/?convert=$currency';
    List<Object> list = JSON.decode((await http.get(endpoint)).body);
    if (filter.length == 0) {
      return list;
    } else {
      return list
        .where((Object coin) => filter.indexOf(coin['symbol']) >= 0)
        .toList();
    }
  }

  static Future<List<Map<String, dynamic>>> getHistorical(String ticker) async {
    String endpoint = 'https://api.cryptowat.ch/markets/bitfinex/' + ticker + 'usd/ohlc';
    Object response;
    try {
      response = JSON.decode((await http.get(endpoint)).body);
    } catch (e) {
      endpoint = 'https://api.cryptowat.ch/markets/poloniex/' + ticker + 'btc/ohlc';
      response = JSON.decode((await http.get(endpoint)).body);
    }
    List<List<double>> data = response['result']['1800'];
    List<Map<String, dynamic>> close = data
      .map((List<num> point) => {
        'time': new DateTime.fromMillisecondsSinceEpoch(point[0] * 1000).toString(),
        'value': point[4] * 1.0
      })
      .toList();
    return close;
  }

  static Future<Map<String, List<List<double>>>> getOrderbook(
    String ticker) async {
    String endpoint = 'https://api.cryptowat.ch/markets/bitfinex/' + ticker + 'usd/orderbook';
    Object res = JSON.decode((await http.get(endpoint)).body);
    List<List<double>> asks = res['result']['asks'];
    List<List<double>> bids = res['result']['bids'];
    return {
      'asks': asks.sublist(0, 20),
      'bids': bids.sublist(0, 20),
    };
  }
}
