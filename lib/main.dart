import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:my_exchange/firebase_options.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/screen/home_screen.dart';
import 'package:my_exchange/theme.dart';

Future<void> main() async {
  initializeGetIt();
  if (kDebugMode) {
    Logger.level = Level.debug;
  } else {
    Logger.level = Level.warning;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // final data = await PlatformAssetBundle().load('certs/lets-encrypt-r3.pem');
  // SecurityContext.defaultContext
  //     .setTrustedCertificatesBytes(data.buffer.asUint8List());
  // HttpOverrides.global = NoCheckCerfiticationHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const pageTransitionBuilder = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    );

    return MaterialApp(
      title: '환율정보',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: pageTransitionBuilder,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: pageTransitionBuilder,
      ),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          ),
      home: const MainScreen(),
    );
  }
}
