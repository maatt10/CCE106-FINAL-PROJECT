import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.frankfurter.dev/v2';

  // Stores rates we've already fetched during this app session.
  final Map<String, double> _rateCache = {};

  Future<double> getRate(String from, String to) async {
    from = from.toUpperCase();
    to = to.toUpperCase();

    // Same currency = no conversion needed.
    if (from == to) {
      return 1.0;
    }

    final cacheKey = '$from-$to';

    // Use cached rate if we've already requested it.
    if (_rateCache.containsKey(cacheKey)) {
      return _rateCache[cacheKey]!;
    }

    final url = Uri.parse(
      '$_baseUrl/rate/$from/$to',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get exchange rate: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final rate = (data['rate'] as num).toDouble();

    _rateCache[cacheKey] = rate;

    return rate;
  }

  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rate = await getRate(from, to);

    return amount * rate;
  }

  void clearCache() {
    _rateCache.clear();
  }
}