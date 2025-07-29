import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sobatternak_admin_web/pages/Tagihan/history_tagihan.dart';
import 'dart:html' as html;


class TagihanPage extends StatefulWidget {
  @override
  _TagihanPageState createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('tagihan');
  List<Map<dynamic, dynamic>> tagihanList = [];

  @override
  void initState() {
    super.initState();
    _fetchTagihanData();
  }

  void _fetchTagihanData() async {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("Data dari Firebase: $data"); // Debugging
      if (data != null && data is Map) {
        setState(() {
          // Ekstrak data dari setiap kategori (kesehatan, pakan, perawatan)
          tagihanList = [];
          data.forEach((kategori, items) {
            if (items is Map) {
              items.forEach((key, value) {
                if (value is Map && value['status_pembayaran'] == "pending") {
                  value['key'] = key;
                  value['kategori'] = kategori;
                  tagihanList.add(value); // Tambahkan ke list
                }
              });
            }
          });
          print("Data yang difilter: $tagihanList"); // Debugging
        });
      } else {
        print("Data tidak ditemukan atau format tidak sesuai.");
      }
    }).onError((error) {
      print("Terjadi error: $error");
    });
  }

  Future<void> konfirmasiPembayaran(Map<dynamic, dynamic> dataTagihan) async {
  try {
    String kategori = dataTagihan['kategori'];
    String idTagihan = dataTagihan['key'];
    
    // 1. Update status di database tagihan
    await FirebaseDatabase.instance
        .ref()
        .child('tagihan')
        .child(kategori)
        .child(idTagihan)
        .update({
      'status_pembayaran': 'approve',
      'tanggal_pembayaran': DateTime.now().toIso8601String(),
    });

    // 2. Update status di database terkait berdasarkan kategori
    if (kategori == 'kesehatan') {
      // Ambil ID laporan kesehatan yang tersimpan
      String idLaporan = dataTagihan['laporan_id'] ?? '';
      if (idLaporan.isNotEmpty) {
        // Update status di laporan_kesehatan
        await FirebaseDatabase.instance
            .ref()
            .child('laporan_kesehatan')
            .child(idLaporan)
            .update({
          'status_pembayaran': 'approve',
        });
      }
    } 
    else if (kategori == 'perawatan') {
      String idKandang = dataTagihan['kandangId'] ?? '';
      String idRiwayat = dataTagihan['riwayat_id'] ?? '';
      if (idKandang.isNotEmpty && idRiwayat.isNotEmpty) {
        // Update status di riwayat_perawatan
        await FirebaseDatabase.instance
            .ref()
            .child('riwayat_perawatan')
            .child(idKandang)
            .child(idRiwayat)
            .update({
          'status_pembayaran': 'approve',
        });
      }
    }
    else if (kategori == 'hewan') {
      // Ambil nomor hewan dari data tagihan
      String nomorHewan = dataTagihan['nomor_hewan'] ?? '';
      if (nomorHewan.isNotEmpty) {
        // Update status di database hewan dan hewans
        // 1. Update di node 'hewan'
        final hewanRef = FirebaseDatabase.instance.ref().child('hewan');
        final snapshot = await hewanRef.orderByChild('nomor_hewan').equalTo(nomorHewan).once();
        
        if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
          final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
          // Ambil key dari hewan yang ditemukan
          String hewanKey = data.keys.first;
          
          // Update status dari pending ke approve
          await hewanRef.child(hewanKey).update({
            'status': 'approve',
          });
        }
        
        // 2. Update di node 'hewans'
        final hewansRef = FirebaseDatabase.instance.ref().child('hewans').child(nomorHewan);
        final hewansSnapshot = await hewansRef.once();
        
        if (hewansSnapshot.snapshot.value != null) {
          await hewansRef.update({
            'status': 'approve',
            'status_pembayaran': 'approve'
          });
        }
      }
    }

    // 3. Update status di database terkait lainnya (kode yang sudah ada)
    if (kategori == 'kesehatan') {
      // Ambil semua data laporan kesehatan
      final laporanKesehatanRef = FirebaseDatabase.instance
          .ref()
          .child('laporan_kesehatan');
      final laporanKesehatanSnapshot = await laporanKesehatanRef.once();
      if (laporanKesehatanSnapshot.snapshot.value != null) {
        final laporanKesehatanData = laporanKesehatanSnapshot.snapshot.value as Map<dynamic, dynamic>;
        laporanKesehatanData.forEach((key, value) async {
          if (value['status_pembayaran'] == 'pending') {
            // Update status di laporan_kesehatan
            await laporanKesehatanRef.child(key).update({
              'status_pembayaran': 'approve',
            });
          }
        });
      }
    } else if (kategori == 'perawatan') {
      // Ambil semua data riwayat perawatan
      final riwayatPerawatanRef = FirebaseDatabase.instance
          .ref()
          .child('riwayat_perawatan');
      final riwayatPerawatanSnapshot = await riwayatPerawatanRef.once();
      if (riwayatPerawatanSnapshot.snapshot.value != null) {
        final riwayatPerawatanData = riwayatPerawatanSnapshot.snapshot.value as Map<dynamic, dynamic>;
        riwayatPerawatanData.forEach((kandangId, value) {
          if (value is Map) {
            value.forEach((key, value) async {
              if (value['status_pembayaran'] == 'pending') {
                // Update status di riwayat_perawatan
                await riwayatPerawatanRef.child(kandangId).child(key).update({
                  'status_pembayaran': 'approve',
                });
              }
            });
          }
        });
      }
    }

    // Tampilkan pesan sukses
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran berhasil dikonfirmasi'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Tampilkan pesan error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal mengkonfirmasi pembayaran: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<Map<String, dynamic>?> _getHewanInfoFromNomor(String nomorHewan) async {
    try {
      // Query untuk mendapatkan data hewan berdasarkan nomor_hewan
      final hewanRef = FirebaseDatabase.instance.ref().child('hewan');
      final snapshot = await hewanRef.orderByChild('nomor_hewan').equalTo(nomorHewan).once();
      
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        // Ambil data hewan pertama yang ditemukan
        final hewanData = data.values.first;
        return {
          'jenis_hewan': hewanData['jenis_hewan'],
          'kandangId': hewanData['kandangid'] ?? hewanData['kandangId'],
        };
      }
      return null;
    } catch (e) {
      print('Error mengambil info hewan dari nomor: $e');
      return null;
    }
  }

  // Helper function untuk mendapatkan informasi hewan berdasarkan kandang ID
  Future<String> _getHewanInfo(String kandangId) async {
    try {
      // Cek jika input adalah format K-nomor, maka ini adalah nomor hewan
      if (kandangId.startsWith('K-')) {
        String nomorHewan = kandangId.substring(2);
        final hewanRef = FirebaseDatabase.instance.ref().child('hewan');
        final snapshot = await hewanRef.orderByChild('nomor_hewan').equalTo(nomorHewan).once();
        
        if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
          final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
          // Ambil data hewan pertama yang ditemukan
          final hewanData = data.values.first;
          return hewanData['jenis_hewan'] ?? 'Tidak diketahui';
        }
        return 'Tidak diketahui';
      }

      // Cari hewan berdasarkan kandangId
      final hewanRef = FirebaseDatabase.instance.ref().child('hewan');
      final snapshot = await hewanRef.orderByChild('kandangid').equalTo(kandangId).once();
      
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        // Ambil data hewan pertama yang ditemukan
        final hewanData = data.values.first;
        return hewanData['jenis_hewan'] ?? 'Tidak diketahui';
      }
      
      // Coba cari dengan kandangId (huruf besar/kecil bisa berbeda)
      final altSnapshot = await hewanRef.orderByChild('kandangId').equalTo(kandangId).once();
      if (altSnapshot.snapshot.value != null && altSnapshot.snapshot.value is Map) {
        final Map<dynamic, dynamic> data = altSnapshot.snapshot.value as Map<dynamic, dynamic>;
        final hewanData = data.values.first;
        return hewanData['jenis_hewan'] ?? 'Tidak diketahui';
      }
      
      return 'Tidak diketahui';
    } catch (e) {
      print('Error mengambil info hewan: $e');
      return 'Tidak diketahui';
    }
  }

  // Helper function untuk mendapatkan nama kandang
  Future<String> _getNamaKandang(String kandangId) async {
    try {
      // Cek jika input adalah format K-nomor, maka ini adalah nomor hewan
      if (kandangId.startsWith('K-')) {
        String nomorHewan = kandangId.substring(2);
        final hewanRef = FirebaseDatabase.instance.ref().child('hewan');
        final snapshot = await hewanRef.orderByChild('nomor_hewan').equalTo(nomorHewan).once();
        
        if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
          final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
          // Ambil data hewan pertama yang ditemukan
          final hewanData = data.values.first;
          String idKandang = hewanData['kandangid'] ?? hewanData['kandangId'] ?? 'N/A';
          
          // Dapatkan data kandang
          final kandangRef = FirebaseDatabase.instance.ref().child('kandang').child(idKandang);
          final kandangSnapshot = await kandangRef.once();
          
          if (kandangSnapshot.snapshot.value != null && kandangSnapshot.snapshot.value is Map) {
            final kandangData = kandangSnapshot.snapshot.value as Map<dynamic, dynamic>;
            return kandangData['nama_kandang'] ?? 'Kandang $idKandang';
          }
          return 'Kandang $idKandang';
        }
        return 'Kandang tidak diketahui';
      }

      final kandangRef = FirebaseDatabase.instance.ref().child('kandang').child(kandangId);
      final snapshot = await kandangRef.once();
      
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        String namaKandang = data['nama_kandang'] ?? 'Kandang $kandangId';
        return namaKandang;
      }
      return 'Kandang $kandangId';
    } catch (e) {
      print('Error mengambil nama kandang: $e');
      return 'Kandang $kandangId';
    }
  }

  // Helper function to get the reference path for different categories
  String _getReferencePath(String kategori, String key, Map<dynamic, dynamic> data) {
    switch (kategori) {
      case 'kesehatan':
        return 'laporan_kesehatan/$key';
      case 'perawatan':
        String kandangId = data['kandangId'] ?? '';
        return 'riwayat_perawatan/$kandangId/$key';
      default:
        return '';
    }
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
  
  // Helper function untuk mendapatkan deskripsi kategori
  String getKategoriDescription(String kategori) {
    switch(kategori) {
      case 'kesehatan':
        return 'Layanan Kesehatan';
      case 'pakan':
        return 'Pembelian Pakan';
      case 'perawatan':
        return 'Layanan Perawatan';
      case 'hewan':
        return 'Pembelian Hewan';
      default:
        return kategori ?? 'Lainnya';
    }
  }
  
  // Helper function untuk mendapatkan nilai harga berdasarkan kategori tagihan
  String getHargaByKategori(Map<dynamic, dynamic> data, String kategori) {
    switch (kategori) {
      case 'hewan':
        return data['harga']?.toString() ?? 'N/A';
      case 'pakan':
        return data['total_harga']?.toString() ?? 'N/A';
      case 'kesehatan':
        return data['biaya']?.toString() ?? 'N/A';
      case 'perawatan':
        return data['tarif']?.toString() ?? 'N/A';
      default:
        return 'N/A';
    }
  }
  
  // Helper function untuk mendapatkan ID kandang berdasarkan kategori
  String getKandangId(Map<dynamic, dynamic> data, String kategori) {
    switch (kategori) {
      case 'hewan':
      case 'pakan':
      case 'perawatan':
        return data['kandangId'] ?? data['kandangid'] ?? 'N/A';
      case 'kesehatan':
        // Untuk kesehatan, kita perlu mendapatkan kandangId berdasarkan nomor_hewan
        // Ini mungkin memerlukan query tambahan ke database hewan
        return 'K-' + (data['nomor_hewan'] ?? 'N/A');
      default:
        return 'N/A';
    }
  }
  
  // Helper function untuk mendapatkan detail perihal tagihan berdasarkan kategori
  String getPerihalByKategori(Map<dynamic, dynamic> data, String kategori) {
    switch (kategori) {
      case 'hewan':
        return 'Pembelian ${data['jenis_hewan'] ?? 'Hewan'} (${data['nomor_hewan'] ?? 'N/A'})'; 
      case 'pakan':
        return '${data['jenis_pakan'] ?? 'Pakan'} (${data['jumlah_kg'] ?? '0'} kg)';
      case 'kesehatan':
        return data['deskripsi_keluhan'] ?? 'Layanan Kesehatan';
      case 'perawatan':
        return data['perawatan'] ?? 'Layanan Perawatan';
      default:
        return 'N/A';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman Tagihan'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'History Tagihan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryTagihanPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Tagihan Menunggu Persetujuan',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Perihal')),
                  DataColumn(label: Text('Kandang')),
                  DataColumn(label: Text('Jenis Hewan')),
                  DataColumn(label: Text('Harga (Rp)')),
                  DataColumn(label: Text('Bukti Transaksi')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: tagihanList.map((tagihanData) {
                  String kategori = tagihanData['kategori'] ?? '';
                  
                  // Mendapatkan tanggal sesuai dengan kategori
                  String tanggal = '';
                  if (kategori == 'kesehatan') {
                    tanggal = tagihanData['tanggal_sakit'] ?? 'N/A';
                  } else if (kategori == 'pakan') {
                    tanggal = tagihanData['tanggal_permintaan'] ?? 'N/A';
                  } else if (kategori == 'perawatan') {
                    tanggal = tagihanData['tanggal'] ?? 'N/A';
                  } else if (kategori == 'hewan') {
                    tanggal = tagihanData['tanggal_permintaan'] ?? 'N/A';
                  } else {
                    tanggal = 'N/A';
                  }
                  
                  // Mendapatkan perihal
                  String perihal = getPerihalByKategori(tagihanData, kategori);
                  
                  // Mendapatkan ID kandang
                  String kandangId = getKandangId(tagihanData, kategori);
                  
                  // Mendapatkan harga
                  String hargaStr = getHargaByKategori(tagihanData, kategori);
                  String harga = hargaStr != 'N/A' 
                      ? formatRupiah(double.tryParse(hargaStr) ?? 0) 
                      : 'N/A';
                  
                  String kategoriDisplay = getKategoriDescription(kategori);
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(tanggal)),
                      DataCell(Text(kategoriDisplay)),
                      DataCell(Text(perihal)),
                      DataCell(
                        FutureBuilder<String>(
                          future: kandangId != 'N/A' ? _getNamaKandang(kandangId) : Future.value('N/A'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(strokeWidth: 2);
                            }
                            return Text(snapshot.data ?? kandangId);
                          }
                        )
                      ),
                      DataCell(
                        kategori == 'hewan' 
                            ? Text(tagihanData['jenis_hewan'] ?? 'N/A')
                            : FutureBuilder<String>(
                                future: kandangId != 'N/A' ? _getHewanInfo(kandangId) : Future.value('N/A'),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator(strokeWidth: 2);
                                  }
                                  return Text(snapshot.data ?? 'N/A');
                                }
                              )
                      ),
                      DataCell(Text(harga)),
                      DataCell(
                        tagihanData['bukti_pembayaran'] != null &&
                                tagihanData['bukti_pembayaran'].toString().isNotEmpty
                            ? TextButton.icon(
                                onPressed: () => _downloadImage(tagihanData['bukti_pembayaran']),
                                icon: Icon(Icons.download),
                                label: Text('Lihat Bukti'),
                              )
                            : Text('Belum ada bukti'),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: () => konfirmasiPembayaran(tagihanData),
                          child: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (tagihanList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Tidak ada tagihan yang menunggu persetujuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Format harga ke format Rupiah
  String formatRupiah(double amount) {
    // Format angka dengan pemisah ribuan
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';
    String result = amount.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
    return result;
  }
}