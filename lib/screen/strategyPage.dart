import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qtrade_app/services/notification_provider.dart';
import 'package:qtrade_app/screen/deployedAlgoDetailsPage.dart';
import 'package:qtrade_app/screen/deployedHistoryPage.dart';
import '../widgets/customBottomNavigationBar.dart';
import 'algorithmPage.dart';

class StrategyPage extends StatefulWidget {
  @override
  _StrategyPageState createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime currentDate = DateTime.now();
  late DateTime eightYearsAgo;
  late DateTime twelveYearsAgo;
  late DateTime selectedStartDate;
  String selectedAlgorithm = '';
  String selectedStockTicker = '';

  @override
  void initState() {
    super.initState();
    eightYearsAgo = currentDate.subtract(Duration(days: 365 * 8));
    twelveYearsAgo = currentDate.subtract(Duration(days: 365 * 12));
    selectedStartDate = eightYearsAgo;
    _dateController.text = DateFormat('yyyy-MM-dd').format(selectedStartDate);
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('No user found')),
      );
    }

    final String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF0D0828),
        elevation: 0,
        title: Text(
          'Strategy',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 16.0,
            right: 16.0,
            bottom: 120.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Deployed Algorithms',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              _buildTopDeployedAlgorithms(userId),
              SizedBox(height: 20),
              Text(
                'Algorithm List',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              _buildAlgorithmList(userId),
              SizedBox(height: 20),
              Text(
                'Deploy Algorithm',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              _buildDeployAlgorithmSection(userId),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildTopDeployedAlgorithms(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Text('Error: ${userSnapshot.error}');
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return _buildNoDeployedAlgorithmsCard();
        }

        var userDoc = userSnapshot.data!;
        var deployedAlgoRefs = userDoc['deploy_algoID'] as List<dynamic>? ?? [];

        if (deployedAlgoRefs.isEmpty) {
          return _buildNoDeployedAlgorithmsCard();
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
              deployedAlgoRefs.map((ref) => (ref as DocumentReference).get())),
          builder: (context, algoSnapshots) {
            if (algoSnapshots.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (algoSnapshots.hasError) {
              return Text('Error: ${algoSnapshots.error}');
            }
            if (!algoSnapshots.hasData || algoSnapshots.data!.isEmpty) {
              return _buildNoDeployedAlgorithmsCard();
            }

            var algoDocs = algoSnapshots.data!;
            algoDocs.sort((a, b) =>
                (a['deploy_MSE'] as num).compareTo(b['deploy_MSE'] as num));

            return Column(
              children: algoDocs.take(2).map((algoDoc) {
                String documentId = algoDoc.id;

                return Card(
                  elevation: 4,
                  color: Colors.white,
                  shadowColor: Colors.grey.withOpacity(0.5),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: getImageForRank(algoDocs.indexOf(algoDoc)),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          algoDoc['deploy_algoName'],
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          algoDoc['deploy_date'] != null
                              ? DateFormat('yyyy-MM-dd h:mma')
                                  .format(algoDoc['deploy_date'].toDate())
                              : 'No date available',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      algoDoc['deploy_stockTicker'],
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeployedAlgoDetailsPage(documentId: documentId),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildNoDeployedAlgorithmsCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No deployed algorithms found.\n Start deploying now!',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoCondensed(
              fontSize: 16,
              color: const Color.fromARGB(210, 0, 0, 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlgorithmList(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return Text('No algorithms found');
        }
        var userDoc = snapshot.data;
        var integratedAlgos = userDoc!['integrated_algoID'] as List ?? [];

        return Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: integratedAlgos.length + 1,
            itemBuilder: (context, index) {
              if (index < integratedAlgos.length) {
                var docID = integratedAlgos[index] is DocumentReference
                    ? (integratedAlgos[index] as DocumentReference).id
                    : integratedAlgos[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('algorithm')
                      .doc(docID)
                      .get(),
                  builder: (context, algoSnapshot) {
                    if (algoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!algoSnapshot.hasData) {
                      return Text('Loading...');
                    }
                    var algoData =
                        algoSnapshot.data!.data() as Map<String, dynamic>;
                    return _buildAlgorithmCircle(
                        algoData['algo_name'], context);
                  },
                );
              } else {
                return _buildAddAlgorithmCircle(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAlgorithmCircle(String name, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeployedHistoryPage(algoName: name),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Material(
              elevation: 8,
              shape: CircleBorder(),
              shadowColor: Colors.grey.withOpacity(0.8),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child:
                    Image.asset('assets/images/algorithmIcon.png', width: 40),
              ),
            ),
            SizedBox(height: 5),
            Text(
              name,
              style: GoogleFonts.robotoCondensed(color: Colors.black),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAlgorithmCircle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => AlgorithmPage()));
        },
        child: Column(
          children: [
            Material(
              elevation: 5,
              shape: CircleBorder(),
              shadowColor: Colors.grey.withOpacity(0.5),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Colors.black),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Add',
              style: GoogleFonts.robotoCondensed(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeployAlgorithmSection(String userId) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 2,
            shadowColor: Colors.grey.withOpacity(0.5),
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 176, 168, 229),
                    Color(0xFFDADAE6)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Algorithm',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.data() == null) {
                        return Text('User not found');
                      }
                      List<dynamic> integratedAlgos = (snapshot.data!.data()
                              as Map<String, dynamic>)['integrated_algoID'] ??
                          [];
                      if (integratedAlgos.isEmpty) {
                        return Text(
                          'Integrate algorithms from Algorithm page to start deployment',
                          style: GoogleFonts.robotoCondensed(),
                        );
                      }

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('algorithm')
                            .where(FieldPath.documentId,
                                whereIn: integratedAlgos)
                            .get(),
                        builder: (context, algoSnapshot) {
                          if (algoSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!algoSnapshot.hasData ||
                              algoSnapshot.data!.docs.isEmpty) {
                            return Text('No algorithms found');
                          }
                          List<DropdownMenuItem<String>> dropdownItems =
                              algoSnapshot.data!.docs.map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(doc.get('algo_name')),
                            );
                          }).toList();
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(255, 235, 235, 245),
                            ),
                            hint: Text('Select Algorithm',
                                style: GoogleFonts.robotoCondensed(
                                    color: Colors.black54)),
                            items: dropdownItems,
                            value: selectedAlgorithm.isEmpty
                                ? null
                                : selectedAlgorithm,
                            onChanged: (value) {
                              setState(() {
                                selectedAlgorithm = value!;
                              });
                            },
                            icon: Icon(Icons.keyboard_arrow_down),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Stock Ticker Symbol',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('s&p500')
                        .doc('tickers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      List<String> tickers =
                          List<String>.from(snapshot.data!['symbols']);
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          } else {
                            return tickers.where((String option) {
                              return option.toLowerCase().startsWith(
                                  textEditingValue.text.toLowerCase());
                            });
                          }
                        },
                        onSelected: (String selection) {
                          setState(() {
                            selectedStockTicker = selection;
                          });
                          debugPrint('You just selected $selection');
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              hintText: 'Enter ticker symbol',
                              hintStyle: GoogleFonts.robotoCondensed(
                                  color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(255, 235, 235, 245),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Date (8-12 years ago)',
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.help_outline),
                        onPressed: () => _showInstructions(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: twelveYearsAgo,
                        lastDate: eightYearsAgo,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedStartDate = picked;
                          _dateController.text = DateFormat('yyyy-MM-dd')
                              .format(selectedStartDate);
                        });
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(255, 235, 235, 245),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dateController.text,
                            style: GoogleFonts.robotoCondensed(
                                color: Colors.black54),
                          ),
                          Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'The algorithm is deploying...',
                              style: GoogleFonts.robotoCondensed(),
                            ),
                          ),
                        );

                        debugPrint('selectedalgo: $selectedAlgorithm');
                        debugPrint('selectedticker: $selectedStockTicker');

                        var algoDocument = await FirebaseFirestore.instance
                            .collection('algorithm')
                            .doc(selectedAlgorithm)
                            .get();
                        var algoName = algoDocument.data()?['algo_name'] ??
                            'Unknown Algorithm';

                        final url =
                            'http://10.0.2.2:5000/predict/${selectedAlgorithm}';
                        final headers = {"Content-Type": "application/json"};
                        final requestBody = jsonEncode({
                          "stockSymbol": selectedStockTicker,
                          "startDate": DateFormat('yyyy-MM-dd')
                              .format(selectedStartDate),
                        });

                        try {
                          final response = await http.post(
                            Uri.parse(url),
                            headers: headers,
                            body: requestBody,
                          );

                          if (response.statusCode == 200) {
                            final Map<String, dynamic> responseData =
                                json.decode(response.body);
                            final Map<String, dynamic> performanceMetrics =
                                responseData['performance_metrics'];
                            final Map<String, dynamic> plotData =
                                responseData['plot_data'];
                            final Map<String, dynamic> trendInsight =
                                responseData['trend_insight'];

                            String plotDataString = json.encode(plotData);
                            DocumentReference newAlgoRef =
                                await FirebaseFirestore.instance
                                    .collection('deployed_algo')
                                    .add({
                              'deploy_algoName': algoName,
                              'deploy_algoID': selectedAlgorithm,
                              'deploy_startDate': selectedStartDate,
                              'deploy_stockTicker': selectedStockTicker,
                              'deploy_EPS': responseData['eps'],
                              'deploy_MSE': performanceMetrics['MSE'],
                              'deploy_RMSE': performanceMetrics['RMSE'],
                              'deploy_MAE': performanceMetrics['MAE'],
                              'deploy_R2': performanceMetrics['R2'],
                              'deploy_MAPE': performanceMetrics['MAPE'],
                              'deploy_volatility': responseData['volatility'],
                              'deploy_trendInsight7D': trendInsight['7day_MA'],
                              'deploy_trendInsight30D':
                                  trendInsight['30day_MA'],
                              'deploy_RSI': responseData['rsi'],
                              'deploy_marketCap': responseData['market_cap'],
                              'deploy_beta': responseData['beta'],
                              'deploy_peRatio': responseData['pe_ratio'],
                              'deploy_graph': plotDataString,
                              'deploy_date': FieldValue.serverTimestamp(),
                              'deploy_backtest': [],
                            });

                            print(
                                'Response data added to database with ID: ${newAlgoRef.id}');

                            DocumentReference userRef = FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(userId);
                            FirebaseFirestore.instance
                                .runTransaction((transaction) async {
                              DocumentSnapshot userSnapshot =
                                  await transaction.get(userRef);
                              List<dynamic> deployedAlgos =
                                  userSnapshot['deploy_algoID'] ?? [];

                              DocumentReference deployedAlgoRef =
                                  FirebaseFirestore.instance
                                      .collection('deployed_algo')
                                      .doc(newAlgoRef.id);
                              deployedAlgos.add(deployedAlgoRef);
                              transaction.update(
                                  userRef, {'deploy_algoID': deployedAlgos});
                            }).then((result) {
                              print(
                                  'Added deployed algorithm reference to user document');
                            }).catchError((error) {
                              print('Error updating user document: $error');
                            });

                            Provider.of<NotificationProvider>(context,
                                    listen: false)
                                .showLocalNotification('Deployment Successful',
                                    'Your algorithm has been deployed successfully.');
                          } else {
                            print(
                                'Request failed with status: ${response.statusCode}.');
                          }
                        } catch (e) {
                          print('An error occurred: $e');
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Deploy now',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D0828),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instructions',
              style: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Select a start date 8 to 12 years prior to today:',
                  style: GoogleFonts.robotoCondensed(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.robotoCondensed(
                        fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: '• ',
                      ),
                      TextSpan(
                        text: '2012-2014: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Choose this range to capture long-term trends and significant historical events, providing a broader market context.\n\n',
                      ),
                      TextSpan(
                        text: '• ',
                      ),
                      TextSpan(
                        text: '2015-2016: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Select these years to focus on more recent market dynamics and faster processing while still covering crucial recent events like market reactions leading up to and including early impacts of global shifts.\n',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

Image getImageForRank(int rank) {
  switch (rank) {
    case 0:
      return Image.asset('assets/images/top1.png');
    case 1:
      return Image.asset('assets/images/top2.png');
    case 2:
      return Image.asset('assets/images/top3.png');
    default:
      return Image.asset('assets/images/algorithmIcon.png');
  }
}
