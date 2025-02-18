import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:graduation_project/widgets/Constants.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceControl extends StatefulWidget {
  final BluetoothDevice server;

  const VoiceControl({this.server});

  static const String id = 'VoiceControl';

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<VoiceControl> {
  final Map<String, HighlightedWord> _highlights = {
    'right': HighlightedWord(
      onTap: () => print('right'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'left': HighlightedWord(
      onTap: () => print('left'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'forward': HighlightedWord(
      onTap: () => print('forward'),
      textStyle: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'backward': HighlightedWord(
      onTap: () => print('backward'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'back': HighlightedWord(
      onTap: () => print('backward'),
      textStyle: const TextStyle(
        color: Colors.indigo,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'up': HighlightedWord(
      onTap: () => print('backward'),
      textStyle: const TextStyle(
        color: Colors.amber,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    'stop': HighlightedWord(
      onTap: () => print('stop'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking'.tr().toString();
  double _confidence = 1.0;

  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = [];
  List<String> commands;
  List<String> forward = [];
  List<String> backward = [];
  List<String> right = [];
  List<String> left = [];
  List<String> stop = [];
  String _messageBuffer = '';
  bool isStopped = false;

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });
      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      commands = prefs.getStringList("commands");
      if (commands == null) {
        commands = ["forward", "backward", "right", "left", "stop"];
      }
    } catch (e) {
    }

    forward = ["forward"];
    backward = ["backward"];
    right = ["right"];
    left = ["left"];
    stop = ["stop"];

    for(int i = 0 ; i < commands.length ; i++){
      if(i % 5 == 0){
        forward.add(commands[i]);
      }
      else if(i % 5 == 1){
        backward.add(commands[i]);
      }
      else if(i % 5 == 2){
        right.add(commands[i]);
      }
      else if(i % 5 == 3){
        left.add(commands[i]);
      }
      else if(i % 5 == 4){
        stop.add(commands[i]);
      }
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                  (text) {
                return text == '/shrug' ? '¯\\_(?)_/¯' : text;
              }(_message.text.trim()),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            height: 50,
            decoration: BoxDecoration(
              color:
              _message.whom == clientID ? chatBotColor : Colors.grey,
              borderRadius: BorderRadius.circular(7.0),
            ),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: (isConnecting
            ? Text('Connecting chat to '.tr().toString() + widget.server.name + '...')
            : isConnected
            ? Text('Live chat with '.tr().toString() + widget.server.name)
            : Text('Chat log with '.tr().toString() + widget.server.name)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          onPressed: isConnected ? _listen : null,
          child: Icon(_isListening ? Icons.stop : Icons.mic),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
              child: TextHighlight(
                text: _text == '' ? "listening..".tr().toString() : _text,
                words: _highlights,
                textStyle: const TextStyle(
                  fontSize: 32.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            // backspacesCounter > 0
            //     ? _messageBuffer.substring(
            //     0, _messageBuffer.length - backspacesCounter)
            //     : _messageBuffer + dataString.substring(0, index),
            _text,
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        switch(text) {
          case '0':
            {
              text = 'Move Forward'.tr().toString();
              break;
            }
          case '1':
            {
              text = 'Move Backward'.tr().toString();
              break;
            }
          case '2':
            {
              text = 'Move Right'.tr().toString();
              break;
            }
          case '3':
            {
              text = 'Move Left'.tr().toString();
              break;
            }
          case '4':
            {
              text = 'Stop'.tr().toString();
              break;
            }
        }

        if(!isStopped || !text.contains('Stop')) {
          setState(() {
            messages.add(_Message(clientID, text));
          });
        }
        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void _listen() async {
    await load();

    ///Receive the voice commands from the user and comvert it to text
    ///then send it to the arduino as integers signals

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: context.locale.toString(),
          onResult: (val) => setState(() {
            _text = "";
            _text = val.recognizedWords;
            isStopped = false;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      moveServo();
    }
  }

  void moveServo() {
    for(int i = 0 ; i < forward.length ; i++){
      if(_text.contains(forward[i]) || _text.contains("امام") ){
        _sendMessage('0');
        break;
      }
      else if(_text.contains(backward[i])){
        _sendMessage("1");
        break;
      }
      else if(_text.contains(right[i])){
        _sendMessage("2");
        break;
      }
      else if(_text.contains(left[i])){
        _sendMessage("3");
        break;
      }
      else if(_text.contains(stop[i])){
        _sendMessage("4");
        break;
      }
    }
  }
}
