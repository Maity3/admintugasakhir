// lib/Homepage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/Kesehatan.dart';
import 'package:sobatternak_admin_web/pages/Pakan/pakan.dart';
import 'package:sobatternak_admin_web/Welcome.dart'; // Sesuaikan dengan lokasi Welcome.dart
import 'package:sobatternak_admin_web/pages/Hewan/Hewan.dart';
import 'package:sobatternak_admin_web/pages/Hewan/Tambah_Hewan.dart';
import 'package:sobatternak_admin_web/pages/Kandang/Data_Kandang.dart';
import 'package:sobatternak_admin_web/pages/Kandang/Tambah_Kandang_Form.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/Pelaporan_Kesehatan.dart';
import 'package:sobatternak_admin_web/pages/Kandang/perawatanKandang.dart';
import 'package:sobatternak_admin_web/pages/Tagihan/tagihan.dart';
import 'package:sobatternak_admin_web/pages/User/User.dart';
import 'package:sobatternak_admin_web/pages/home/homePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sobat Ternak Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Homepage(),
      routes: {
        '/login': (context) => Welcome(), // Ganti dengan halaman login Anda
      },
    );
  }
}

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectedIndex = 0;
  final List<Widget> pages = [
    homePage(), 
    UserPage(),
    DataKandangPage(),
    HewanPage(kandangId: 'someId',),
    dataPakan(),
    KesehatanHewanPage(),// Halaman Home
    TagihanPage()
     // Halaman Data User (sebelumnya Data Kandang)
  ];

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(176, 105, 230, 0.922),
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset(
              'assets/logo/sobat_ternak.png',
              height: 30.0,
            ),
            SizedBox(width: 8.0),
            Text(
              'Admin',
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: SizedBox(),
            ),
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                // Aksi saat ikon avatar diklik (misalnya, navigasi ke profil pengguna)
              },
            ),
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'Logout') {
                  _handleLogout(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Logout',
                  child: Text('Logout'),
                ),
              ],
              icon: Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 250.0, // Atur lebar sidebar
            color: Colors.blueGrey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'SELAMAT DATANG',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Divider(color: Colors.white),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem('Home', Icons.home, 0),
                      _buildMenuItem('Data User', Icons.person, 1),
                      _buildMenuItem('Data Kandang', Icons.home_work, 2),
                      _buildMenuItem('Data Hewan', Icons.pets, 3),
                      _buildMenuItem('Data Pakan', Icons.food_bank, 4),
                      _buildMenuItem('Laporan Kesehatan Hewan', Icons.medical_information, 5),
                      _buildMenuItem('Tagihan', Icons.money, 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.0),
          Container(
            width: 4.0,
            color: Color.fromARGB(255, 224, 219, 219),
          ),
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}