import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:dasaklunch/components/auth_state.dart';
import 'package:dasaklunch/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends AuthState<LoginPage> {
  bool _isLoading = false;
  late final TextEditingController _emailController;

  Future<void> _signInMagicLink() async {
    setState(() {
      _isLoading = true;
    });
    final response = await supabase.auth.signIn(
        email: _emailController.text,
        options: AuthOptions(
            redirectTo:
                kIsWeb ? null : 'cz.madsoft.dasaklunch://login-callback/'));
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    } else {
      context.showSnackBar(message: 'Magický odkaz byl zaslán na Váš email!');
      _emailController.clear();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInGitHub() async {
    setState(() {
      _isLoading = true;
    });
    final response = await supabase.auth.signIn(
        provider: Provider.github,
        options: AuthOptions(
          redirectTo: kIsWeb ? null : 'cz.madsoft.dasaklunch://login-callback/',
        ));
    if (response.error != null) {
      context.showErrorSnackBar(message: response.error!.message);
    } else {
      await canLaunch(response.url!)
          ? launch(response.url!)
          : context.showErrorSnackBar(message: 'Nelze otevřít odkaz');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInFacebook() async {
    setState(() {
      _isLoading = true;
    });
    final response = await supabase.auth.signIn(
        provider: Provider.facebook,
        options: AuthOptions(
          redirectTo: kIsWeb ? null : 'cz.madsoft.dasaklunch://login-callback/',
        ));
    if (response.error != null) {
      context.showErrorSnackBar(message: response.error!.message);
    } else {
      await canLaunch(response.url!)
          ? launch(response.url!)
          : context.showErrorSnackBar(message: 'Nelze otevřít odkaz');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    _emailController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Přihlásit se')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Přihlásit se pomocí magického odkazu pomocí emailu'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInMagicLink,
            child: Text(_isLoading ? 'Načítání' : 'Zaslat magický odkaz'),
          ),
          const Divider(
            color: Colors.grey,
          ),
          const Center(child: Text("Jiné způsoby:")),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInGitHub,
            child: const Text("GitHub"),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _signInFacebook,
            child: const Text("Facebook"),
          ),
          Text(
            "Google nefunguje LOL",
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
