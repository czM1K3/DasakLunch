import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:dasaklunch/components/auth_required_state.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart';
import 'package:dasaklunch/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

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
  String? _imageExt;

  Future<void> _loadLunch() async {
    setState(() {
      _loading = true;
    });
    var response = await get(
        Uri.parse("https://delta-lunch-scrape.vercel.app/api/fetchLunch"),
        headers: {'Accept': 'application/json; charset=UTF-8'});
    if (response.statusCode == 200) {
      String today = DateFormat("yyyy-MM-dd").format(DateTime.now());

      Utf8Codec utf8 = const Utf8Codec();
      String decoded = utf8.decode(response.bodyBytes);
      List<dynamic> parsed = jsonDecode(decoded);

      List<String> lunchDates =
          List<String>.from(parsed.map((e) => e["date"]).toList());

      try {
        dynamic todayLunch = parsed[lunchDates.indexOf(today)];
        _lunches = List<String>.from(
            [todayLunch["lunch1"], todayLunch["lunch2"], todayLunch["lunch3"]]);
      } catch (e) {
        _lunches = [];
      }
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveReview(String lunchName, String review, Uint8List? image,
      String? imageExt) async {
    setState(() {
      _loading = true;
    });

    String? imageUrl = await _uploadImage(image, imageExt);

    int lunchId = await _getLunch(lunchName);
    PostgrestResponse response = await supabase.from("reviews").insert({
      "lunch_id": lunchId,
      "content": review,
      "user_uid": supabase.auth.currentUser!.id,
      "image_url": imageUrl,
    }).execute();
    if (response.error != null) {
      context.showErrorSnackBar(message: "Chyba při vytváření recenze");
    } else {
      Navigator.pop(context);
    }
    setState(() {
      _loading = false;
    });
  }

  Future<String?> _uploadImage(Uint8List? image, String? imageExt) async {
    if (image == null || imageExt == null) return null;

    Random rnd = Random();
    String newName = '${rnd.nextInt(1000000000)}.$imageExt';
    final uploadResponse =
        await supabase.storage.from("images").uploadBinary(newName, image);
    if (uploadResponse.error != null) {
      context.showErrorSnackBar(message: "Chyba při nahrávání obrázku");
      return null;
    }
    final response = supabase.storage.from("images").getPublicUrl(newName);
    return response.data;
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

  Future<void> _takePhoto(ImageSource imageSource) async {
    final XFile? image = await ImagePicker().pickImage(
      source: imageSource,
      maxHeight: 600,
      maxWidth: 600,
    );
    if (image == null) return;
    Uint8List buffer = await image.readAsBytes();
    setState(() {
      _image = buffer;
      _imageExt = image.path.split(".").last;
    });
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
              ? const Center(child: Text("Pro dnes nebylo nic nalezeno"))
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
                            onPressed: () {
                              _takePhoto(ImageSource.camera);
                            },
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _takePhoto(ImageSource.gallery);
                            },
                            child: const Icon(Icons.file_copy),
                          )
                        ],
                      ),
                    ),
                    _image != null
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            margin: const EdgeInsets.all(8),
                            color: Colors.black,
                            child: Image.memory(
                              _image!,
                            ),
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
                _saveReview(
                    _dropdownValue!, _textController.text, _image, _imageExt);
              },
              child: const Icon(Icons.send),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }
}
