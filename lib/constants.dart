import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

const apiHost = 'api.apilayer.com';
const baseUnit = 'KRW';
const availableUnits = ['THB', 'USD'];
const availableLanguage = ['KO', 'TH', "EN"];
const shortcuts = [20, 100, 500, 1000, 5000];
const reverseShortcuts = [1000, 5000, 10000, 50000, 100000];
final dateFormat = DateFormat('yyyy-MM-dd');
final logger = Logger();

abstract class Constants {
  static const apiKey = String.fromEnvironment('API_KEY', defaultValue: "");
}
