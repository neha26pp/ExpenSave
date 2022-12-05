import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() async {
  //initialize the firebase app before loading expensave
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expensave',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: 'ExpenSave',
        //category: 'Meal',
      ),
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
  //final String category;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List expenses = List.empty();
  String title = "";
  String category = "";
  double amount = 0.0;

  List<String> categories = [
    'Meals',
    'Bills',
    'Travel',
    'Grocery',
    'Misc',
  ];
  String? selectedValue;
  DateTime? selectedDate;
  @override
  void initState() {
    super.initState();
    // expenses = ["Rent", "Mobile recharge"];
  }

  createExpense() {
    DocumentReference documentReferenceE =
        FirebaseFirestore.instance.collection("MyExpenses").doc(title);
    // DocumentReference documentReferenceC =
    FirebaseFirestore.instance.collection("MyCategories").doc(category);

    Map<String, dynamic> expenseList = {
      "name": title,
      "category": category,
      "amount": amount,
      "date": selectedDate,
    };

    documentReferenceE
        .set(expenseList)
        .whenComplete(() => print("Data stored successfully"));
  }

  deleteExpense(item) {
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection("MyExpenses").doc(item);
    documentReference
        .delete()
        .whenComplete(() => print("deleted expenses successfully"));
  }

  updateExpense(item) {
    deleteExpense(item);
    createExpense();
  }

  void _showDatePicker() {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2021),
            lastDate: DateTime.now())
        .then((date) {
      if (date == null && date.toString().isEmpty) {
        return;
      }
      selectedDate = date;

      /*
       onChanged: (String value) {
                                                title = value;
                                              }),
      */
      setState(() => selectedDate = date!);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime? pickedDate = selectedDate;
    //selectedDate = null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("MyExpenses").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          } else if (snapshot.hasData || snapshot.data != null) {
            return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  QueryDocumentSnapshot<Object?>? documentSnapshot =
                      snapshot.data?.docs[index];
                  return Dismissible(
                      key: Key(index.toString()),
                      child: Card(
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            (documentSnapshot != null)
                                ? (documentSnapshot["name"])
                                : "",
                          ),

                          subtitle: Text(
                            (documentSnapshot != null)
                                // ignore: unnecessary_null_comparison
                                ? ((documentSnapshot["amount"].toString() !=
                                        null)
                                    // ignore: prefer_interpolation_to_compose_strings
                                    ? ("Amount: " +
                                        documentSnapshot["amount"].toString())
                                    : "")
                                : "",
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.blue,
                            onPressed: () {
                              setState(() {
                                //todos.removeAt(index);
                                deleteExpense((documentSnapshot != null)
                                    ? (documentSnapshot["name"])
                                    : "");
                              });
                            },
                          ),
                          // ignore: avoid_print
                          onTap: () {
                            //print("Container was tapped");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExpenseDetails(
                                          name: documentSnapshot!["name"],
                                          amount: documentSnapshot["amount"],
                                          category:
                                              documentSnapshot["category"],
                                          selectedDate:
                                              documentSnapshot["date"].toDate(),
                                        )));
                          },
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    title: const Text("Edit Expense"),
                                    content: SizedBox(
                                      width: 400,
                                      height: 400,
                                      child: Column(
                                        children: [
                                          TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Name',
                                                hintText:
                                                    documentSnapshot!["name"],
                                              ),
                                              style: const TextStyle(
                                                  fontFamily: 'Quicksand'),
                                              onChanged: (String value) {
                                                title = value;
                                              }),
                                          TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Amount',
                                                hintText:
                                                    documentSnapshot["amount"]
                                                        .toString(),
                                              ),
                                              style: const TextStyle(
                                                  fontFamily: 'Quicksand'),
                                              onChanged: (value) {
                                                //double.tryParse(element.get('price').toString()) ?? 0
                                                setState(() {
                                                  amount =
                                                      double.tryParse(value)!;
                                                });
                                              }),
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 8.0, bottom: 5.0),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.all(0.0),
                                              horizontalTitleGap: 0.0,
                                              title: Text(
                                                selectedDate == null
                                                    ? 'No Date Selected!'
                                                    : DateFormat.yMMMd()
                                                        .format(selectedDate!),
                                                style: const TextStyle(
                                                  fontFamily: 'OpenSans',
                                                ),
                                              ),
                                              leading:
                                                  const Icon(Icons.date_range),
                                              trailing: TextButton(
                                                onPressed: _showDatePicker,
                                                child: Text(
                                                  'Choose Date',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .button,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DropdownButton(
                                            icon: Icon(Icons.arrow_drop_down),
                                            hint: const Text(
                                              'Select Item',
                                              style: TextStyle(
                                                  fontFamily: 'Quicksand'),
                                            ),
                                            value: selectedValue,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedValue = value as String;
                                                category = value;
                                              });
                                            },
                                            items: categories.map((item) {
                                              return DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(
                                                  item,
                                                  style: const TextStyle(
                                                      fontFamily: 'Quicksand'),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                          onPressed: () {
                                            setState(() {
                                              //todos.add(title);
                                              // ignore: unnecessary_null_comparison
                                              updateExpense((documentSnapshot !=
                                                      null)
                                                  ? (documentSnapshot["name"])
                                                  : "");
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("Edit"))
                                    ],
                                  );
                                });
                          },
                        ),
                      ));
                });
          }
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  title: const Text("Add expense"),
                  content: Container(
                    width: 400,
                    height: 400,
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                          ),
                          onChanged: (String value) {
                            title = value;
                          },
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Quicksand',
                          ),
                          onChanged: (value) {
                            setState(() {
                              amount = double.tryParse(value)!;
                            });
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(0.0),
                            horizontalTitleGap: 0.0,
                            title: Text(
                              selectedDate == null
                                  ? 'No Date Selected!'
                                  : DateFormat.yMMMd().format(selectedDate!),
                              style: const TextStyle(
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            leading: const Icon(Icons.date_range),
                            trailing: TextButton(
                              onPressed: _showDatePicker,
                              child: Text(
                                'Choose Date',
                                style: Theme.of(context).textTheme.button,
                              ),
                            ),
                          ),
                        ),
                        DropdownButton(
                          icon: Icon(Icons.arrow_drop_down),
                          hint: const Text(
                            'Select Item',
                            style: TextStyle(fontFamily: 'Quicksand'),
                          ),
                          value: selectedValue,
                          onChanged: (value) {
                            setState(() {
                              selectedValue = value as String;
                              category = value;
                            });
                          },
                          items: categories.map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(fontFamily: 'Quicksand'),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                        onPressed: () {
                          setState(() {
                            //todos.add(title);
                            createExpense();
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text("Add"))
                  ],
                );
              });
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ExpenseDetails extends StatelessWidget {
  final String name;
  final double amount;
  final String category;
  final DateTime selectedDate;

  const ExpenseDetails(
      {required this.name,
      required this.amount,
      required this.category,
      required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details"),
      ),
      body: Center(
          child: Text(
              "name: $name\namount: $amount\ncategory: $category\ndate: $selectedDate")),
    );
  }
}
