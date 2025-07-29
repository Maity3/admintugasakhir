import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DetailPakanPage extends StatefulWidget {
  final String pakanId; // ID pakan yang diterima

  DetailPakanPage({required this.pakanId, required Map<String, dynamic> pakan});

  @override
  _DetailPakanPageState createState() => _DetailPakanPageState();
}

class _DetailPakanPageState extends State<DetailPakanPage> {
  final DatabaseReference _pakanRef = FirebaseDatabase.instance.ref("pakan");
  Map<dynamic, dynamic> pakanData = {};  // Inisialisasi dengan map kosong
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getPakanData();
  }

  // Mengambil data pakan dari Firebase berdasarkan pakanId
  Future<void> _getPakanData() async {
    try {
      final snapshot = await _pakanRef.child(widget.pakanId).get(); // Menggunakan pakanId yang diteruskan
      if (snapshot.exists) {
        setState(() {
          pakanData = snapshot.value as Map<dynamic, dynamic>;
          isLoading = false;
        });
      } else {
        // Jika data tidak ada
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pakan'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: TextEditingController(text: pakanData['jenis_pakan'] ?? 'N/A'),
                    decoration: InputDecoration(labelText: 'Jenis Pakan'),
                    readOnly: true, // Disable editing
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: '${pakanData['quality_stock'] ?? 0} Kg'),
                    decoration: InputDecoration(labelText: 'Stock Pakan'),
                    readOnly: true, // Disable editing
                  ),
                  TextField(
                    controller: TextEditingController(text: 'Rp ${pakanData['harga_per_kilo'] ?? 0}'),
                    decoration: InputDecoration(labelText: 'Harga per Kilo'),
                    readOnly: true, // Disable editing
                  ),
                  TextField(
                    controller: TextEditingController(text: pakanData['tanggal_kedaluwarsa'] ?? 'Tidak ada tanggal'),
                    decoration: InputDecoration(labelText: 'Tanggal Kedaluwarsa'),
                    readOnly: true, // Disable editing
                  ),
                  TextField(
                    controller: TextEditingController(text: pakanData['deskripsi'] ?? 'Tidak ada deskripsi'),
                    decoration: InputDecoration(labelText: 'Deskripsi Pakan'),
                    readOnly: true, // Disable editing
                  ),
                  
                  SizedBox(height: 20),
                  // Tabel Nutrisi Pakan
                  if (pakanData['nutrisi'] != null)
                    DataTable(
                      columns: [
                        DataColumn(label: Text('Nutrisi')),
                        DataColumn(label: Text('Kandungan')),
                      ],
                      rows: [
                        DataRow(cells: [
                          DataCell(Text('Protein Kasar (PK)')),
                          DataCell(Text('${pakanData['nutrisi']['PK']} %')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Serat Kasar (SK)')),
                          DataCell(Text('${pakanData['nutrisi']['SK']} %')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Energi Metabolik (EM)')),
                          DataCell(Text('${pakanData['nutrisi']['EM']} MJ/kg')),
                        ]),
                      ],
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Kembali ke halaman sebelumnya
                      Navigator.pop(context);
                    },
                    child: Text('Kembali'),
                  ),
                ],
              ),
            ),
    );
  }
}
