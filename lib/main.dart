import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedIndex;

  final _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textFieldController,
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(contex, index) {
    final item = _todoList[index];
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        _lastRemoved = Map.from(item);
        _lastRemovedIndex = index;
        _todoList.removeAt(index);

        setState(() {
          _saveData();
        });

        final snackBar = SnackBar(
          content: Text("Tarefa ${item["title"]} removida"),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: () {
              _restoreToDo(_lastRemoved, _lastRemovedIndex);
            },
          ),
        );

        Scaffold.of(contex).removeCurrentSnackBar();
        Scaffold.of(contex).showSnackBar(snackBar);
      },
      child: CheckboxListTile(
        title: Text(item["title"]),
        value: item["ok"],
        secondary: CircleAvatar(
          child: Icon(item["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool checked) {
          setState(() {
            item["ok"] = checked;
            _saveData();
          });
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void _addToDo() {
    Map<String, dynamic> newToDo = Map();
    newToDo["title"] = _textFieldController.text;
    _textFieldController.text = "";
    newToDo["ok"] = false;

    setState(() {
      _todoList.add(newToDo);
      _saveData();
    });
  }

  void _restoreToDo(Map<String, dynamic> lastRemoved, int index) {
    setState(() {
      _todoList.insert(_lastRemovedIndex, _lastRemoved);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });

    return null;
  }
}
