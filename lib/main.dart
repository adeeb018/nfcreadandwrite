import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:hex/hex.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyTabView(),
    );
  }
}

class MyTabView extends StatefulWidget {
  @override
  _MyTabViewState createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView>
    with SingleTickerProviderStateMixin {
  ValueNotifier<dynamic> result = ValueNotifier(null);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tab View Example'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tab 1'),
            Tab(text: 'Tab 2'),
            Tab(text: 'Tab 3'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: ElevatedButton(onPressed: () { _startNFCReading(); },
            child: Text('click here'),
          ),),
          Center(child: ElevatedButton(onPressed: () { _ndefWrite(); },
            child: Text('click here'),
          ),),
          Center(child: Text('Content for Tab 3')),
        ],
      ),
    );
  }

  void _startNFCReading() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();

      //We first check if NFC is available on the device.
      if (isAvailable) {
        //If NFC is available, start an NFC session and listen for NFC tags to be discovered.
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            Ndef? ndef = Ndef.from(tag);

            if (ndef == null) {
              print('Tag is not compatible with NDEF');
              return;
            }

            // Process NFC tag, When an NFC tag is discovered, print its data to the console.
            // debugPrint('NFC Tag Detected: ${tag.data}');

            // print(tag.data);
            // print(tag.data["ndef"]["cachedMessage"]["records"]);

            List<Object?> records =
                tag.data["ndef"]["cachedMessage"]["records"];

            int i = 0;
            int j = 3;
            for (Object? record in records) {
              print("NFC READ record");
              // record;
              List<int> asciiCodes =
                  tag.data["ndef"]["cachedMessage"]["records"][i]["payload"];
              i++;

              List<int> sublist =
                  List.from(asciiCodes.getRange(j, asciiCodes.length));
              j > 1 ? j = j - 2 : j;
              // showSnackBar(context, 'device not found on scan, scan again and wait for 5 seconds');
              // Convert ASCII codes to characters
              String result = String.fromCharCodes(sublist);
              // showSnackBar(context, result);
              print(result);
            }
            // Convert hexadecimal payload to bytes
            // List<int> asciiCodes = tag.data["ndef"]["cachedMessage"]["records"][0]["payload"];
            // Create a sublist excluding the first 3 element (ASCII 2)
            // List<int> sublist = List.from(asciiCodes.getRange(3, asciiCodes.length));

            // Convert ASCII codes to characters
            // String result = String.fromCharCodes(sublist);
            // print(result);
          },
        );
      } else {
        debugPrint('NFC not available.');
      }
    } catch (e) {
      debugPrint('Error reading NFC: $e');
    }
  }

//ndef write

  void _ndefWrite() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createText('Hello World!'),
        NdefRecord.createUri(Uri.parse('https://flutter.dev')),
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList('Hello'.codeUnits)),
        NdefRecord.createExternal(
            'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }

// Future<void> nfcCheck() async {
//   var availability = await FlutterNfcKit.nfcAvailability;
//   if (availability != NFCAvailability.available) {
//     log("NFC CHECK not available");
//   }
//   else {
//     log('NFC CHECK available');
//   }
//   try {
//     // timeout only works on Android, while the latter two messages are only for iOS
//     var tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10),
//         iosMultipleTagMessage: "Multiple tags found!",
//         iosAlertMessage: "Scan your tag");
//
//     var ndefAvailable = tag.ndefAvailable;
//     print('here');
//     print(tag.type);
//     NFCTag.type ==
//     if (tag.type == NFCTagType.mifare_classic){
//       await FlutterNfcKit.authenticateSector(0, keyA: "FFFFFFFFFFFF");
//
//       log("NFC READ inside tag type");
//        // read one sector, or
//       var data = await FlutterNfcKit.readBlock(0);
//       print(data);// read one block
//     }
// print(tag.ndefAvailable);
// if (ndefAvailable != null){
//   log("NFC CHECK inside first condition");
//   /// decoded NDEF records (see [ndef.NDEFRecord] for details)
//   /// `UriRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=U uri=https://github.com/nfcim/ndef`
//   for (var record in await FlutterNfcKit.readNDEFRecords(cached: false)) {
//     print(record.toString());
//   }
//
//   /// raw NDEF records (data in hex string)
//   /// `{identifier: "", payload: "00010203", type: "0001", typeNameFormat: "nfcWellKnown"}`
//   for (var record in await FlutterNfcKit.readNDEFRawRecords(
//       cached: false)) {
//     print(jsonEncode(record).toString());
//   }
// } else {
//     log("NFC READ else part");
// }

//
//   }catch(e){
//     print(e);
//   }
//
//
//
// }
}

showSnackBar(BuildContext context, String s) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(s),
      duration: Duration(seconds: 2),
    ),
  );
}
