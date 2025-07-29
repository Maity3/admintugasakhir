import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DetailKesehatanPage extends StatefulWidget {
  final String nomorHewan;

  DetailKesehatanPage({required this.nomorHewan});

  @override
  _DetailKesehatanPageState createState() => _DetailKesehatanPageState();
}

class _DetailKesehatanPageState extends State<DetailKesehatanPage> {
  final DatabaseReference laporanKesehatanRef =
      FirebaseDatabase.instance.reference().child('laporan_kesehatan');
  final DatabaseReference hewanRef =
      FirebaseDatabase.instance.reference().child('hewan');
  final DatabaseReference hewansRef =
      FirebaseDatabase.instance.reference().child('hewans');
  
  Map<String, dynamic>? _laporanTerkini;
  String? _laporanTerkiniKey; // Menyimpan key dari laporan terkini
  List<Map<String, dynamic>> _riwayatKesehatan = [];
  TextEditingController _penangananController = TextEditingController();
  DateTime _tanggalSembuh = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDataKesehatan();
  }

  Future<void> _fetchDataKesehatan() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 1. Ambil semua laporan kesehatan berdasarkan nomor hewan
      DataSnapshot snapshotLaporan = await laporanKesehatanRef
          .orderByChild('nomor_hewan')
          .equalTo(widget.nomorHewan)
          .once()
          .then((snapshot) => snapshot.snapshot);

      // 2. Ambil data hewan untuk mendapatkan riwayat
      DataSnapshot snapshotHewan = await hewanRef
          .child(widget.nomorHewan)
          .once()
          .then((snapshot) => snapshot.snapshot);

      setState(() {
        _laporanTerkini = null;
        _laporanTerkiniKey = null;
        
        // Proses laporan kesehatan
        if (snapshotLaporan.exists && snapshotLaporan.value != null) {
          var data = snapshotLaporan.value as Map<dynamic, dynamic>;
          
          // Ekstrak semua laporan untuk hewan ini
          Map<String, Map<String, dynamic>> semuaLaporan = {};
          data.forEach((key, value) {
            if (value != null && value['nomor_hewan'] == widget.nomorHewan) {
              semuaLaporan[key.toString()] = Map<String, dynamic>.from(value);
            }
          });
          
          // Ambil semua laporan dan urutkan berdasarkan tanggal (terbaru dulu)
          var entries = semuaLaporan.entries.toList();
          entries.sort((a, b) {
            // Jika tanggal_sakit tidak ada, gunakan tanggal dummy lama
            DateTime dateA = a.value['tanggal_sakit'] != null
                ? DateFormat('yyyy-MM-dd').parse(a.value['tanggal_sakit'])
                : DateTime(2000, 1, 1);
            DateTime dateB = b.value['tanggal_sakit'] != null
                ? DateFormat('yyyy-MM-dd').parse(b.value['tanggal_sakit'])
                : DateTime(2000, 1, 1);
            return dateB.compareTo(dateA); // Terbaru dulu
          });
          
          // Cek apakah ada laporan dengan status "Sakit"
          var laporanSakitEntries = entries.where((entry) => 
              entry.value['status'] == 'Sakit' || entry.value['status'] == null).toList();
          
          if (laporanSakitEntries.isNotEmpty) {
            // Jika ada yang sakit, gunakan laporan terbaru dari yang sakit
            var entry = laporanSakitEntries.first;
            _laporanTerkini = entry.value;
            _laporanTerkiniKey = entry.key;
          } else if (entries.isNotEmpty) {
            // Jika tidak ada yang sakit, ambil laporan terbaru saja
            _laporanTerkini = entries.first.value;
            _laporanTerkiniKey = entries.first.key;
          }
        }

        // Proses riwayat kesehatan
        _riwayatKesehatan = [];
        
        // 3. Kelola riwayat kesehatan dari semua sumber
        List<Map<String, dynamic>> allHealthRecords = [];
        
        // 3a. Tambahkan riwayat dari database hewan (jika ada)
        if (snapshotHewan.exists && snapshotHewan.value != null) {
          var dataHewan = snapshotHewan.value as Map<dynamic, dynamic>;
          
          if (dataHewan.containsKey('riwayat_kesehatan') && 
              dataHewan['riwayat_kesehatan'] != null) {
            // Handle jika riwayat_kesehatan berupa List
            if (dataHewan['riwayat_kesehatan'] is List) {
              var riwayatList = dataHewan['riwayat_kesehatan'] as List;
              for (var item in riwayatList) {
                if (item != null) {
                  allHealthRecords.add(Map<String, dynamic>.from(item));
                }
              }
            } 
            // Handle jika riwayat_kesehatan berupa Map
            else if (dataHewan['riwayat_kesehatan'] is Map) {
              var riwayatMap = dataHewan['riwayat_kesehatan'] as Map;
              allHealthRecords.add(Map<String, dynamic>.from(riwayatMap));
            }
          }
        }
        
        // 3b. Tambahkan riwayat dari laporan yang sudah selesai (status Sehat)
        if (snapshotLaporan.exists && snapshotLaporan.value != null) {
          var data = snapshotLaporan.value as Map<dynamic, dynamic>;
          
          data.forEach((key, laporan) {
            if (laporan != null && 
                laporan['nomor_hewan'] == widget.nomorHewan && 
                laporan['status'] == 'Sehat' &&
                laporan['tanggal_sembuh'] != null) {
              
              // Buat objek riwayat dari laporan
              Map<String, dynamic> riwayatItem = Map<String, dynamic>.from(laporan);
              
              // Cek apakah sudah ada di daftar riwayat berdasarkan tanggal
              bool isDuplicate = allHealthRecords.any((record) {
                return record['tanggal_sakit'] == riwayatItem['tanggal_sakit'] &&
                       record['tanggal_sembuh'] == riwayatItem['tanggal_sembuh'];
              });
              
              if (!isDuplicate) {
                allHealthRecords.add(riwayatItem);
              }
            }
          });
        }
        
        // 3c. Urutkan semua riwayat berdasarkan tanggal terbaru
        allHealthRecords.sort((a, b) {
          DateTime dateA = a['tanggal_sakit'] != null 
              ? DateFormat('yyyy-MM-dd').parse(a['tanggal_sakit']) 
              : DateTime(2000, 1, 1);
          DateTime dateB = b['tanggal_sakit'] != null 
              ? DateFormat('yyyy-MM-dd').parse(b['tanggal_sakit']) 
              : DateTime(2000, 1, 1);
          return dateB.compareTo(dateA); // Terbaru dulu
        });
        
        _riwayatKesehatan = allHealthRecords;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching health data: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kesehatan: $e')),
      );
    }
  }

  Future<void> _updateHealthStatus() async {
    try {
      if (_laporanTerkini == null || _laporanTerkiniKey == null) {
        throw Exception("Tidak ada laporan untuk diperbarui");
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(_tanggalSembuh);
      String penangananText = _penangananController.text.trim();
      
      // Validasi data
      if (penangananText.isEmpty) {
        throw Exception("Penanganan tidak boleh kosong");
      }

      // 1. Update status di laporan_kesehatan menjadi Sehat
      await laporanKesehatanRef.child(_laporanTerkiniKey!).update({
        'status': 'Sehat',
        'tanggal_sembuh': formattedDate,
        'penanganan': penangananText,
      });

      // 2. Siapkan data riwayat kesehatan baru
      Map<String, dynamic> newRiwayat = {
        'tanggal_sakit': _laporanTerkini!['tanggal_sakit'],
        'tanggal_sembuh': formattedDate,
        'penanganan': penangananText,
        'keluhan': _laporanTerkini!['deskripsi_keluhan'],
        'gejala': _laporanTerkini!['gejala'],
        'biaya': _laporanTerkini!['biaya'],
        'jenis_hewan': _laporanTerkini!['jenis_hewan'],
      };

      // 3. Ambil data lengkap hewan saat ini
      DataSnapshot hewanSnapshot = await hewanRef
          .child(widget.nomorHewan)
          .once()
          .then((snapshot) => snapshot.snapshot);

      List<Map<String, dynamic>> riwayatList = [];
      
      // 4. Proses riwayat kesehatan yang sudah ada
      if (hewanSnapshot.exists && hewanSnapshot.value != null) {
        var dataHewan = hewanSnapshot.value as Map<dynamic, dynamic>;
        
        if (dataHewan.containsKey('riwayat_kesehatan') && 
            dataHewan['riwayat_kesehatan'] != null) {
          // Jika riwayat berupa List
          if (dataHewan['riwayat_kesehatan'] is List) {
            var existingRiwayat = dataHewan['riwayat_kesehatan'] as List;
            for (var item in existingRiwayat) {
              if (item != null) {
                riwayatList.add(Map<String, dynamic>.from(item));
              }
            }
          } 
          // Jika riwayat berupa Map
          else if (dataHewan['riwayat_kesehatan'] is Map) {
            var existingRiwayat = dataHewan['riwayat_kesehatan'] as Map;
            riwayatList.add(Map<String, dynamic>.from(existingRiwayat));
          }
        }
      }
      
      // 5. Tambahkan riwayat baru
      riwayatList.insert(0, newRiwayat);

      // 6. Update status kesehatan dan riwayat di hewan dan hewans
      await hewanRef.child(widget.nomorHewan).update({
        'kesehatan': 'Sehat',
        'riwayat_kesehatan': riwayatList,
      });

      await hewansRef.child(widget.nomorHewan).update({
        'kesehatan': 'Sehat',
        'riwayat_kesehatan': riwayatList,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status kesehatan berhasil diperbarui')),
      );
      
      // 7. Refresh data
      _fetchDataKesehatan();
      
      // 8. Reset controller
      _penangananController.clear();
      
    } catch (e) {
      print("Error updating health status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status kesehatan: $e')),
      );
    }
  }

  Future<void> _showUpdateDialog() async {
    _penangananController.clear(); // Reset controller sebelum dialog muncul
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status Kesehatan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _penangananController,
                decoration: InputDecoration(
                  labelText: 'Penanganan yang dilakukan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Tanggal Sembuh'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_tanggalSembuh)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _tanggalSembuh,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalSembuh = picked;
                    });
                    Navigator.pop(context);
                    _showUpdateDialog(); // Rebuild dialog dengan tanggal baru
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateHealthStatus();
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatKesehatanList() {
    if (_riwayatKesehatan.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada riwayat penyakit',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _riwayatKesehatan.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> riwayat = _riwayatKesehatan[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sakit: ${riwayat['tanggal_sakit'] ?? '-'} - Sembuh: ${riwayat['tanggal_sembuh'] ?? 'Belum sembuh'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(),
                _buildRiwayatField('Keluhan', riwayat['keluhan'] ?? riwayat['deskripsi_keluhan']),
                _buildRiwayatField('Jenis Hewan', riwayat['jenis_hewan']),
                _buildRiwayatField('Penanganan', riwayat['penanganan']),
                if (riwayat.containsKey('biaya') && riwayat['biaya'] != null)
                  _buildRiwayatField('Biaya', 'Rp ${riwayat['biaya'].toString()}'),
                if (riwayat.containsKey('gejala') && riwayat['gejala'] != null) ...[
                  SizedBox(height: 10),
                  Text(
                    'Gejala:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _formatGejala(riwayat['gejala']),
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiwayatField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Tidak ada data',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGejala(dynamic gejala) {
    if (gejala == null) return 'Tidak ada data';
    
    try {
      if (gejala is String) return gejala;
      
      if (gejala is Map) {
        return gejala.entries
            .where((e) => e.value == true)
            .map((e) => e.key.toString())
            .join(', ');
      }
      
      return gejala.toString()
          .replaceAll('true', '')
          .replaceAll('false', '')
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(',', ', ')
          .replaceAll(':', '');
    } catch (e) {
      return gejala.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current animal is sick based on the latest report
    bool isHewanSakit = _laporanTerkini != null && 
                       (_laporanTerkini!['status'] == 'Sakit' || _laporanTerkini!['status'] == null);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Kesehatan Hewan"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDataKesehatan,
            tooltip: 'Refresh Data',
          ),
          if (isHewanSakit)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _showUpdateDialog,
              tooltip: 'Update Status Kesehatan',
            ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDataKesehatan,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Kesehatan Terkini
                      Card(
                        elevation: 3,
                        color: isHewanSakit ? Colors.red.shade50 : Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isHewanSakit ? Icons.sick : Icons.check_circle, 
                                    color: isHewanSakit ? Colors.red : Colors.green,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Status Kesehatan Terkini',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(),
                              if (_laporanTerkini == null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Hewan dalam keadaan sehat',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Status'),
                                      subtitle: Text(
                                        isHewanSakit ? 'Sakit' : 'Sehat',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isHewanSakit ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Nomor Hewan'),
                                      subtitle: Text(_laporanTerkini!['nomor_hewan']),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Jenis Hewan'),
                                      subtitle: Text(_laporanTerkini!['jenis_hewan'] ?? 'Tidak Ada Data'),
                                    ),
                                    
                                    // Tampilkan detail jika status sakit
                                    if (isHewanSakit) ...[
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('Deskripsi Keluhan'),
                                        subtitle: Text(_laporanTerkini!['deskripsi_keluhan'] ?? 'Tidak Ada Deskripsi'),
                                      ),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('Tanggal Sakit'),
                                        subtitle: Text(_laporanTerkini!['tanggal_sakit'] ?? 'Tidak Ada Data'),
                                      ),
                                      if (_laporanTerkini!.containsKey('estimasi_sembuh') && 
                                          _laporanTerkini!['estimasi_sembuh'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Estimasi Sembuh'),
                                          subtitle: Text(_laporanTerkini!['estimasi_sembuh']),
                                        ),
                                      if (_laporanTerkini!.containsKey('gejala') && 
                                          _laporanTerkini!['gejala'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Gejala'),
                                          subtitle: Text(
                                            _formatGejala(_laporanTerkini!['gejala']),
                                          ),
                                        ),
                                      if (_laporanTerkini!.containsKey('biaya') && 
                                          _laporanTerkini!['biaya'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Estimasi Biaya'),
                                          subtitle: Text(
                                            'Rp ${_laporanTerkini!['biaya'].toString()}',
                                          ),
                                        ),
                                    ] 
                                    // Tampilkan info penanganan jika status sehat
                                    else if (!isHewanSakit) ...[
                                      if (_laporanTerkini!.containsKey('tanggal_sakit') && 
                                          _laporanTerkini!['tanggal_sakit'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Tanggal Sakit'),
                                          subtitle: Text(_laporanTerkini!['tanggal_sakit']),
                                        ),
                                      if (_laporanTerkini!.containsKey('tanggal_sembuh') && 
                                          _laporanTerkini!['tanggal_sembuh'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Tanggal Sembuh'),
                                          subtitle: Text(_laporanTerkini!['tanggal_sembuh']),
                                        ),
                                      if (_laporanTerkini!.containsKey('penanganan') && 
                                          _laporanTerkini!['penanganan'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Penanganan'),
                                          subtitle: Text(_laporanTerkini!['penanganan']),
                                        ),
                                      if (_laporanTerkini!.containsKey('deskripsi_keluhan') && 
                                          _laporanTerkini!['deskripsi_keluhan'] != null)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('Keluhan'),
                                          subtitle: Text(_laporanTerkini!['deskripsi_keluhan']),
                                        ),
                                    ],
                                  ],
                                ),
                              if (isHewanSakit)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: ElevatedButton.icon(
                                    onPressed: _showUpdateDialog,
                                    icon: Icon(Icons.medical_services),
                                    label: Text('Update Status Kesehatan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size(double.infinity, 45),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Riwayat Kesehatan
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Riwayat Kesehatan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildRiwayatKesehatanList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}