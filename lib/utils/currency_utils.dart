class CurrencyUtils {
  static const Map<String, String> symbols = {
    'PHP': '₱',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'KRW': '₩',
    'SGD': 'S\$',
    'AUD': 'A\$',
  };

  static String getSymbol(String currency) {
    return symbols[currency.toUpperCase()] ?? currency;
  }

  static String format(double amount, String currency) {
    final symbol = getSymbol(currency);

    return '$symbol${amount.toStringAsFixed(2)}';
  }
}