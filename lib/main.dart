import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:convert' show json;
import 'package:unity_ads_flutter/unity_ads_flutter.dart';

const String videoPlacementId='rewardedVideo';
const String gameIdAndroid='3077537';
const String gameIdIOS='3077536';

String encodeMap(Map data) {
  return data.keys
      .map((key) =>
          "${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key])}")
      .join("&");
}

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  runApp(new MaterialApp(title: 'JGI Stats', home: new Home(), debugShowCheckedModeBanner: false));
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new HomeView();
  }
}

class HomeView extends State<Home> with UnityAdsListener {
  UnityAdsError _error;
  bool _ready;
  String _errorMessage;
  var _coins = 10;
  var loggedIn = false;
  var connData = ['-', '-', '-', '-', '-'];
  var status = 'Not Logged In';
  var color = Colors.red;

  var controller = TextEditingController();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localDBFile async {
    final path = await _localPath;
    return File('$path/database.dat');
  }

  Future<List> get users async {
    final file = await _localDBFile;
    var db = await file.readAsString();
    var dat = json.decode(db);
    return dat;
  }

  Future<File> get _localCoinsFile async {
    final path = await _localPath;
    return File('$path/coins.dat');
  }

  Future<int> get gcoins async {
    final file = await _localCoinsFile;
    var db = await file.readAsString();
    var dat = int.parse(db);
    return dat;
  }

