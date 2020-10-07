import 'package:EmergencyApp/main.dart';
import 'package:EmergencyApp/repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:flutter/material.dart';

class EmergencyContacts extends StatefulWidget {
  @override
  _EmergencyContactsState createState() => _EmergencyContactsState();
}

class _EmergencyContactsState extends State<EmergencyContacts> {
  final UserRepository userRepository = UserRepository();
  List<Map<String, dynamic>> con = [];
  Future<List<Map<String, dynamic>>> contacts;
  String _title;
  MultiSelectController controller = new MultiSelectController();
  @override
  void initState() {
    _title = 'Emergency Contacts';
    contacts = fetchContacts();
    super.initState();
  }

  // Function to retrieve emergency contacts added by a user.
  Future<List<Map<String, dynamic>>> fetchContacts() async {
    con = await userRepository.retrieveContacts();
    return con;
  }

  // Function to select all.
  void selectAll() {
    setState(() {
      controller.toggleAll();
    });
  }

  // Delete all selected contacts from emergency contacts table.
  void executeQuery() async {
    List<Map<String, dynamic>> contact = [];
    var list = controller.selectedIndexes;
    var l = await contacts;
    list.forEach((element) {
      contact.add(l.elementAt(element));
    });
    var c = contact;
    bool result = await userRepository.deleteContacts(c);
    if (result) {
      setState(() {
        controller.deselectAll();
        contacts = fetchContacts();
        _title = 'Emergency Contacts';
      });
      displayDialog(context);
    }
  }

  // Display a dialog on successful deletion of selected contacts.
  displayDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contacts Deleted!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Selected contacts have been deleted'),
              ],
            ),
          ),
          actions: <Widget>[
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: contacts,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Emergency Contacts'),
              ),
              body: Center(
                child: Text("You do not have any emergency contacts stored"),
              ),
            );
          } else if (snapshot.data[0] == {'unauthorised': 1}) {
            // Redirect to SignInPage if no user is logged in.
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SignInPage()));
          } else {
           return WillPopScope(
             onWillPop: () async {
               // Deselect all selected contacts before exiting build.
               var before = !controller.isSelecting;
               setState(() {
                 controller.deselectAll();
                 _title = "Contacts";
               });
               return before;
             },
             child: new Scaffold(
                 appBar: new AppBar(
                   title: Text(_title),
                   actions: (controller.isSelecting)
                       ? <Widget>[
                     IconButton(
                       icon: Icon(Icons.select_all),
                       onPressed: selectAll,
                     ),
                     IconButton(
                       icon: Icon(Icons.delete_forever),
                       onPressed: () {
                         executeQuery();
                       },
                     )
                   ]
                       : <Widget>[],
                 ),
                 body: ListView.builder(
                   itemCount: snapshot.data.length,
                   itemBuilder: (context, index) {
                     return InkWell(
                       child: MultiSelectItem(
                         isSelecting: controller.isSelecting,
                         onSelected: () {
                           setState(() {
                             controller.toggle(index);
                             if (controller.selectedIndexes.length != 0) {
                               _title = 'Selected ${controller.selectedIndexes.length}';
                             } else {
                               _title = 'Contacts';
                             }
                           });
                         },
                         child: Container(
                           child: ListTile(
                             leading: controller.isSelected(index)
                                 ? CircleAvatar(child: Icon(Icons.check, color: Colors.blue,),)
                                 : CircleAvatar(child: Text(snapshot.data[index]['initials'])),
                             title: new Text("${snapshot.data[index]['name']}"),
                           ),
                           decoration: controller.isSelected(index)
                               ? new BoxDecoration(color: Colors.cyan[100])
                               : new BoxDecoration(),
                         ),
                       ),
                     );
                   },
                 )
             ),
           );
          }
        }
        return SpinKitThreeBounce(
          color: Theme.of(context).accentColor,
          size: 30.0,
        );
      },
    );
  }
}