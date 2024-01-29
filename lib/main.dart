import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyTabView(),
    );
  }
}

class MyTabView extends StatefulWidget {
  const MyTabView({super.key});

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
          tabs: const [
            Tab(text: 'Read'),
            Tab(text: 'Write'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            decoration: buildBoxDecoration("assets/image/nfcreadimage.png"),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildText('Text: $text'),
                        buildText('URL: $url'),
                        buildText('URL: $url'),
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
            decoration: buildBoxDecoration('assets/image/nfcwriteimage.png'),
            child: Center(
              child: Column(
                children: [
                  buildPaddingandText(text1Controller,'Enter a text'),
                  buildPaddingandText(text2Controller,'Enter a URL'),
                  buildPaddingandText(text3Controller,'Enter phone number'),
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

  BoxDecoration buildBoxDecoration(String path) {
    return BoxDecoration(
            image: DecorationImage(
                image: AssetImage(path),
                fit: BoxFit.scaleDown),
          );
  }

  Padding buildPaddingandText(TextEditingController textEditingController, String text) {
    return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: text,
                    ),
                  ),
                );
  }

  Text buildText(String text) {
    return Text(
                        text,
                        style: const TextStyle(
                          fontSize: 20,
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
              showSnackBar(context,'Tag is not compatible with NDEF');
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
              // String result = String.fromCharCodes(sublist);
              // showSnackBar(context, result);
              // print(result);
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
  
}

showSnackBar(BuildContext context, String s) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(s),
      duration: const Duration(seconds: 2),
    ),
  );
}
