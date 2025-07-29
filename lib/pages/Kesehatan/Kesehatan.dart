import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/Pelaporan_Kesehatan.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/detailKesehatan.dart';
import 'package:sobatternak_admin_web/pages/Kesehatan/pelaporan.dart';

class KesehatanHewanPage extends StatefulWidget {
  @override
  _KesehatanHewanPageState createState() => _KesehatanHewanPageState();
}

class _KesehatanHewanPageState extends State<KesehatanHewanPage> {
  final DatabaseReference hewanRef = FirebaseDatabase.instance.reference().child('hewan');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _hewanList = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  void _checkAuthAndFetchData() async {
    User? user = _auth.currentUser ;
    if (user != null) {
      print("Email pengguna: ${user.email}");
      if (user.email == 'admin1@gmail.com') {
        _fetchHewanData();
      } else {
        print("Pengguna tidak memiliki izin");
      }
    } else {
      print("Pengguna tidak terautentikasi");
    }
  }

  Future<void> _fetchHewanData() async {
    try {
      DataSnapshot snapshot = await hewanRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> hewanList = [];
        snapshot.children.forEach((child) {
          var hewanData = child.value as Map?;
          if (hewanData != null) {
            hewanList.add(Map<String, dynamic>.from(hewanData));
          }
        });
        setState(() {
          _hewanList = hewanList;
        });
        print("Data hewan diambil dari Firebase: $_hewanList");
      } else {
        print("Tidak ada data tersedia");
      }
    } catch (e) {
      print("Kesalahan mengambil data: $e");
    }
  }

  void _navigateToDetail(String nomorHewan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailKesehatanPage(nomorHewan: nomorHewan),
      ),
    );
  }

  void _navigateToPelaporan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PelaporanKesehatanHewan(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kesehatan Hewan'),
      ),
      body: _hewanList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _hewanList.length,
              itemBuilder: (context, index) {
                final hewan = _hewanList[index];
                return ListTile(
                  leading: Icon(Icons.pets),
                  title: Text("Jenis Hewan: ${hewan['jenis_hewan']}"),
                  subtitle: Text("Nomor Hewan: ${hewan['nomor_hewan']}"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _navigateToDetail(hewan['nomor_hewan']);
                    // Aksi ketika item ini ditekan, misalnya navigasi ke detail hewan
                    print("Hewan dipilih: ${hewan['jenis_hewan']}");
                  },
                );
              },
            ),
             floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPelaporan,
        child: Icon(Icons.report),
        tooltip: 'Laporkan Kesehatan Hewan',
      ),
    );
  }
}