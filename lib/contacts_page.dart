import 'package:EmergencyApp/emergency_contacts.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:multi_select_item/multi_select_item.dart';
import 'package:EmergencyApp/repository.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _contacts;
  List<Contact> con = [];
  String _title;
  String _searchTerm;
  bool _refresh = true;
  TextEditingController _textEditingController = new TextEditingController();
  MultiSelectController _controller = new MultiSelectController();
  final UserRepository userRepository = UserRepository();

  @override
  void initState() {
    checkForPermission();
    super.initState();
    _title = 'Contacts';
    _controller.disableEditingWhenNoneSelected = true;
    checkForPermission();
  }

  // Check if contact permission is given, else prevent the build.
  void checkForPermission() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      Navigator.of(context).pop();
    } else if (status.isGranted) {
      refreshContacts(_refresh);
    }
  }

  Future<void> refreshContacts(bool refresh) async {
    // Refresh contacts only when requested by the user.
    if (_refresh) {
      var contacts =
          (await ContactsService.getContacts(withThumbnails: false)).toList();
      con = contacts;
      // Set the controller's length for selection.
      _controller.set(con.length);
    }
    List<Contact> c = [];
    // Search in contacts on user input.
    if (_searchTerm != null && _searchTerm != '' && _searchTerm != ' ') {
      con.forEach((element) {
        if (element.displayName != null && element.phones.isNotEmpty) {
          // Display only those contacts which either contain the searched value as name (or) as number.
          if (element.displayName
                  .toLowerCase()
                  .replaceAll(' ', '')
                  .contains(_searchTerm.toLowerCase().replaceAll(' ', '')) ||
              searchInPhone(element.phones)) {
            c.add(element);
          }
        }
      });
    }
    setState(() {
      // If search results are empty, display all contacts.
      _contacts = c.isEmpty ? con : c;
    });
  }

  // Function to search for user input in all phone numbers of a contact.
  bool searchInPhone(Iterable<Item> phones) {
    phones.forEach((element) {
      if (element.value
          .replaceAll(' ', '')
          .contains(_searchTerm.replaceAll(' ', ''))) {
        return true;
      }
    });
    return false;
  }

  // Function to select all contacts.
  void selectAll() {
    setState(() {
      _controller.toggleAll();
    });
  }

  // Function to add all selected contacts as emergency contacts into local database.
  void executeQuery() async {
    List<Contact> contacts = [];
    var list = _controller.selectedIndexes;
    list.forEach((element) {
      contacts.add(con.elementAt(element));
    });
    bool result = await userRepository.addContacts(contacts);
    if (result) {
      displayDialog(context);
      setState(() {
        _controller.deselectAll();
        _title = 'Contacts';
      });
    }
  }

  // Display a success dialog on successful insertion of contacts.
  displayDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contacts Added'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Hurray! All the selected contacts have been added.'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Emergency Contacts'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EmergencyContacts()));
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Deselect all contacts before exiting the build.
        var b = !_controller.isSelecting;
        setState(() {
          _controller.deselectAll();
          _title = 'Contacts';
        });
        return b;
      },
      child: new Scaffold(
        appBar: new AppBar(
          title: Text(_title),
          actions: _controller.isSelecting
              ? <Widget>[
                  IconButton(
                    icon: Icon(Icons.select_all),
                    onPressed: selectAll,
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle),
                    onPressed: () {
                      executeQuery();
                    },
                  )
                ]
              : <Widget>[],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 29.0),
                child: Container(
                  height: 60.0,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15, 8, 8, 8),
                      child: TextField(
                        cursorWidth: 1,
                        cursorColor: Colors.cyan[800],
                        controller: _textEditingController,
                        decoration: InputDecoration(
                            labelText: _textEditingController.text == null ||
                                    _textEditingController.text == ''
                                ? 'Search for contact'
                                : '',
                            suffixIcon: _searchTerm != ''
                                ? IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      _textEditingController.clear();
                                      setState(() {
                                        _searchTerm = "";
                                        _refresh = false;
                                        refreshContacts(_refresh);
                                      });
                                    })
                                : Icon(Icons.search)),
                        onChanged: (text) {
                          setState(() {
                            _searchTerm = text;
                            _refresh = false;
                            refreshContacts(_refresh);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _contacts != null
                    ? ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            child: MultiSelectItem(
                              isSelecting: _controller.isSelecting,
                              onSelected: () {
                                setState(() {
                                  _controller.toggle(con.indexWhere((element) =>
                                      element == _contacts[index]));
                                  if (_controller.selectedIndexes.length != 0) {
                                    _title =
                                        'Selected ${_controller.selectedIndexes.length}';
                                  } else {
                                    _title = 'Contacts';
                                  }
                                });
                              },
                              child: Container(
                                child: ListTile(
                                  leading: _controller.isSelected(
                                          con.indexWhere((element) =>
                                              element == _contacts[index]))
                                      ? CircleAvatar(
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.blue,
                                          ),
                                        )
                                      : CircleAvatar(
                                          child: Text(
                                              _contacts[index].initials())),
                                  title: new Text(
                                      "${_contacts[index].displayName ?? 'Unknown'}"),
                                ),
                                decoration: _controller.isSelected(
                                        con.indexWhere((element) =>
                                            element == _contacts[index]))
                                    ? new BoxDecoration(color: Colors.cyan[100])
                                    : new BoxDecoration(),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: SpinKitThreeBounce(
                          color: Theme.of(context).accentColor,
                          size: 30.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EmergencyContacts()));
          },
          tooltip: 'Emergency Contacts',
          child: Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
