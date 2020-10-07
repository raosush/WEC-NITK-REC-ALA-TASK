import 'dart:convert';
import 'package:EmergencyApp/client_db.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  // Instantiate DBProvider class.
  final dbProvider = ClientDBProvider();

  // Function to add all selected contacts.
  Future<bool> addContacts(List<Contact> contacts) async {
    final db = await dbProvider.database;
    // Confirm if user is logged in or not, return if user is not logged in.
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser == null) {
      return false;
    }
    // Iterate all selected contacts.
    for (final c in contacts) {
      List<String> phones = [];
      // Store all unique labels of phone numbers
      var x = c.phones.toSet().toList().map((e) => e.label).toList();
      // Store all unique phone numbers
      var z = c.phones.toSet().toList().map((e) => e.value).toList();
      List<String> y = [];
      // Store only the first value of each label, in case of duplicates.
      // Ex - "mobile": +91 12345 67890, "mobile": +911234567890
      x.asMap().forEach((key, value) {
        if (y.indexWhere((element) => element == value) == -1) {
          y.add(value);
          phones.add(z.elementAt(key));
        }
      });
      // Create a map to store required details.
      var map = {'name': c.displayName ?? "Unknown", 'initials': c.initials(), 'number': json.encode(phones), 'uid': firebaseUser.uid};
      var result = db.insert('contacts', map);
      // Check if the contact was successfully added or not, if unsuccessful return false.
      if (result == null) {
        return false;
      }
    }
    return true;
  }

  // Function to retrieve emergency contacts stored in database.
  Future<List<Map<String, dynamic>>> retrieveContacts() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> result = [];
    // Check if user is logged in or not, if not logged in return unauthorised status.
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser == null) {
      return [{'unauthorised': 1}];
    }
    // Retrieve all emergency contacts stored by the currently logged in user.
    result = await db.query('contacts', where: 'uid = ?', whereArgs: [firebaseUser.uid]);
    if (result.isNotEmpty && result != null) {
      return result;
    }
    return [];
  }

  // Function to delete emergency contacts selected by the user.
  Future<bool> deleteContacts(List<Map<String, dynamic>> contacts) async{
    final db = await dbProvider.database;
    // Check if user is logged in or not, if not logged in return.
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser == null) {
      return false;
    }
    // Iterate over all contacts selected to delete them.
    for (final c in contacts) {
      var result = db.delete('contacts', where: 'id = ?', whereArgs: [c['id']]);
      if (result == null) {
        return false;
      }
    }
    return true;
  }

  // Function to fetch template inserted by the user.
  Future<String> fetchTemplate() async {
    final db = await dbProvider.database;
    // Check if user is logged in or not, return if not logged in.
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser == null) {
      return 'unauthorised';
    }
    // Return the template stored by the currently logged in user.
    var result = await db.query('templates', where: 'uid = ?', whereArgs: [firebaseUser.uid]);
    if (result.isNotEmpty && result != null) {
      return result.first['info'];
    }
    return 'empty';
  }

  // Function to insert template entered by user into local database.
  Future<bool> addTemplate(String template) async {
    final db = await dbProvider.database;
    // Check if user is logged in or not, return if not logged in.
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser == null) {
      return false;
    }
    // Insert template added by user into local database.
    var result = await db.insert('templates', {'info': template, 'uid': firebaseUser.uid});
    if (result != null) {
      return true;
    }
    return false;
  }

  // Function to delete all data, when a user signs out.
  Future<void> wipeDate(String uid) async {
    final db = await dbProvider.database;
    var result = await db.delete('contacts', where: 'uid = ?', whereArgs: [uid]);
    var r = await db.delete('templates', where: 'uid = ?', whereArgs: [uid]);
    return;
  }
}