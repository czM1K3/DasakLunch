import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:dasaklunch/components/auth_required_state.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart';
import 'package:dasaklunch/utils/constants.dart';
import 'package:image_picker/image_picker.dart';

class CreateReviewPage extends StatefulWidget {
  const CreateReviewPage({Key? key}) : super(key: key);

  @override
  _CreateReviewPageState createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends AuthRequiredState<CreateReviewPage> {
  bool _loading = false;
  List<String>? _lunches;
  String? _dropdownValue;
  late final TextEditingController _textController;
  Uint8List? _image;

  Future<void> _loadLunch() async {
    setState(() {
      _loading = true;
    });
    var response = await get(
        Uri.parse("https://delta-lunch-scrape.vercel.app/api/fetchLunch"),
        headers: {'Accept': 'application/json; charset=UTF-8'});
    if (response.statusCode == 200) {
      String today = DateFormat("yyyy-MM-dd").format(DateTime.now());
      today = "2021-10-04";

      Utf8Codec utf8 = const Utf8Codec();
      String decoded = utf8.decode(response.bodyBytes);
      List<dynamic> parsed = jsonDecode(decoded);

      List<String> lunchDates =
          List<String>.from(parsed.map((e) => e["date"]).toList());

      dynamic todayLunch = parsed[lunchDates.indexOf(today)];
      _lunches = List<String>.from(
          [todayLunch["lunch1"], todayLunch["lunch2"], todayLunch["lunch3"]]);
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveReview(String lunchName, String review) async {
    setState(() {
      _loading = true;
    });
    int lunchId = await _getLunch(lunchName);
    PostgrestResponse response = await supabase.from("reviews").insert({
      "lunch_id": lunchId,
      "content": review,
      "user_uid": supabase.auth.currentUser!.id,
    }).execute();
    if (response.status != 200) {
      context.showErrorSnackBar(message: "Něco se pokazilo");
    } else {
      setState(() {
        _loading = false;
      });
      Navigator.pop(context);
    }
  }

  Future<int> _getLunch(String lunchName) async {
    PostgrestResponse initialResult =
        await supabase.from("lunches").select().eq("name", lunchName).execute();
    if (!initialResult.data.isEmpty) {
      return initialResult.data[0]["id"];
    }

    await supabase.from("lunches").insert({
      "name": lunchName,
    }).execute();

    PostgrestResponse createdResult =
        await supabase.from("lunches").select().eq("name", lunchName).execute();

    return createdResult.data[0]["id"];
  }

  Future<Uint8List?> _takePhoto(ImageSource imageSource) async {
    final XFile? image = await ImagePicker().pickImage(
      source: imageSource,
      maxHeight: 600,
      maxWidth: 600,
    );
    if (image == null) return null;
    Uint8List buffer = await image.readAsBytes();
    return buffer;
  }

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _loadLunch();
    }
  }

  @override
  void onUnauthenticated() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> lunches = _lunches ?? [];
    if (_dropdownValue == null && lunches.isNotEmpty) {
      _dropdownValue = lunches.first;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vytvořit recenzi'),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            )
          : lunches.isEmpty
              ? const Text("Pro dnes nebylo nic nalezeno")
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: DropdownButton(
                        items: lunches
                            .map((lunch) => DropdownMenuItem(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(lunch),
                                  ),
                                  value: lunch,
                                ))
                            .toList(),
                        value: _dropdownValue,
                        elevation: 16,
                        onChanged: (String? newValue) {
                          setState(() {
                            _dropdownValue = newValue;
                          });
                        },
                        itemHeight: 70,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        controller: _textController,
                        decoration: InputDecoration(
                          labelText: 'Recenze',
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          )),
                          floatingLabelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            child: const Icon(Icons.camera),
                            onPressed: () async {
                              Uint8List? image =
                                  await _takePhoto(ImageSource.camera);
                              setState(() {
                                _image = image;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Uint8List? image =
                                  await _takePhoto(ImageSource.gallery);
                              setState(() {
                                _image = image;
                              });
                            },
                            child: const Icon(Icons.file_copy),
                          )
                        ],
                      ),
                    ),
                    _image != null
                        ? Image.memory(
                            _image!,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Text("Žádný obrázek není bybrán"),
                          ),
                  ],
                ),
      floatingActionButton: _loading || lunches.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (_dropdownValue == null) {
                  context.showErrorSnackBar(message: "Musíte vybrat typ obědu");
                  return;
                }
                if (_textController.text.isEmpty) {
                  context.showErrorSnackBar(
                      message: "Musíte vyplnit obsah recenze");
                  return;
                }
                _saveReview(_dropdownValue!, _textController.text);
              },
              child: const Icon(Icons.send),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }
}
