import 'package:flutter/material.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/pelaporanJual.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/pelaporanSakit.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/pelaporanhewanMati.dart';

class PelaporanKesehatanHewan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pelaporan Hewan'),
        backgroundColor: Color.fromRGBO(184, 137, 220, 0.922),
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Text(
              'Pilih Jenis Pelaporan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 40),

            // Card untuk Pelaporan Sakit
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PelaporanSakitPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        size: 50,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pelaporan Hewan Sakit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Laporkan hewan yang sedang sakit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 5),

            // Card untuk Pelaporan Mati
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PelaporanMatiPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Icon(
                        Icons.close,
                        size: 50,
                        color: Colors.red,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pelaporan Hewan Mati',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Laporkan hewan yang telah mati',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 5),

            // Card untuk Pelaporan Dijual
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PelaporanDijualPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 50,
                        color: Colors.green,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pelaporan Hewan Dijual',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Laporkan hewan yang telah dijual',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
