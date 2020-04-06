import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WSB Application',
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
      home: MyHomePage(title: 'WSB Students Chat'),
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
  List<String> chatMessages = [];
  bool _smallDevice = false;

  FirebaseUser _user;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseReference = Firestore.instance;
  var _textController = TextEditingController(text: "Write here");

  void _loginWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    print("signed in " + user.displayName);

    databaseReference.collection('chat').limit(50).snapshots().listen((event) {
      print("GOT RESPONSE FROM DATABASE ${event.runtimeType}");

      event.documents.reversed.forEach((element) {
        chatMessages.add("${element['message']} from ${element['user']}");
      });
      setState(() {
        chatMessages = chatMessages.toSet().toList();
      });
    });

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context);
    print("SIZE ${deviceData.size}");
    if (deviceData.size.width < 600) {
      _smallDevice = true;
    } else {
      _smallDevice = false;
    }

    if (chatMessages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: _buildUserWidget(_user),
                onPressed: () {
                  _loginWithGoogle();
                },
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _user == null ? Colors.red : Colors.blueGrey,
          actions: _isLoggedIn(),
          centerTitle: true,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: chatMessages.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    return ListTile(title: Text(chatMessages[index]));
                  }),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 4.0)),
                  child: TextField(
                    focusNode: FocusNode(),
                    cursorColor: Colors.lightGreen,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, height: 5),
                    onSubmitted: (text) {
                      _sendMessageToFirebase(text);
                      _textController.value = TextEditingValue(text: "");
                    },
                    controller: _textController,
                  ),
                )),
            Container(
              child: _smallDevice == true
                  ? Text("Small Device")
                  : Text("Large Device"),
            )
          ],
        ),
      );
    }
  }

  Widget _buildUserWidget(FirebaseUser user) {
    if (user == null) {
      return Text("Login With Google");
    } else {
      return Row(
        children: [Text(user.displayName), Image.network(user.photoUrl)],
      );
    }
  }

  List<Widget> _isLoggedIn() {
    if (_user == null) {
      return [Text("Guest")];
    } else {
      return [
        Image.network("${_user.photoUrl}"),
        Text(
          _user.displayName,
          style: TextStyle(color: Colors.white),
        ),
      ];
    }
  }

  void _sendMessageToFirebase(String text) async {
    if (text != "Write here") {
      DocumentReference ref = await databaseReference
          .collection("chat")
          .add({'message': text, 'user': _user.email});
    }
  }
}
