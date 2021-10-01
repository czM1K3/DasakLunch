import 'package:dasaklunch/models/lunch.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:dasaklunch/components/auth_required_state.dart';
import 'package:dasaklunch/utils/constants.dart';

class LunchesPage extends StatefulWidget {
  const LunchesPage({Key? key}) : super(key: key);

  @override
  _LunchesPageState createState() => _LunchesPageState();
}

class _LunchesPageState extends AuthRequiredState<LunchesPage> {
  late List<Lunch> _lunches;
  bool _loading = false;

  Future<void> _loadLunches() async {
    setState(() {
      _loading = true;
    });
    final response = await supabase
        .from("lunches")
        .select()
        .order("name", ascending: true)
        .execute();
    final error = response.error;
    if (error != null && response.status != 406) {
      context.showErrorSnackBar(message: error.message);
    }
    final data = response.data;
    if (data != null) {
      _lunches = List<Lunch>.from(data.map((lunch) {
        return Lunch(id: lunch["id"], name: lunch["name"]);
      }));
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _loadLunches();
    }
  }

  @override
  void onUnauthenticated() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _signOut() async {
    final response = await supabase.auth.signOut();
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    }
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obědy'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        children: _loading
            ? [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                )
              ]
            : _lunches.map((lunch) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/lunch", arguments: {
                        "lunch": lunch,
                      });
                    },
                    child: Text(lunch.name),
                  ),
                );
              }).toList(),
      ),
    );
  }
}
