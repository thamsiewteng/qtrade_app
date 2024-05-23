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

  // This widget is the root of your application.
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
