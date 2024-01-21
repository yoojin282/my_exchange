import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/screen/home_page.dart';
import 'package:my_exchange/service/database_service.dart';

Future<void> main() async {
  initializeGetIt();
  WidgetsFlutterBinding.ensureInitialized();
  // TODO 여기 반드시 지우기
  if (kDebugMode) {
    await DatabaseService.provider.reset();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '환율정보',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: child!,
      ),
      home: const MainScreen(),
    );
  }
}
