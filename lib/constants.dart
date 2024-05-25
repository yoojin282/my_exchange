final Uri apiUrl = Uri.parse(
    'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON');
const List<String> availableUnits = ['THB', 'USD', "JPY(100)"];
const List<String> availableLanguage = ['KO', 'TH', "EN"];
const shortcuts = [20, 100, 500, 1000, 5000];
const reverseShortcuts = [1000, 5000, 10000, 50000, 100000];

abstract class Constants {
  static const String apiKey =
      String.fromEnvironment('API_KEY', defaultValue: "");
}
