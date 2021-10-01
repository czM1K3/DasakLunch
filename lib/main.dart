import 'package:dasaklunch/pages/login_page.dart';
import 'package:dasaklunch/pages/lunch_page.dart';
import 'package:dasaklunch/pages/lunches_page.dart';
import 'package:dasaklunch/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  String supabaseUrl = dotenv.get("SUPABASE_URL");
  String supabaseAnonKey = dotenv.get("SUPABASE_ANON_KEY");

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(MaterialApp(
    title: "Dašák obědy",
    theme: ThemeData.dark().copyWith(
      primaryColor: Colors.green,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          onPrimary: Colors.white,
          primary: Colors.green,
        ),
      ),
    ),
    initialRoute: "/",
    routes: <String, WidgetBuilder>{
      "/": (_) => const SplashPage(),
      "/login": (_) => const LoginPage(),
      "/lunches": (_) => const LunchesPage(),
      "/lunch": (context) => LunchePage(
            arguments: ModalRoute.of(context)?.settings.arguments,
          ),
    },
  ));
}
