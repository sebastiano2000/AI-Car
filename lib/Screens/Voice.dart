import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:graduation_project/Screens/voiceControl.dart';
import 'package:graduation_project/Services/connection.dart';
import 'package:graduation_project/widgets/Constants.dart';

import 'navbar.dart';

class Voice extends StatelessWidget {

  static const String id = 'Voice';

  Voice(this.username, this.photo);

  String username;
  String photo;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        ///Check if the user is connected to Bluetooth if he is not
        ///connected it will show him an icon of the Bluetooth disabled on the page.
        future: FlutterBluetoothSerial.instance.requestEnable(),
        builder: (context, future) {
          if (future.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                height: double.infinity,
                child: Center(
                  child: Icon(
                    Icons.bluetooth_disabled,
                    size: 200.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            );

          } else {
            return Home(username,photo);
          }
        },
        // child: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class Home extends StatelessWidget {

  Home(this.username, this.photo);

  String username;
  String photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: buttonsColor,
        centerTitle: true,
        title: Text('Connection'),
      ),
      ///When the user choose the device which he want
      ///to connect it will send the Bluetooth device data
      ///to the control room page to communicate with.
      body: SelectBondedDevicePage(
        onChatPage: (device1) {
          BluetoothDevice device = device1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NavBar.Info(
                  server: device,
                  photo: photo,
                  username: username,
                  index: 1,
                );
              },
            ),
          );
        },
      ),
    );
  }
}