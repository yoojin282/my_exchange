import 'package:get_it/get_it.dart';
import 'package:my_exchange/repository/exchange_repository.dart';

final getIt = GetIt.instance;

void initializeGetIt() {
  getIt.registerSingleton(ExchangeRepository());
}
