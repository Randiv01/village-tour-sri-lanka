import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'repositories/share_repository.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/homestays/homestay_details_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _deepLinkChannel = MethodChannel(
    'com.example.village_tour_sri_lanka/deeplink',
  );

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();
  }

  Future<void> _setupDeepLinkHandling() async {
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          await _processReferralLink(link);
        }
      }
    });

    try {
      final initialLink = await _deepLinkChannel.invokeMethod<String>(
        'getInitialLink',
      );
      if (initialLink != null && initialLink.isNotEmpty) {
        // Wait briefly for splash/Firebase initialization before handling initial deep link
        await Future.delayed(const Duration(milliseconds: 2200));
        await _processReferralLink(initialLink);
      }
    } catch (_) {}
  }

  Future<void> _processReferralLink(String rawLink) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final result = await ShareRepository().handleIncomingReferralLink(
        rawLink,
      );
      if (result == null) return;

      final title = result['homestayTitle'] ?? 'Village Homestay';
      final hId = result['homestayId'] ?? 'explore';

      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Referral link clicked! +1 click recorded for "$title".',
          ),
          backgroundColor: Colors.green[800],
        ),
      );

      if (hId.isNotEmpty && hId != 'explore' && hId != 'general_referral') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => HomestayDetailsScreen(homestayId: hId),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village Tour Sri Lanka',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
