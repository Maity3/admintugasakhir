import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html;


class HistoryTagihanPage extends StatefulWidget {
  @override
  _HistoryTagihanPageState createState() => _HistoryTagihanPageState();
}

class _HistoryTagihanPageState extends State<HistoryTagihanPage> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('tagihan');
  List<Map<dynamic, dynamic>> historyList = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  void _fetchHistoryData() async {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          historyList = [];
          data.forEach((kategori, items) {
            if (items is Map) {
              items.forEach((key, value) {
                if (value is Map && value['status_pembayaran'] == "approve") {
                  value['key'] = key;
                  value['kategori'] = kategori;
                  historyList.add(value);
                }
              });
            }
          });
          // Sort berdasarkan tanggal pembayaran (terbaru di atas)
          historyList.sort((a, b) {
            String dateA = a['tanggal_pembayaran'] ?? '';
            String dateB = b['tanggal_pembayaran'] ?? '';
            return dateB.compareTo(dateA);
          });
        });
      }
    }).onError((error) {
      print("Error fetching data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data history: $error')),
      );
    });
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Tampilkan indikator loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16),
              Text('Sedang membuka bukti pembayaran...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Buka gambar di tab baru
      html.window.open(imageUrl, '_blank');

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bukti pembayaran berhasil dibuka di tab baru'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Perbarui UI secara langsung
      setState(() {});
    } catch (e) {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka bukti pembayaran: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Tagihan'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Tanggal Pembayaran')),
            DataColumn(label: Text('Perihal')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Nominal')),
            DataColumn(label: Text('Bukti Transaksi')),
          ],
          rows: historyList.map((historyData) {
            String tanggalPembayaran = historyData['tanggal_pembayaran'] ?? 'N/A';
            
            String perihal = historyData['deskripsi_keluhan'] ?? 
                           historyData['jenis_pakan'] ?? 
                           historyData['perawatan'] ?? 
                           historyData['nomor_hewan'] ?? 'N/A';

            String kategori = historyData['kategori'] ?? 'N/A';
            
            String nominal = '';
            if (historyData['biaya'] != null) {
              nominal = 'Rp ${historyData['biaya']}';
            } else if (historyData['total_harga'] != null) {
              nominal = 'Rp ${historyData['total_harga']}';
            } else if (historyData['tarif'] != null) {
              nominal = 'Rp ${historyData['tarif']}';
            } else if (historyData['harga'] != null) {
              nominal = 'Rp ${historyData['harga']}';
            };

            return DataRow(
              cells: [
                DataCell(Text(tanggalPembayaran)),
                DataCell(Text(perihal)),
                DataCell(Text(kategori)),
                DataCell(Text(nominal)),
                DataCell(
                  historyData['bukti_pembayaran'] != null &&
                          historyData['bukti_pembayaran'].toString().isNotEmpty
                      ? TextButton.icon(
                          onPressed: () => _downloadImage(historyData['bukti_pembayaran']),
                          icon: Icon(Icons.download),
                          label: Text('Lihat Bukti'),
                        )
                      : Text('Belum ada bukti'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}