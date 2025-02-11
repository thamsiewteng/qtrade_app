import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qtrade_app/screen/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qtrade_app/services/notification_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID
    'High Importance Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(
    ChangeNotifierProvider(
      create: (context) => NotificationProvider(),
      child: MyApp(),
    ),
  );
}
// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MyApp());
//   //uploadSP500Data();
// }

// Future<void> uploadSP500Data() async {
//   final firestoreInstance = FirebaseFirestore.instance;
//   final sp500Collection = firestoreInstance.collection('sp500');

//   //Check if the collection already has data to avoid duplication
//   final existingData = await sp500Collection.limit(1).get();
//   if (existingData.size != 0) {
//     // Collection already has data, so we do not upload it again.
//     return;
//   }

//   try {
//     final csvData = await rootBundle.loadString('assets/data/sp500.csv');
//     List<List<dynamic>> rowsAsListOfValues =
//         const CsvToListConverter().convert(csvData);

//     // Assuming the long names are in column 2 (index 1).
//     List<dynamic> longCompanyNames =
//         rowsAsListOfValues.sublist(0).map((row) => row[3]).toList();

//     // Create a single document with an array of long company names.
//     await sp500Collection
//         .doc('companyNames')
//         .set({'companyNames': longCompanyNames});
//   } catch (e) {
//     // If there's an error, print it to the console or log to a file.
//     print('An error occurred while uploading data: $e');
//     // Optionally, you can rethrow the error or handle it as needed.
//   }
// }

// Future<void> uploadSP500Data() async {
//   // Load the CSV file from the Flutter assets
//   final String csvData = await rootBundle.loadString('assets/data/sp500.csv');
//   // Convert the CSV data to a List of Lists
//   List<List<dynamic>> rowsAsListOfValues =
//       const CsvToListConverter().convert(csvData);

//   // Extract the index of the 'Longname' column
//   final int symbolIndex = rowsAsListOfValues[0].indexOf('Symbol');

//   // Extract the 'Longname' values, skipping the header
//   List<String> symbol = rowsAsListOfValues
//       .sublist(1) // Skip header
//       .map((row) => row[symbolIndex].toString())
//       .toList();

//   // Get a reference to the Firestore instance
//   FirebaseFirestore db = FirebaseFirestore.instance;

//   // Write to the database
//   await db.collection('s&p500').doc('tickers').set({
//     'symbols': symbol,
//   });
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
