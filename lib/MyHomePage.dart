import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<File> _getCacheFile() async =>
    File("${(await getApplicationDocumentsDirectory()).path}/contests.json");

Future<String> _readCache() async {
  var cacheFile = await _getCacheFile();
  if (!(await cacheFile.exists())) await _updateCache().catchError((err) {});
  return cacheFile.readAsString();
}

Future<String> _updateCache() async {
  final url = 'http://contests.acmicpc.info/contests.json';
  var response = await http.get(url);
  if (response.statusCode != 200) throw Exception('Failed to load contests');
  var cacheFile = await _getCacheFile();
  await cacheFile.create();
  await cacheFile.writeAsString(response.body);
  return response.body;
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<dynamic> _contestList;

  Widget _buildCard(dynamic item) => Card(
        key: Key(item["id"]),
        child: ListTile(
          title: Text(item["name"]),
          subtitle: Row(
            children: <Widget>[
              Text("${item["start_time"]} ${item["week"]}"),
              Expanded(child: Container()),
              Text(item["oj"]),
            ],
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: item["link"]));
          },
          onLongPress: () {
            url_launcher.launch(item["link"]);
          },
        ),
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
      appBar: AppBar(
        title: Text('Contest Viewer'),
      ),
      body: Center(
        child: FutureBuilder<dynamic>(
          future: _contestList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<dynamic> lst = json.decode(snapshot.data);
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
                Scaffold.of(context).showSnackBar(const SnackBar(
                  content: Text("Refreshing..."),
                  duration: const Duration(seconds: 1),
                ));
                _updateCache().then((res) {
                  setState(() {
                    _contestList = _readCache().whenComplete(() {
                      Scaffold.of(context).hideCurrentSnackBar();
                      Scaffold.of(context).showSnackBar(const SnackBar(
                        content: Text("Refreshed."),
                        duration: const Duration(seconds: 1),
                      ));
                    });
                  });
                }).catchError((err) {
                  Scaffold.of(context).hideCurrentSnackBar();
                  Scaffold.of(context).showSnackBar(const SnackBar(
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
                  image: AssetImage('assets/bg.png'),
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
              title: Row(
                children: <Widget>[
                  Text("Art: Nonad"),
                  Text("    "),
                  Text(
                    "（世界第一可爱前辈）",
                    style: TextStyle(
                      color: Colors.black12,
                      fontSize: 4.2,
                    ),
                  ),
                ],
              ),
              onTap: () {
                url_launcher.launch("https://www.cnblogs.com/non-");
              },
            ),
            ListTile(
              title: Text("Src: acmicpc.info"),
              onTap: () {
                url_launcher.launch("http://acmicpc.info/archives/224");
              },
            ),
          ],
        ),
      ),
    );
  }
}
