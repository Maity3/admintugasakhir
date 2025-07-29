import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailLaporanHewan extends StatelessWidget {
  final int nomor; // Ubah menjadi int
  final String tanggal;
  final String pengirim;
  final String namaPelapor;
  final String pesan;
  final String hewanId; // Tambahkan ID hewan untuk referensi
  final String ownerId; // Tambahkan ownerId untuk referensi pengguna
  final String kandangId;

  DetailLaporanHewan({
    required this.nomor,
    required this.tanggal,
    required this.pengirim,
    required this.namaPelapor,
    required this.pesan,
    required this.kandangId,
    required this.hewanId, // Tambahkan parameter untuk ID hewan
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
            _buildReadOnlyTextField('Tanggal: $tanggal'),
            SizedBox(height: 8),
            _buildReadOnlyTextField('ID: $pengirim'),
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
                _rejectHewan(); // Panggil fungsi untuk menolak dan menghapus data
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
    if (pengirim.isNotEmpty) {
      _database.child('hewan').child(pengirim).update({'status': 'dimiliki'}).then((_) {
        print('Status hewan diupdate menjadi dimiliki');
        _database.child('hewans').child(pengirim).update({
          'status': 'dimiliki',
        }).then((_) {
          print('Status hewan diupdate di users/kandangs/hewans');
          _sendNotification('Hewan Anda telah disetujui'); // Mengirim notifikasi setelah status diupdate
        }).catchError((error) {
          print('Error saat mengupdate status di users/kandangs/hewans: $error');
        });
      }).catchError((error) {
        print('Error saat mengupdate status di hewan: $error');
      });
    } else {
      print('hewanId tidak boleh kosong');
    }
  }

  void _rejectHewan() {
    if (pengirim.isNotEmpty && ownerId.isNotEmpty) {
      _database.child('hewan').child(pengirim).update({
        'status': null,
        'ownerId': null,
        'kandangId': null,
      }).then((_) {
        print('Status, ownerId, dan kandangId berhasil dihapus dari hewan');
        _database.child('users').child(ownerId).child('kandangs').child(kandangId).child('hewans').child(pengirim).remove().then((_) {
          print('Data hewan berhasil dihapus dari pengguna');
          _sendNotification('Hewan Anda telah ditolak'); // Mengirim notifikasi setelah hewan ditolak
        }).catchError((error) {
          print('Error saat menghapus data hewan dari pengguna: $error');
        });
      }).catchError((error) {
        print('Error saat menghapus status hewan: $error');
      });
    } else {
      print('hewanId atau ownerId tidak boleh kosong');
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