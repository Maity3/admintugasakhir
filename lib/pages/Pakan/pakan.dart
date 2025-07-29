import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sobatternak_admin_web/pages/Pakan/Detail_Pakan.dart';
import 'package:sobatternak_admin_web/pages/Pakan/pemberitahuan_pakan.dart';
import 'tambah_pakan_form.dart'; // Make sure to import your TambahPakanForm

class dataPakan extends StatefulWidget {
  @override
  _dataPakanState createState() => _dataPakanState();
}

class _dataPakanState extends State<dataPakan> {
  final DatabaseReference _pakanRef = FirebaseDatabase.instance.ref("pakan");
  List<Map<dynamic, dynamic>> _pakanList = [];

  @override
  void initState() {
    super.initState();
    _fetchPakanData();
  }

  Future<void> _fetchPakanData() async {
  _pakanRef.onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      setState(() {
        _pakanList = data.entries.map((entry) {
          // Mengambil key dan value dari setiap entry
          final key = entry.key;
          final value = entry.value as Map<dynamic, dynamic>;

          // Mengembalikan map dengan key dan value yang diinginkan
          return {
            'key': key,
            'deskripsi': value['deskripsi'],
            'harga_per_kilo': value['harga_per_kilo'],
            'jenis_pakan': value['jenis_pakan'],
            'quality_stock': value['quality_stock'],
            'tanggal_kedaluwarsa': value['tanggal_kedaluwarsa'],
          };
        }).toList();
      });
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Pakan'),
        actions: [
          IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => pemberitahuanPakan()),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to TambahPakanForm when the button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TambahPakanForm()),
              );
            },
          ),
        ],
      ),
      body: _pakanList.isEmpty
          ? Center(
              child: Text(
                'Data pakan belum tersedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
            )
           : ListView.builder(
              itemCount: _pakanList.length,
              itemBuilder: (context, index) {
                final pakan = _pakanList[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(pakan['jenis_pakan'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock Pakan: ${pakan['quality_stock'] ?? 0} Kg'),
                        Text('Harga perKilo: Rp ${pakan['harga_per_kilo'] ?? 0}'),
                        Text('Tanggal Kedaluwarsa: ${pakan['tanggal_kedaluwarsa'] ?? 'Tidak ada tanggal'}'),
                        Text('Deskripsi: ${pakan['deskripsi'] ?? 'Tidak ada deskripsi'}'),
                      ],
                    ),
                    onTap: () {
                      // Navigate to DetailPakanPage when the item is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPakanPage(pakanId: pakan['key'], pakan: {},),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}