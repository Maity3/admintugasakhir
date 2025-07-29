import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailLaporanKandang extends StatelessWidget {
  final int nomor; // Ubah menjadi int
  final String tanggal;
  final String pengirim;
  final String namaPelapor;
  final String pesan;
  final String ownerId; // Tambahkan ownerId untuk referensi pengguna
  final String kandangId;

  DetailLaporanKandang({
    required this.nomor,
    required this.tanggal,
    required this.pengirim,
    required this.namaPelapor,
    required this.pesan,
    required this.kandangId,
    required this.ownerId, // Tambahkan parameter untuk ownerId
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
            _buildReadOnlyTextField('Kandang: $kandangId'),
            SizedBox(height: 8),
            _buildReadOnlyTextField('Nama Kandang: $pengirim'),
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
                _updateStatusToDimiliki(); // Panggil fungsi untuk mengupdate status
              } else if (newValue == 'Tolak') {
                _rejectKandang(); // Panggil fungsi untuk menolak dan menghapus data
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

  void _updateStatusToDimiliki() {
    if (kandangId.isNotEmpty) {
      _database.child('kandang').child(kandangId).update({'status': 'dimiliki'}).then((_) {
        print('Status kandang diupdate menjadi dimiliki');
        _database.child('users').child(ownerId).child('kandangs').child(kandangId).update({
          'status': 'dimiliki',
        }).then((_) {
          print('Status kandang diupdate di users/kandangs');
          _sendNotification('Kandang Anda telah disetujui'); // Mengirim notifikasi setelah status diupdate
        }).catchError((error) {
          print('Error saat mengupdate status di users/kandangs: $error');
        });
      }).catchError((error) {
        print('Error saat mengupdate status di kandang: $error');
      });
    } else {
      print('KandangId tidak boleh kosong');
    }
  }

  void _rejectKandang() {
    if (kandangId.isNotEmpty && ownerId.isNotEmpty) {
      _database.child('kandang').child(kandangId).update({
        'status': null,
        'ownerId': null,
      }).then((_) {
        print('Status, ownerId, dan kandangId berhasil dihapus dari kandang');
        _database.child('users').child(ownerId).child('kandangs').child(kandangId).remove().then((_) {
          print('Data kandang berhasil dihapus dari pengguna');
          _sendNotification('kandang Anda telah ditolak'); // Mengirim notifikasi setelah kandang ditolak
        }).catchError((error) {
          print('Error saat menghapus data kandang dari pengguna: $error');
        });
      }).catchError((error) {
        print('Error saat menghapus status kandang: $error');
      });
    } else {
      print('kandangId atau ownerId tidak boleh kosong');
    }
  }

  Future<void> _sendNotification(String message) async {
    String? fcmToken = await _getFcmToken(ownerId);
    if (fcmToken != null) {
      final url = 'https://fcm.googleapis.com/v1/projects/st-akhir/messages:send';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 104560182537285782875', // Ganti dengan server key Anda
      };
      final body = {
        'to': fcmToken,
        'notification': {
          'title': 'Notifikasi Kandang anda',
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
    DataSnapshot snapshot = await _database.child("users").child(ownerId).child("fcm_token").get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> tokenData = Map<String, dynamic>.from(snapshot.value as Map);
      return tokenData['token']; // Mengambil token dari data
    }
    return null; // Jika tidak ada token ditemukan
  }
}