import 'package:dasaklunch/models/lunch.dart';
import 'package:dasaklunch/models/review.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:dasaklunch/components/auth_required_state.dart';
import 'package:dasaklunch/utils/constants.dart';
import 'package:intl/intl.dart';

class LunchePage extends StatefulWidget {
  final dynamic arguments;

  const LunchePage({Key? key, required this.arguments}) : super(key: key);

  @override
  _LunchePageState createState() => _LunchePageState();
}

class _LunchePageState extends AuthRequiredState<LunchePage> {
  late Lunch _lunch;
  late List<Review> _reviews;
  bool _loading = false;

  Future<void> _loadLunch() async {
    setState(() {
      _loading = true;
    });
    final response = await supabase
        .from("reviews")
        .select()
        .eq("lunch_id", _lunch.id)
        .execute();
    final error = response.error;
    if (error != null && response.status != 406) {
      context.showErrorSnackBar(message: error.message);
    }
    final data = response.data;
    if (data != null) {
      _reviews = List<Review>.from(data
          .map((review) => Review(
                id: review["id"],
                content: review["content"],
                date: DateTime.parse(review["created_at"]),
                imageUrl: review["image_url"],
              ))
          .toList());
    }
    setState(() {
      _loading = false;
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
    _lunch = widget.arguments['lunch'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oběd'),
      ),
      body: ListView(
        children: [
          Text(
            _lunch.name,
            style: const TextStyle(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          const Text(
            "Recenze:",
            textAlign: TextAlign.center,
          ),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _reviews.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Žádná recenze"),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _reviews
                          .map(
                            (review) => Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat("d.M.yyyy").format(review.date) +
                                        " - " +
                                        review.content,
                                  ),
                                  review.imageUrl != null
                                      ? Container(
                                          margin: EdgeInsets.all(8),
                                          padding: EdgeInsets.all(2),
                                          color: Colors.black,
                                          child:
                                              Image.network(review.imageUrl!),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
        ],
      ),
    );
  }
}
