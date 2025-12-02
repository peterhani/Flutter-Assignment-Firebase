import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

// 🔥 Your Firebase Web Config (from Firebase console)
const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: "AIzaSyBdtoQIvrkU_QMpwQeIaDVTlrchfuJk1w0",
  authDomain: "my-new-app-69f59.firebaseapp.com",
  projectId: "my-new-app-69f59",
  storageBucket: "my-new-app-69f59.firebasestorage.app",
  messagingSenderId: "527854943830",
  appId: "1:527854943830:web:a45d5a9e8fb842151505f7",
  // measurementId is optional and not provided, so we leave it out
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web using the config above
  await Firebase.initializeApp(
    options: firebaseWebOptions,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Assignment 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