  @override
  void initState() {
    gcoins.then((coinval) { _coins = _coins + coinval; });
    UnityAdsFlutter.initialize(gameIdAndroid, gameIdIOS, this, true);
    _ready = false;
    super.initState();
    _login('', '');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void onUnityAdsError(UnityAdsError error, String message) {
    print('$error occurred: $message');
    setState((){
      _error=error;
      _errorMessage=message;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text(_error.toString()),
            content: new Text(_errorMessage),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  void onUnityAdsFinish(String placementId, FinishState result) {
    print('Finished $placementId with $result');
    setState(() async {
      _coins += 5;
      var file = await _localCoinsFile;
      file.writeAsString(_coins.toString());
    });
  }

  @override
  void onUnityAdsReady(String placementId) {
    print('Ready: $placementId');
    if (placementId == videoPlacementId){
      setState(() {
        _ready = true;
      });
    }
  }

  @override
  void onUnityAdsStart(String placementId) {
    print('Start: $placementId');
    if(placementId == videoPlacementId){
      setState(() {
        _ready = false;
      });
    }
  }

  String randomCase(String str) {
    var rng = new Random.secure();
    var strList = str.split('');
    for (var i = 0; i < strList.length; i++) {
      var choice = rng.nextBool();
      if (choice)
        strList[i] = strList[i].toLowerCase();
      else
        strList[i] = strList[i].toUpperCase();
    }
    return strList.join('');
  }

  void _loginJGI() {
    var nu;
    users.then((resp) {
      nu = resp;
    });
    var n = nu[1];
    n.forEach((user, pass) {
      var username = randomCase(user);
      _login(username, pass);
    });
  }

  void _getNewCoins() {
    setState(() {
      _ready = false;
      UnityAdsFlutter.show('video');
    });
  }

  void _login(String username, String password) {
    if(_coins == 0) {
      return;
    }
    var headers = {
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "max-age=0",
      "Connection": "keep-alive",
      "Host": "wifi.dvois.com",
      "Origin": "null",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.81 Safari/537.36"
    };
    var data = {
      "username": username,
      "password": password,
      "dst": '',
      "popup": false
    };
    var url = "http://wifi.dvois.com/login";
    Dio dio = new Dio();
    dio
        .post(url,
            options: Options(
                headers: headers,
                contentType:
                    ContentType.parse("application/x-www-form-urlencoded")),
            data: data)
        .then((response) {
      var doc = parse(response.data);
      var text = doc.getElementsByTagName("input");
      var table = doc.getElementsByTagName("table");

      setState(() async {
        if (table.isNotEmpty) {
          loggedIn = true;
          _coins = _coins - 1;
          var file = await _localCoinsFile;
          file.writeAsString(_coins.toString());
          color = Colors.green;
          status = 'Logged In!';
          return;
        } else if (text.isNotEmpty) {
          loggedIn = false;
          color = Colors.red;
          status = 'Not Logged In';
        }
      });
    });
  }

  void _getJGIStats() {
    var headers = {
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "max-age=0",
      "Connection": "keep-alive",
      "Content-Type": "application/x-www-form-urlencoded",
      "Host": "wifi.dvois.com",
      "Origin": "null",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.81 Safari/537.36"
    };
    var url = "http://wifi.dvois.com/status";
    Dio dio = new Dio();
    dio.get(url, options: Options(headers: headers)).then((response) {
      var doc = parse(response.data);
      var table = doc.getElementsByClassName("tabula")[0].children[0].children;
      setState(() {
        for (var i = 0; i < table.length; i++) {
          connData[i] = table[i].children[1].innerHtml;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _getJGIStats();

    return Scaffold(
      backgroundColor: Color(0xffe0e0e0),
      body: Container(
          child: Stack(
        children: <Widget>[
          Container(
              height: 0.345 * MediaQuery.of(context).size.height,
              child: AppBar(
                elevation: 2,
                backgroundColor: color,
              )),
          Container(
              height: 0.35 * MediaQuery.of(context).size.height,
              child: Center(
                child: Text(
                  status,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
              )),
          Container(
              padding: EdgeInsets.only(
                  top: 0.33 * MediaQuery.of(context).size.height,
                  right: 0.02 * MediaQuery.of(context).size.width,
                  bottom: 0.01 * MediaQuery.of(context).size.height),
              child: Container(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 0.03 * MediaQuery.of(context).size.height,
                    left: 0.02 * MediaQuery.of(context).size.width,
                  ),
                  child: Center(
                    child: Container(
                      child: ListView(
                        padding: EdgeInsets.only(top: 0),
                        children: [
                          Card(
                            child: ListTile(
                                subtitle: Text("UPLOAD / DOWNLOAD",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                leading: Icon(
                                  Icons.data_usage,
                                  color: Colors.black,
                                ),
                                title: Text(connData[1],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17))),
                          ),
                          Card(
                            child: ListTile(
                                subtitle: Text("IP ADDRESS",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                leading: Icon(
                                  Icons.settings_ethernet,
                                  color: Colors.black,
                                ),
                                title: Text(connData[0],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17))),
                          ),
                          Card(
                            child: ListTile(
                                subtitle: Text("TIME ELAPSED",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                leading: Icon(
                                  Icons.timelapse,
                                  color: Colors.black,
                                ),
                                title: Text(connData[2],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17))),
                          ),
                          Card(
                            child: ListTile(
                                subtitle: Text("COINS",
                                    style:
                                    TextStyle(fontWeight: FontWeight.w500)),
                                leading: Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.black,
                                ),
                                title: Text(_coins.toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17)),
                                trailing: IconButton(icon: Icon(Icons.add), onPressed: (_ready)? _getNewCoins : null, color: (_ready)? Colors.blue: Colors.grey,
                                ),
                            ),
                          ),
                        ],
                      ),
                      alignment: Alignment.topLeft,
                    ),
                  ),
                ),
              )),
          Builder(
            builder: (BuildContext context) {
              return Container(
                padding: EdgeInsets.only(left: 0.8 * MediaQuery.of(context).size.width, top: 0.3 * MediaQuery.of(context).size.height),
                child: FloatingActionButton(child: Icon(Icons.cloud_download), onPressed: () async {
                  try {
                    final file = await _localDBFile;
                    Dio dio = new Dio();
                    var response = await dio.get('https://jgi.herokuapp.com/v2/getdb');
                    file.writeAsString(response.data);
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Database updated successfully!'),
                    ));
                  }
                  catch(e) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Error updating database!'),
                    ));
                  }
                },),
              );
            },
          ),
          Container(
            padding: EdgeInsets.only(left: 0.6 * MediaQuery.of(context).size.width, top: 0.3 * MediaQuery.of(context).size.height),
            child: FloatingActionButton(child: Icon(Icons.vpn_lock), onPressed: _loginJGI,),
          ),
        ],
      )),
    );
  }
}
