import 'package:dasaklunch/components/lunches_list.dart';
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
  bool _authenticated = false;

  @override
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      setState(() {
        _authenticated = true;
      });
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
      body: _authenticated
          ? const LunchesList()
          : const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, "/create-review");
          Navigator.pushReplacementNamed(context, "/lunches");
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
