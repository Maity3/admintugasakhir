import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailLaporanPakan extends StatelessWidget {
  final int nomor; // Ubah menjadi int
  final String tanggal;
  final String pengirim;
  final String namaPelapor;
  final String pesan;
  final String hewanId; // Tambahkan ID hewan untuk referensi
  final String ownerId; // Tambahkan ownerId untuk referensi pengguna
  final String kandangId;
  final String pakanId;

  DetailLaporanPakan({
    required this.nomor,
    required this.tanggal,
    required this.pengirim,
    required this.namaPelapor,
    required this.pesan,
    required this.kandangId,
    required this.hewanId, // Tambahkan parameter untuk ID hewan
    required this.ownerId, // Tambahkan parameter untuk ownerId
    required this.pakanId,
  });

  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0), // Mengatur sudut melengkung
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadOnlyTextField('Nomor: $nomor'),
            SizedBox(height: 8),
            _buildReadOnlyTextField('Permintaan: $tanggal'),
            SizedBox(height: 8),
            _buildReadOnlyTextField('Jenis Pakan: $pengirim'),
            SizedBox(height: 8),
            _buildReadOnlyTextField('Pesan: $pesan'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _showActionDialog(context);
              },
              child: Text('Pilih Status'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildReadOnlyTextField(String text) {
    return TextField(
      controller: TextEditingController(text: text),
      readOnly: true,
      decoration: InputDecoration(
        border: UnderlineInputBorder(), // Garis bawah
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey), // Warna garis bawah saat aktif
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(184, 137, 220, 0.922),), // Warna garis bawah saat fokus
        ),
        contentPadding: EdgeInsets.only(bottom: 8.0), // Padding untuk menyesuaikan posisi teks
      ),
    );
  }

  void _showActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Tindakan'),
          content: DropdownButton<String>(
            hint: Text('Pilih Tindakan'),
            items: <String>['Setuju', 'Tolak'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue == 'Setuju') {
                _updateStatusToDimiliki(pakanId); // Panggil fungsi untuk mengupdate status
              } else if (newValue == 'Tolak') {
                _rejectPakan(); // Panggil fungsi untuk menolak dan menghapus data
              }
              Navigator.of(context).pop(); // Menutup dialog setelah memilih
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _updateStatusToDimiliki(String pakanId) async {
  // Memastikan pakanId tidak kosong
  if (pakanId.isNotEmpty) {
    // Ambil data pakan terlebih dahulu
    DataSnapshot pakanSnapshot = await _database.child('pakan').child(pakanId).get();
    
    if (pakanSnapshot.exists) {
      var pakanData = pakanSnapshot.value as Map<dynamic, dynamic>;
      int qualityStock = pakanData['quality_stock'] ?? 0; // Ambil quality_stock, default 0 jika tidak ada

      // Ambil jumlah_kg dari tabel pakans
      DataSnapshot pakansSnapshot = await _database.child('pakans').child(pakanId).get();
      
      if (pakansSnapshot.exists) {
        var pakansData = pakansSnapshot.value as Map<dynamic, dynamic>;
        int jumlahKg = pakansData['jumlah_kg'] ?? 0; // Ambil jumlah_kg, default 0 jika tidak ada

        // Kurangi quality_stock dengan jumlah_kg
        if (qualityStock >= jumlahKg) {
          qualityStock -= jumlahKg; // Mengurangi quality_stock dengan jumlah_kg

          // Update quality_stock di database
          await _database.child('pakan').child(pakanId).update({
            'quality_stock': qualityStock,
          }).then((_) async {
            print('Quality stock pakan berhasil diperbarui menjadi $qualityStock');

            // Update status di tabel pakans menjadi 'dimiliki'
            await _database.child('pakans').child(pakanId).update({
              'status': 'dimiliki',
              'status_pembayaran': 'approve' // Mengupdate status menjadi 'dimiliki'
            }).then((_) {
              print('Status pakans berhasil diperbarui menjadi dimiliki');
            }).catchError((error) {
              print('Error saat mengupdate status di pakans: $error');
            });
          }).catchError((error) {
            print('Error saat mengupdate quality stock di pakan: $error');
          });
        } else {
          print('Quality stock tidak cukup untuk mengurangi $jumlahKg');
        }
      } else {
        print('Data pakans tidak ditemukan untuk pakanId: $pakanId');
      }
    } else {
      print('Pakan tidak ditemukan');
    }
  } else {
    print('pakanId tidak boleh kosong');
  }
}
  void _rejectPakan() {
  // Memastikan pakanId dan pengirim tidak kosong
  if (pengirim.isNotEmpty && pakanId.isNotEmpty) {
    _database.child('pakans').child(pakanId).remove().then((_) {
      print('Data Pakan berhasil dihapus dari pengguna');
      _sendNotification('Pakan Anda telah ditolak'); // Mengirim notifikasi setelah Pakan ditolak
    }).catchError((error) {
      print('Error saat menghapus data Pakan dari pengguna: $error');
    });
  } else {
    print('PakanId atau pengirim tidak boleh kosong');
  }
}

  Future<void> _sendNotification(String message) async {
    String? fcmToken = await _getFcmToken(ownerId);
    if (fcmToken != null) {
      final url = 'https://fcm.googleapis.com/fcm/send';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'your_channel_id', // Ganti dengan server key Anda
      };
      final body = {
        'to': fcmToken,
        'notification': {
          'title': 'Notifikasi Hewan',
          'body': message,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Notifikasi berhasil dikirim');
      } else {
        print('Gagal mengirim notifikasi: ${response.body}');
      }
    } else {
      print('FCM token tidak ditemukan untuk ownerId: $ownerId');
    }
  }

  Future<String?> _getFcmToken(String ownerId) async {
    DataSnapshot snapshot = await _database.child('fcmTokens').child(ownerId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> tokenData = Map<String, dynamic>.from(snapshot.value as Map);
      return tokenData['token']; // Mengambil token dari data
    }
    return null; // Jika tidak ada token ditemukan
  }
}