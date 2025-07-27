import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service with error handling
  try {
    await NotificationService().init();
  } catch (e) {
    print('Failed to initialize notifications: $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => SubscriptionProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}