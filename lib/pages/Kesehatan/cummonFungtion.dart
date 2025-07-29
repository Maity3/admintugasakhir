import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CommonFunctions {
  // Fungsi untuk memilih hewan
  static Future<Map<String, dynamic>?> pilihHewan(BuildContext context, FirebaseDatabase database) async {
    DatabaseReference hewanRef = database.ref().child("hewan");
    DataSnapshot snapshot = await hewanRef.get();

    List<Map<String, dynamic>> hewanList = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> hewanData = snapshot.value as Map<dynamic, dynamic>;
      hewanData.forEach((key, value) {
        if (value['nomor_hewan'] != null) {
          hewanList.add({
            'id': key,
            'nomor_hewan': value['nomor_hewan'] ?? 'Tidak diketahui',
            'jenis_hewan': value['jenis_hewan'] ?? 'Tidak diketahui',
            'ownerId': value['ownerId'] ?? 'Tidak diketahui',
            'kandangid': value['kandangid'] ?? 'Tidak diketahui',
            'data': value,
          });
        }
      });
    }

    if (hewanList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada hewan yang tersedia')),
      );
      return null;
    }

    String? selectedHewan;
    Map<String, dynamic>? result;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Pilih Hewan"),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedHewan,
                      hint: Text("Pilih Hewan"),
                      isExpanded: true,
                      items: hewanList.map((Map<String, dynamic> hewan) {
                        return DropdownMenuItem<String>(
                          value: hewan['id'],
                          child: Text('${hewan['nomor_hewan']} - ${hewan['jenis_hewan']}'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedHewan = newValue;
                        });
                      },
                    ),
                    if (selectedHewan != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Hewan:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            ...hewanList
                                .where((hewan) => hewan['id'] == selectedHewan)
                                .map((hewan) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Nomor: ${hewan['nomor_hewan']}'),
                                        Text('Jenis: ${hewan['jenis_hewan']}'),
                                        Text('Owner ID: ${hewan['ownerId']}'),
                                      ],
                                    )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedHewan != null) {
                      var selectedHewanData = hewanList.firstWhere((hewan) => hewan['id'] == selectedHewan);
                      result = {
                        'id': selectedHewan,
                        'nomor_hewan': selectedHewanData['nomor_hewan'],
                        'jenis_hewan': selectedHewanData['jenis_hewan'],
                        'ownerId': selectedHewanData['ownerId'],
                        'data': selectedHewanData['data'],
                      };
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Pilih"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hewan dipilih: ${result!['nomor_hewan']}')),
      );
    }

    return result;
  }

  // Fungsi untuk memperbarui status hewan
  static Future<void> updateHewanStatus(String hewanId, String status, FirebaseDatabase database) async {
    Map<String, dynamic> updateData = {
      'kesehatan': status,
    };

    // Perbarui status di tabel hewan
    DatabaseReference hewanRef = database.ref().child("hewan/$hewanId");
    await hewanRef.update(updateData);

    // Perbarui status di tabel hewans
    DatabaseReference hewansRef = database.ref().child("hewans/$hewanId");
    await hewansRef.update(updateData);
  }

  // Fungsi untuk memindahkan hewan ke riwayat dan menghapus dari database utama
  static Future<void> moveHewanToHistoryAndDelete(
    String hewanId,
    Map<String, dynamic> hewanData,
    String nomorHewan,
    String jenisHewan,
    String ownerId,
    String alasanKeluar,
    Map<String, dynamic> additionalData,
    FirebaseDatabase database, {
    DateTime? tanggalKeluar, String? kandangid, String? kandangId,
  }) async {
    try {
      // 1. Ambil data lengkap hewan dari database
      DatabaseReference hewanRef = database.ref().child("hewan/$hewanId");
      DataSnapshot hewanSnapshot = await hewanRef.get();
      
      DatabaseReference hewansRef = database.ref().child("hewans/$hewanId");
      DataSnapshot hewansSnapshot = await hewansRef.get();

      Map<String, dynamic> finalHewanData = {};
      bool dataFound = false;

      if (hewanSnapshot.exists) {
        finalHewanData = Map<String, dynamic>.from(hewanSnapshot.value as Map);
        dataFound = true;
        print('Data ditemukan di tabel hewan');
      } else if (hewansSnapshot.exists) {
        finalHewanData = Map<String, dynamic>.from(hewansSnapshot.value as Map);
        dataFound = true;
        print('Data ditemukan di tabel hewans');
      } else if (hewanData.isNotEmpty) {
        // Gunakan data yang sudah disimpan sebelumnya
        finalHewanData = Map<String, dynamic>.from(hewanData);
        dataFound = true;
        print('Menggunakan data yang tersimpan sebelumnya');
      }

      if (!dataFound) {
        throw Exception('Data hewan tidak ditemukan di database');
      }

      // 2. Buat data untuk riwayat hewan dengan data yang tersedia
      Map<String, dynamic> riwayatData = {
        'original_hewan_id': hewanId,
        'nomor_hewan': finalHewanData['nomor_hewan'] ?? nomorHewan,
        'jenis_hewan': finalHewanData['jenis_hewan'] ?? jenisHewan,
        'ownerId': finalHewanData['ownerId'] ?? ownerId,
        'alasan_keluar': alasanKeluar, // 'Mati' atau 'Dijual'
        'tanggal_keluar': tanggalKeluar != null 
            ? DateFormat('dd-MM-yyyy').format(tanggalKeluar) 
            : null,
        'timestamp_moved': ServerValue.timestamp,
        ...additionalData, // Data tambahan seperti harga jual, penyebab kematian, dll
      };

      // Tambahkan field lain jika tersedia
      if (finalHewanData.containsKey('kandangid')) riwayatData['kandangid'] = finalHewanData['kandangid'];
      if (finalHewanData.containsKey('jenis_kelamin')) riwayatData['jenis_kelamin'] = finalHewanData['jenis_kelamin'];
      if (finalHewanData.containsKey('kategori')) riwayatData['kategori'] = finalHewanData['kategori'];
      if (finalHewanData.containsKey('kesehatan')) riwayatData['kesehatan'] = finalHewanData['kesehatan'];
      if (finalHewanData.containsKey('tanggal_masuk')) riwayatData['tanggal_masuk'] = finalHewanData['tanggal_masuk'];
      if (finalHewanData.containsKey('umur_hewan')) riwayatData['umur_hewan'] = finalHewanData['umur_hewan'];
      if (finalHewanData.containsKey('harga')) riwayatData['harga'] = finalHewanData['harga'];
      if (finalHewanData.containsKey('update_harga_info')) riwayatData['update_harga_info'] = finalHewanData['update_harga_info'];
      if (finalHewanData.containsKey('image_url')) riwayatData['image_url'] = finalHewanData['image_url'];

      // 3. Simpan ke riwayat hewan
      DatabaseReference riwayatRef = database.ref().child("riwayat_hewan").push();
      await riwayatRef.set(riwayatData);
      print('Data berhasil disimpan ke riwayat hewan');

      // 4. Hapus dari database utama
      if (hewanSnapshot.exists) {
        await hewanRef.remove();
        print('Data berhasil dihapus dari tabel hewan');
      }
      if (hewansSnapshot.exists) {
        await hewansRef.remove();
        print('Data berhasil dihapus dari tabel hewans');
      }

      print('Hewan berhasil dipindahkan ke riwayat dan dihapus dari database utama');

    } catch (e) {
      print('Error saat memindahkan hewan ke riwayat: $e');
      throw e;
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    Color confirmColor,
  ) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                result = false;
                Navigator.of(context).pop();
              },
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                result = true;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: confirmColor,
              ),
              child: Text("Ya"),
            ),
          ],
        );
      },
    );
    return result;
  }

  // Fungsi untuk validasi form
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Silakan masukkan $fieldName';
    }
    return null;
  }

  // Fungsi untuk validasi harga
  static String? validatePrice(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Silakan masukkan $fieldName';
    }
    if (double.tryParse(value) == null || double.parse(value) <= 0) {
      return 'Silakan masukkan $fieldName yang valid';
    }
    return null;
  }

  // Fungsi untuk format mata uang
  static String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  // Fungsi untuk menampilkan snackbar sukses
  static void showSuccessSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Fungsi untuk menampilkan snackbar error
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }
}