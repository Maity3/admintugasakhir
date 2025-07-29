import 'package:flutter/material.dart';

class homePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selamat Datang, admin sobaternak!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Image.asset(
              'assets/logo/sobaternak_splash.png', // Ganti dengan path gambar di asset Anda
              width: 400,
              height: 400,
            ),
          ],
        ),
      ),
    );
  }
}