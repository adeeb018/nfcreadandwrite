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
  String text = '';
  String url = '';
  String ph = '';

  final text1Controller = TextEditingController();
  final text2Controller = TextEditingController();
  final text3Controller = TextEditingController();

  ValueNotifier<dynamic> result = ValueNotifier(null);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('NFC Read and Write'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Read'),
            const Tab(text: 'Write'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/image/nfcreadimage.png"),
                  fit: BoxFit.scaleDown),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Text: $text',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'URL: $url',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Phone number: $ph',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _startNFCReading();
                          },
                          child: const Text('click to Scan'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
            image: DecorationImage(
            image: AssetImage("assets/image/nfcwriteimage.png"),
            fit: BoxFit.scaleDown),
          ),
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TextField(
                      controller: text1Controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a text',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: TextField(
                      controller: text2Controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter url',
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: TextField(
                      controller: text3Controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter phone number',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 200.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _ndefWrite(text1Controller.text, text2Controller.text,
                            text3Controller.text);
                      },
                      child: const Text('click to write'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

            List<Object?> records =
                tag.data["ndef"]["cachedMessage"]["records"];

            int i = 0;
            int j = 3;
            // print(records);
            for (Object? record in records) {
              print("NFC READ record");
              // record;
              // here we create a list which can can hold payload data in hex format
              List<int> asciiCodes =
                  tag.data["ndef"]["cachedMessage"]["records"][i]["payload"];
              // here sublist is used to delete unwanted hex elements from payload data
              List<int> sublist;
              //checking if type format is 1 and index is 0 then we need to remove (,en) from start
              if (tag.data["ndef"]["cachedMessage"]["records"][i]
                              ["typeNameFormat"]
                          .toString() ==
                      "1" &&
                  i == 0) {
                sublist = List.from(asciiCodes.getRange(j, asciiCodes.length));
                text = String.fromCharCodes(sublist);
              }
              // here the j value for url is retrieved by giving j=1
              else if (i == 1) {
                j = 1;
                sublist = List.from(asciiCodes.getRange(j, asciiCodes.length));
                url = String.fromCharCodes(sublist);
              }
              // others will have to start from 0
              else {
                j = 0;
                sublist = List.from(asciiCodes.getRange(j, asciiCodes.length));
                ph = String.fromCharCodes(sublist);
              }
              i++;

              // Convert ASCII codes to characters
              String result = String.fromCharCodes(sublist);
              // showSnackBar(context, result);
              print(result);
            }
            setState(() {});
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

  void _ndefWrite(String text, String url, String ph) {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createText(text),
        NdefRecord.createUri(Uri.parse(url)),
        NdefRecord.createMime('text/plain', Uint8List.fromList(ph.codeUnits)),
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
      duration: const Duration(seconds: 2),
    ),
  );
}
