import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/screen/home_page.dart';
import 'package:my_exchange/theme.dart';

Future<void> main() async {
  initializeGetIt();
  // HttpOverrides.global = NoCheckCerfiticationHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final data = await PlatformAssetBundle().load('certs/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '환율정보',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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

// class NoCheckCerfiticationHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (cert, host, port) => true;
//   }
// }
