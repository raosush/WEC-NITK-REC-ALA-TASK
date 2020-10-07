import 'dart:convert';
import 'package:EmergencyApp/contacts_page.dart';
import 'package:EmergencyApp/emergency_contacts.dart';
import 'package:EmergencyApp/emergency_template.dart';
import 'package:EmergencyApp/repository.dart';
import 'package:EmergencyApp/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms/flutter_sms.dart';

// Display sign in page if user is not logged in, and display home page if user is logged in.
Widget homeScreen() {
  return FutureBuilder<FirebaseUser>(
    future: FirebaseAuth.instance.currentUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasData) {
          return MyHomePage();
        } else {
          return SignInPage();
        }
      } else if (snapshot.hasError) {
        print(snapshot.error);
      }
      return SpinKitThreeBounce(
        color: Theme.of(context).accentColor,
        size: 30.0,
      );
    },
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarming App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: homeScreen(),
    );
  }
}

class SignInPage extends StatefulWidget {
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseUser _user;
  bool _success;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Sign In',
            style: TextStyle(
                fontSize: 18,
                fontFamily: 'Soleil',
                fontWeight: FontWeight.w600),
          ),
        ),
        body: displaySnackbar());
  }

  // Form to sign in via Google.
  Widget displaySnackbar() {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Emergency Application',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
              Container(
                  height: 160,
                  width: 160,
                  child: Image.asset('assets/ic_launcher.png')),
              Text(
                'Please sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Login with ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Soleil'),
                      ),
                      Icon(
                        FontAwesomeIcons.google,
                        size: 20,
                      ),
                    ],
                  ),
                  onPressed: () {
                    _signInWithGoogle().then((value) {
                      _success = value;
                      if (_success) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => MyHomePage(),
                        ));
                      } else if (_success == false) {
                        final snackBar = SnackBar(
                            content: Text(
                                'Sorry! We are unable to log you in. Please try again!'));
                        Scaffold.of(context).showSnackBar(snackBar);
                      }
                    });
                    displayDialog(context);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  displayDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new Center(
          child: new SizedBox(
            width: 80.0,
            height: 80.0,
            child: SpinKitThreeBounce(
              color: Theme.of(context).accentColor,
              size: 30.0,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    // Return if no google account is selected.
    if (googleUser != null) {
      // Complete google authentication.
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Sign in user after authenticating request.
      _user = (await _auth.signInWithCredential(credential)).user;
      assert(_user.email != null);
      assert(_user.displayName != null);
      assert(!_user.isAnonymous);
      assert(await _user.getIdToken() != null);

      final FirebaseUser currentUser = await _auth.currentUser();
      assert(_user.uid == currentUser.uid);
      return true;
    }
    return false;
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final UserRepository userRepository = UserRepository();
  bool _hasPermission;
  @override
  void initState() {
    super.initState();
    // Ask for contacts permission.
    _askPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _askPermissions() async {
    PermissionStatus permissionStatus;
    while (permissionStatus != PermissionStatus.granted) {
      permissionStatus = await _getContactPermission();
      if (permissionStatus != PermissionStatus.granted) {
        _hasPermission = false;
        _handleInvalidPermissions(permissionStatus);
      } else {
        _hasPermission = true;
      }
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    final status = await Permission.contacts.status;
    // Request for contacts permission if not granted. Exit loop if permission is permanently denied.
    if (!status.isGranted && !status.isPermanentlyDenied) {
      final result = await Permission.contacts.request();
      return result ?? PermissionStatus.undetermined;
    } else {
      return status;
    }
  }

  // Handle exception if user denies permission.
  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Access to contacts data denied',
          details: null);
    } else if (permissionStatus == PermissionStatus.restricted) {
      throw PlatformException(
          code: 'PERMISSION_DISABLED',
          message: 'Contacts data is not available on device',
          details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Alarming App"),
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
                      child: Image(
                        image: AssetImage('assets/ic_launcher.png'),
                        height: 40.0,
                      ),
                    ),
                    Text(
                      'Emergency App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
              ),
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.user),
              title: Text('Add Contacts'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContactsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Emergency Contacts'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EmergencyContacts()));
              },
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.pen),
              title: Text('Template'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EmergencyTemplate()));
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('User Profile'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserProfile()));
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Welcome to the app!'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.message
        ),
        onPressed: () {
          _sendSMS();
        },
      ),
    );
  }

  // Function to send SMS to selected contacts.
  void _sendSMS() async {
    String message = await userRepository.fetchTemplate();
    List<Map<String, dynamic>> con = await userRepository.retrieveContacts();
    // Check message returned from the query, if user is logged in and template is not empty and emergency contacts are added, then send sms to selected contacts with template.
    if (message != 'unauthorised' && message != 'empty' && con != [] && con != [{'unauthorised': 1}]) {
      List<String> people = [];
      // Add numbers of all emergency contacts.
      con.forEach((element) {
        json.decode(element['number']).forEach((e) {
          people.add(e.toString());
        });
      });
      // Send message to emergency contacts with the template provided by user.
      String _result = await sendSMS(message: message, recipients: people)
          .catchError((onError) {
        print(onError);
      });
      print(_result);
    } else if (message == 'unauthorised') {
      // If user is not logged in, redirect to login page.
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SignInPage()));
    } else if (message == 'empty') {
      // If template is empty, display a dialog with the error.
      displayDialog(context, 'Please add a template', 1);
    } else if (con == []) {
      // If contacts added are empty, display a dialog with the error.
      displayDialog(context, 'Please add emergency contacts!', 2);
    }
  }

  displayDialog(BuildContext context, String message, int x) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(x == 1 ? 'Emergency Template' : 'Add Contact'),
              onPressed: () {
                // Close dialog.
                Navigator.of(context).pop();
                // Navigate to respective error causing page.
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => x == 1 ? EmergencyTemplate() : ContactsPage()));
              },
            ),
            FlatButton(
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
