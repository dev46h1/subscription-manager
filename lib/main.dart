import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service with proper error handling
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Request notification permissions
    final permissionGranted = await notificationService.requestPermissions();
    if (!permissionGranted) {
      print('Notification permissions not granted');
    }
    
    print('Notification service initialized successfully');
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