import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'utils.dart';

Future<File> _getCacheFile() async =>
    File("${(await getApplicationDocumentsDirectory()).path}/contests.json");

Future<String> _readCache() async {
  var cacheFile = await _getCacheFile();
  if (!(await cacheFile.exists())) await _updateCache().catchError((err) {});
  return cacheFile.readAsString();
}

DateTime _parseTimeStamp(int ts) => DateTime.fromMillisecondsSinceEpoch(ts);

Future<String> _updateCache() async {
  final url = 'https://lyc.xuming.studio/api/contests-info';
  var response = await http.get(url);
  if (response.statusCode != 200) throw Exception('Failed to load contests');
  var cacheFile = await _getCacheFile();
  await cacheFile.create();
  await cacheFile.writeAsString(response.body);
  return response.body;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<dynamic> _contestList;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextStyle _mapColor(int d) {
    if (d < 0) return TextStyle(color: Colors.red);
    if (d < 2) return TextStyle(color: Colors.green);
    if (d < 3) return TextStyle(color: Colors.amber);
    return TextStyle();
  }

  Widget _buildCard(dynamic item) => Card(
        key: Key(item["contestId"].toString()),
        child: ListTile(
          title: Text(item["contestName"]).pad2(3, 0),
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["startTime"]).pad2(3, 0),
                  Text(item["endTime"]).pad2(3, 0),
                ],
              ),
              Expanded(child: Container()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item["ojName"]).pad2(3, 0),
                  Text(
                    "${(item["dateDiff"] as int).toSignedString()}d",
                    style: _mapColor(item["dateDiff"]),
                  ).pad2(3, 0),
                ],
              ),
            ],
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: item["link"]));
            _scaffoldKey.currentState.showSnackBar(const SnackBar(
              content: Text("Contest link copied."),
              duration: const Duration(seconds: 1),
            ));
          },
          onLongPress: () {
            url_launcher.launch(item["link"]);
          },
        ).pad2(3, 0),
      );

  @override
  void initState() {
    _contestList = _readCache();
    super.initState();
    _updateCache().then((s) {
      _contestList = _readCache();
    }).catchError((err) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Contest Viewer'),
      ),
      body: Center(
        child: FutureBuilder<dynamic>(
          future: _contestList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<dynamic> lst = json.decode(snapshot.data)["data"];
              return ListView(
                children: lst.map(_buildCard).toList(),
              );
            } else if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () {
            _scaffoldKey.currentState.showSnackBar(const SnackBar(
              content: Text("Refreshing..."),
              duration: const Duration(seconds: 1),
            ));
            _updateCache().then((res) {
              setState(() {
                _contestList = _readCache().whenComplete(() {
                  _scaffoldKey.currentState.hideCurrentSnackBar();
                  _scaffoldKey.currentState.showSnackBar(const SnackBar(
                    content: Text("Refreshed."),
                    duration: const Duration(seconds: 1),
                  ));
                });
              });
            }).catchError((err) {
              _scaffoldKey.currentState.hideCurrentSnackBar();
              _scaffoldKey.currentState.showSnackBar(const SnackBar(
                content: Text("Refresh failed."),
                duration: const Duration(seconds: 1),
              ));
            });
          },
          tooltip: 'Refresh Contest List',
          child: Icon(Icons.refresh),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Container(),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/column_img.webp'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            ListTile(
              title: Text("Dev: TooYoungTooSimp"),
              onTap: () {
                url_launcher.launch("https://lyc.xuming.studio/");
              },
            ),
            ListTile(
              title: Text("Art: Nonad"),
              onTap: () {
                url_launcher.launch("https://www.cnblogs.com/non-");
              },
            ),
          ],
        ),
      ),
    );
  }
}
