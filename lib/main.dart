import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sobatternak_admin_web/Homepage.dart';
import 'package:sobatternak_admin_web/Welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBVw2KFXwpEOUsCCkv85hp5RkGAu3S1y8k",
  authDomain: "st-akhir.firebaseapp.com",
  databaseURL: "https://st-akhir-default-rtdb.firebaseio.com",
  projectId: "st-akhir",
  storageBucket: "st-akhir.appspot.com",
  messagingSenderId: "722777072311",
  appId: "1:722777072311:web:3d8ccd381a0bfee54ea332",
  measurementId: "G-G4TWQZRNZY"
    )
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin App', // Ganti judul aplikasi sesuai keinginan Anda
      theme: ThemeData(
        primaryColor: Colors.grey, // Warna utama aplikasi (putih)
        scaffoldBackgroundColor: Colors.grey[200], // Warna latar belakang scaffold (abu-abu muda)
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
            .copyWith(secondary: Colors.grey), // Skema warna tambahan
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => Welcome(),
        '/home': (context) => Homepage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return Homepage();
        } else {
          return Welcome();
        }
      },
    );
  }
}