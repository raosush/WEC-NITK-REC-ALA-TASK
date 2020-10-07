import 'package:EmergencyApp/main.dart';
import 'package:EmergencyApp/repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final UserRepository userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info'),
      ),
      body: buildUserInfo(),
    );
  }

  Widget buildUserInfo() {
    return FutureBuilder<FirebaseUser>(
      future: FirebaseAuth.instance.currentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  (snapshot.data.photoUrl != null &&
                          snapshot.data.photoUrl != '')
                      ? CircleAvatar(
                          radius: 45.0,
                          backgroundImage: NetworkImage(snapshot.data.photoUrl),
                        )
                      : CircleAvatar(
                          radius: 45.0,
                          backgroundImage: NetworkImage(
                              'https://secure.gravatar.com/avatar/?d=mm&r=g'),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      height: 1.0,
                      width: MediaQuery.of(context).size.width / 1.4,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    '${snapshot.data.displayName}',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Soleil'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 1.0,
                      width: MediaQuery.of(context).size.width / 1.4,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    '${snapshot.data.email}',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Soleil'),
                  ),
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Text(
                      'Logout',
                    ),
                    color: Theme.of(context).accentColor,
                    textColor: Colors.white,
                    padding: EdgeInsets.all(12.0),
                    onPressed: () async {
                      // Logout user and wipe data from local database, pertaining to current user.
                      userRepository.wipeDate(snapshot.data.uid);
                      await FirebaseAuth.instance.signOut();
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      await googleSignIn.signOut();
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => SignInPage()));
                    },
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
          } else {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => SignInPage()));
          }
        }
        return Center(
          child: SpinKitThreeBounce(
            size: 30.0,
            color: Theme.of(context).accentColor,
          ),
        );
      },
    );
  }
}
