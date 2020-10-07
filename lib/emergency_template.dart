import 'package:EmergencyApp/repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EmergencyTemplate extends StatefulWidget {
  @override
  _EmergencyTemplateState createState() => _EmergencyTemplateState();
}

class _EmergencyTemplateState extends State<EmergencyTemplate> {
  String _template;
  TextEditingController _templateController = TextEditingController();
  final UserRepository userRepository = UserRepository();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // Fetch existing templates, if any.
    fetchData();
    super.initState();
  }

  void fetchData() async {
    String info = await userRepository.fetchTemplate();
    if (info != 'unauthorised' && info != 'empty') {
      // Set the value of template as stored in database.
      setState(() {
        _template = info;
        _templateController.value = TextEditingValue(text: _template);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Template'),
      ),
      body: _form(),
    );
  }

  Widget _form() {
    // Separate build to display snackbar.
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: TextFormField(
              obscureText: false,
              style: TextStyle(
                fontSize: 20,
              ),
              maxLines: 3,
              minLines: 1,
              controller: _templateController,
              decoration: InputDecoration(
                  hintStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  hintText: 'Enter template',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  ),
                  prefixIcon: Padding(
                    child: IconTheme(
                      data:
                      IconThemeData(color: Theme.of(context).primaryColor),
                      child: Icon(Icons.description),
                    ),
                    padding: EdgeInsets.only(left: 30, right: 10),
                  )),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter value';
                }
                return null;
              },
              onSaved: (String value) {
                _template = value;
              },
            ),
          ),
          Builder(
              builder: (context) => Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  disabledColor: Colors.black45,
                  hoverColor: Colors.blueGrey,
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins'),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      var result = await postTemplate(_template);
                      if (result) {
                        final snackBar = SnackBar(
                            content: Text('Yay! Template has been successfully created'));
                        Scaffold.of(context).showSnackBar(snackBar);
                      } else {
                        final snackBar = SnackBar(
                            content: Text(
                                'Sorry, we are facing a glitch at the moment!'));
                        Scaffold.of(context).showSnackBar(snackBar);
                      }
                    }
                  },
                ),
              ))
        ],
      ),
    );
  }

  // Insert template added by user into local database.
  Future<bool> postTemplate(String template) async {
    bool result = await userRepository.addTemplate(template);
    return result;
  }
}