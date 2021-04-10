//import 'dart:html';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert' as convert;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Countdown Solver'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _controller = TextEditingController();
  String _wordsDescendingSize;
  bool _matchedWord = false;
  String _foundWord = "waiting to solve...";
  List<String> _definitions = [];

  // load the entire sorted word file into a variable (to be run at init) ...
  void _loadWordFileData() async {
    _wordsDescendingSize =
        await rootBundle.loadString('assets/descendingWords.txt');
  }

  void _addVowel() {
    setState(() {
      if (_controller.text.length < 9) {
        Random rnd = new Random();
        int r = rnd.nextInt(5);
        _controller.text += "aeiou".substring(r, r + 1);
      }
    });
  }

  void _addConsonant() {
    setState(() {
      if (_controller.text.length < 9) {
        Random rnd = new Random();
        int r = rnd.nextInt(21);
        _controller.text += "bcdfghjklmnpqrstvwxyz".substring(r, r + 1);
      }
    });
  }

  void _fillRandom() {
    setState(() {
      _controller.clear();
      _definitions.clear();
      _matchedWord = false;
      _foundWord = "press 'Solve' to check...";
      for (int i = 0; i < 9; i++) {
        Random rnd = new Random();
        int r = rnd.nextInt(26);
        _controller.text += "abcdefghijklmnopqrstuvwxyz".substring(r, r + 1);
      }
    });
  }

  void _clear() {
    setState(() {
      // thanks to https://stackoverflow.com/questions/57059516/errors-when-clearing-textfield-flutter
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.clear());
      _matchedWord = false;
      _foundWord = "waiting to solve...";
      _definitions.clear();
    });
  }

  void _findWordMatch() {
    _matchedWord = true;
    List<String> words = _wordsDescendingSize.split('\n');
    for (String word in words) {
      List<String> availableLetters = _controller.text.split('');
      List<String> candidateLetters = word.split('');
      for (String letter in candidateLetters) {
        if (!availableLetters.remove(letter)) {
          _matchedWord = false;
          break;
        } else {
          _matchedWord = true;
        }
      }
      if (_matchedWord) {
        _foundWord = word;
        break;
      }
    }
    setState(() {
      if (!_matchedWord)
        _foundWord = "nothing found!";
      else
        _getDefinition();
    });
  }

  void _getDefinition() async {
    var url =
        Uri.https("api.dictionaryapi.dev", "/api/v2/entries/en_GB/$_foundWord");
    var response = await http.get(url);
    setState(() {
      _definitions.clear();
      if (response.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(response.body);
        for (var partOfSpeech in jsonResponse[0]['meanings']) {
          var wordType = partOfSpeech['partOfSpeech'];
          for (var definition in partOfSpeech['definitions']) {
            _definitions.add("$wordType - ${definition['definition']}");
          }
        }
      } else {
        _definitions.add("No definition found on Google for $_foundWord.");
      }
    });
    //print(_definitions);
    for (String d in _definitions) debugPrint(d);
  }

  @override
  void initState() {
    _loadWordFileData();
    super.initState();
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
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(
            widget.title,
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Container(
                child: Text(
                  'Puzzle letters:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.all(10),
              ),
              Container(
                child: TextField(
                  controller: _controller,
                  onChanged: (text) {
                    if (text.length > 9) text = text.substring(0, 9);
                  },
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    //hintText: _controller.text,
                    suffixIcon: IconButton(
                      onPressed: _clear,
                      icon: Icon(Icons.clear),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                color: Colors.lightBlue,
                alignment: Alignment.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _addVowel,
                    child: Text('Vowel'),
                  ),
                  TextButton(
                    onPressed: _addConsonant,
                    child: Text('Cnsnt'),
                  ),
                  TextButton(
                    onPressed: _fillRandom,
                    child: Text('Randm'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_controller.text.length < 9) {
                        final snackBar = SnackBar(
                          content: Text("Need 9 letters!"),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      } else
                        _findWordMatch();
                    },
                    child: Text('Solve'),
                  ),
                ],
              ),
              Container(
                child: Text(
                  'Largest word found:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        _matchedWord ? FontWeight.bold : FontWeight.normal,
                    color: _matchedWord ? Colors.black : Colors.grey,
                  ),
                ),
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.all(10),
              ),
              Container(
                child: Text(
                  _foundWord,
                  style: TextStyle(
                    fontSize: _matchedWord ? 30 : 20,
                    fontStyle:
                        _matchedWord ? FontStyle.normal : FontStyle.italic,
                    fontWeight:
                        _matchedWord ? FontWeight.bold : FontWeight.normal,
                    color: _matchedWord ? Colors.black : Colors.grey,
                  ),
                ),
                height: 40,
                alignment: Alignment.center,
              ),
              Container(
                child: Text(
                  'Definition(s):',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        _matchedWord ? FontWeight.bold : FontWeight.normal,
                    color: _matchedWord ? Colors.black : Colors.grey,
                  ),
                ),
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.all(10),
              ),
              FractionallySizedBox(
                child: SingleChildScrollView(
                  child: Container(
                    height: 100,
                    child: ListView.separated(
                      itemCount: _definitions.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          child: Text('${_definitions[index]}'),
                          alignment: Alignment.centerLeft,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )

        /*
        Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      */
        );
  }
}
