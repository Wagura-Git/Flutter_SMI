import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login/login_screen.dart'; // Import halaman login

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistem Manajemen Surat',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        // Anda bisa mengatur font global di sini
        fontFamily: 'Roboto',
      ),
      // Tentukan halaman pertama yang muncul (Halaman Login)
      home: const LoginScreen(),
    );
  }
}
