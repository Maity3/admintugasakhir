import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import untuk ImagePicker
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PelaporanKesehatanHewanPage extends StatefulWidget {
  @override
  _PelaporanKesehatanHewanPageState createState() =>
      _PelaporanKesehatanHewanPageState();
}

class _PelaporanKesehatanHewanPageState
    extends State<PelaporanKesehatanHewanPage> {
  final _formKey = GlobalKey<FormState>();
  int _estimasiBiayaPerawatan = 0;
  String _keluhan = '';
  String? _imageUrl;
  String? _imageName;
  String? _selectedHewanId;
  String? _selectedHewanNomor;
  String? _selectedHewanOwnerId;
  String? _selectedHewanJenis;
  Map<String, dynamic>? _selectedHewanData; // Store complete hewan data
  bool _isUploading = false;
  DateTime _tanggalSakit = DateTime.now();
  DateTime? _estimasiSembuh;
  DateTime? _tanggalMati;
  DateTime? _tanggalDijual; // Tambahan untuk tanggal dijual
  String _statusHewan = 'Sakit'; // Default status
  String _penyebabKematian = ''; // Penyebab kematian
  String _penanganan = ''; // Penanganan yang diberikan
  double _hargaJual = 0; // Harga jual hewan
  String _keteranganJual = ''; // Keterangan penjualan
  
  Map<String, bool> _gejala = {
    'Pneumonia': false,
    'Cacingan': false,
    'Kaki pincang': false,
    'Penyakit Mulut dan Kuku (PMK)': false,
    'Kejang': false,
    'Scabies (Mange)': false,
    'Distokia (Gangguan kelahiran)': false,
    'Gejala Lain': false,
  };

  Map<String, int> _hargaGejala = {
    'Pneumonia': 70000,
    'Cacingan': 40000,
    'Kaki pincang': 150000,
    'Penyakit Mulut dan Kuku (PMK)': 50000,
    'Kejang': 60000,
    'Scabies (Mange)': 35000,
    'Distokia (Gangguan kelahiran)': 80000,
    'Gejala Lain': 0,
  };

  TextEditingController _tanggalSakitController = TextEditingController();
  TextEditingController _estimasiSembuhController = TextEditingController();
  TextEditingController _tanggalMatiController = TextEditingController();
  TextEditingController _tanggalDijualController = TextEditingController(); // Tambahan controller
  TextEditingController _penyebabKematianController = TextEditingController();
  TextEditingController _penangananController = TextEditingController();
  TextEditingController _hargaJualController = TextEditingController(); // Controller untuk harga jual
  TextEditingController _keteranganJualController = TextEditingController(); // Controller untuk keterangan jual

  final FirebaseDatabase _database =
      FirebaseDatabase.instance; // Instance Firebase Database

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Flutter Web
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files?.length == 1) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files![0]);
          reader.onLoadEnd.listen((e) async {
            setState(() {
              _isUploading = true;
            });

            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('hewan_images/${files[0].name}');
              final uploadTask = storageRef.putBlob(files[0]);
              final snapshot = await uploadTask.whenComplete(() {});
              final imageUrl = await snapshot.ref.getDownloadURL();

              setState(() {
                _imageUrl = imageUrl;
                _imageName = files[0].name;
                _isUploading = false;
              });
            } catch (e) {
              setState(() {
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengunggah gambar: $e')));
            }
          });
        }
      });
    } else {
      // Flutter Mobile
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('hewan_images/${image.name}');
          await storageRef.putFile(File(image.path));
          final imageUrl = await storageRef.getDownloadURL();

          setState(() {
            _imageUrl = imageUrl;
            _imageName = image.name;
            _isUploading = false;
          });
        } catch (e) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah gambar: $e')));
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025, 12, 31), // Sesuaikan lastDate jika perlu
    );
    if (picked != null) {
      setState(() {
        if (controller == _estimasiSembuhController) {
          if (picked.isBefore(_tanggalSakit)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Estimasi sembuh tidak boleh sebelum tanggal sakit')),
            );
            return;
          }
          _estimasiSembuh = picked;
        } else if (controller == _tanggalMatiController) {
          if (picked.isBefore(_tanggalSakit)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tanggal kematian tidak boleh sebelum tanggal sakit')),
            );
            return;
          }
          _tanggalMati = picked;
        } else if (controller == _tanggalDijualController) {
          _tanggalDijual = picked;
        } else if (controller == _tanggalSakitController) {
          _tanggalSakit = picked;
        }
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  String? ownerId; // Variabel untuk menyimpan ownerId
  String? kandangId; // Variabel untuk menyimpan kandangId
  String? selectedHewanId; // ID hewan yang dipilih

  // Fungsi untuk memperbarui status hewan
  Future<void> updateHewanStatus(String status) async {
    if (_selectedHewanId != null) {
      Map<String, dynamic> updateData = {
        'kesehatan': status,
      };

      // Tambahkan data khusus untuk status dijual
      if (status == 'Dijual') {
        updateData['harga_jual'] = _hargaJual;
        updateData['keterangan_jual'] = _keteranganJual;
        updateData['tanggal_dijual'] = _tanggalDijual != null 
            ? DateFormat('dd-MM-yyyy').format(_tanggalDijual!) 
            : null;
      }

      // Perbarui status di tabel hewan
      DatabaseReference hewanRef = _database.ref().child("hewan/$_selectedHewanId");
      await hewanRef.update(updateData);

      // Perbarui status di tabel hewans
      DatabaseReference hewansRef = _database.ref().child("hewans/$_selectedHewanId");
      await hewansRef.update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status hewan berhasil diperbarui menjadi: $status')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data hewan tidak lengkap.')),
      );
    }
  }

  // Fungsi untuk memindahkan hewan ke riwayat dan menghapus dari database utama
  Future<void> moveHewanToHistoryAndDelete(String reason, Map<String, dynamic> additionalData) async {
    if (_selectedHewanId == null) {
      throw Exception('ID hewan tidak tersedia');
    }

    try {
      // 1. Ambil data lengkap hewan dari database
      DatabaseReference hewanRef = _database.ref().child("hewan/$_selectedHewanId");
      DataSnapshot hewanSnapshot = await hewanRef.get();
      
      DatabaseReference hewansRef = _database.ref().child("hewans/$_selectedHewanId");
      DataSnapshot hewansSnapshot = await hewansRef.get();

      Map<String, dynamic> hewanData = {};
      bool dataFound = false;

      if (hewanSnapshot.exists) {
        hewanData = Map<String, dynamic>.from(hewanSnapshot.value as Map);
        dataFound = true;
        print('Data ditemukan di tabel hewan');
      } else if (hewansSnapshot.exists) {
        hewanData = Map<String, dynamic>.from(hewansSnapshot.value as Map);
        dataFound = true;
        print('Data ditemukan di tabel hewans');
      } else if (_selectedHewanData != null) {
        // Gunakan data yang sudah disimpan sebelumnya
        hewanData = Map<String, dynamic>.from(_selectedHewanData!);
        dataFound = true;
        print('Menggunakan data yang tersimpan sebelumnya');
      }

      if (!dataFound) {
        throw Exception('Data hewan tidak ditemukan di database');
      }

      // 2. Buat data untuk riwayat hewan dengan data yang tersedia
      Map<String, dynamic> riwayatData = {
        'original_hewan_id': _selectedHewanId,
        'nomor_hewan': hewanData['nomor_hewan'] ?? _selectedHewanNomor ?? 'Tidak diketahui',
        'jenis_hewan': hewanData['jenis_hewan'] ?? _selectedHewanJenis ?? 'Tidak diketahui',
        'ownerId': hewanData['ownerId'] ?? _selectedHewanOwnerId ?? 'Tidak diketahui',
        'alasan_keluar': reason, // 'Mati' atau 'Dijual'
        'tanggal_keluar': reason == 'Mati' 
            ? (_tanggalMati != null ? DateFormat('dd-MM-yyyy').format(_tanggalMati!) : null)
            : (_tanggalDijual != null ? DateFormat('dd-MM-yyyy').format(_tanggalDijual!) : null),
        'timestamp_moved': ServerValue.timestamp,
        ...additionalData, // Data tambahan seperti harga jual, penyebab kematian, dll
      };

      // Tambahkan field lain jika tersedia
      if (hewanData.containsKey('kandangid')) riwayatData['kandangid'] = hewanData['kandangid'];
      if (hewanData.containsKey('jenis_kelamin')) riwayatData['jenis_kelamin'] = hewanData['jenis_kelamin'];
      if (hewanData.containsKey('kategori')) riwayatData['kategori'] = hewanData['kategori'];
      if (hewanData.containsKey('kesehatan')) riwayatData['kesehatan'] = hewanData['kesehatan'];
      if (hewanData.containsKey('tanggal_masuk')) riwayatData['tanggal_masuk'] = hewanData['tanggal_masuk'];
      if (hewanData.containsKey('umur_hewan')) riwayatData['umur_hewan'] = hewanData['umur_hewan'];
      if (hewanData.containsKey('harga')) riwayatData['harga'] = hewanData['harga'];
      if (hewanData.containsKey('update_harga_info')) riwayatData['update_harga_info'] = hewanData['update_harga_info'];
      if (hewanData.containsKey('image_url')) riwayatData['image_url'] = hewanData['image_url'];

      // 3. Simpan ke riwayat hewan
      DatabaseReference riwayatRef = _database.ref().child("riwayat_hewan").push();
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

  Future<void> _pilihHewan() async {
    DatabaseReference hewanRef = _database.ref().child("hewan");
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
            'kandangid': value['kandangid'] ?? 'Tidak diketahui', // sesuai dengan database Anda
            'data': value, // Simpan data lengkap
          });
        }
      });
    }

    String? selectedHewan;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Hewan"),
          content: DropdownButton<String>(
            value: selectedHewan,
            hint: Text("Pilih Hewan"),
            items: hewanList.map((Map<String, dynamic> hewan) {
              return DropdownMenuItem<String>(
                value: hewan['id'],
                child: Text(hewan['nomor_hewan'] ?? 'Tidak diketahui'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedHewan = newValue;
                _selectedHewanId = newValue;
                var selectedHewanData = hewanList.firstWhere((hewan) => hewan['id'] == newValue);
                _selectedHewanNomor = selectedHewanData['nomor_hewan'];
                _selectedHewanJenis = selectedHewanData['jenis_hewan'];
                _selectedHewanOwnerId = selectedHewanData['ownerId'];
                _selectedHewanData = selectedHewanData['data']; // Store complete data
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Tutup"),
            ),
            TextButton(
              onPressed: () {
                if (selectedHewan != null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hewan dipilih: $_selectedHewanNomor')),
                  );
                }
              },
              child: Text("Pilih"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tanggalSakitController.text = DateFormat('dd-MM-yyyy').format(_tanggalSakit);
    _tanggalDijualController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _tanggalSakitController.dispose();
    _estimasiSembuhController.dispose();
    _tanggalMatiController.dispose();
    _tanggalDijualController.dispose();
    _penyebabKematianController.dispose();
    _penangananController.dispose();
    _hargaJualController.dispose();
    _keteranganJualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pelaporan Hewan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_isUploading)
                CircularProgressIndicator(), // Tampilkan indikator proses saat mengunggah
              if (_imageName != null)
                Text('Nama File: $_imageName'), // Tampilkan nama file gambar
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pilih Gambar'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pilihHewan,
                child: Text('Pilih Hewan'),
              ),
              if (_selectedHewanNomor != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Hewan Terpilih: $_selectedHewanNomor (${_selectedHewanJenis ?? "Tidak diketahui"})',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(height: 20),
              
              // Status Hewan Selection
              Text(
                'Status Hewan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Sakit',
                    groupValue: _statusHewan,
                    onChanged: (String? value) {
                      setState(() {
                        _statusHewan = value!;
                      });
                    },
                  ),
                  Text('Sakit'),
                  SizedBox(width: 20),
                  Radio<String>(
                    value: 'Mati',
                    groupValue: _statusHewan,
                    onChanged: (String? value) {
                      setState(() {
                        _statusHewan = value!;
                      });
                    },
                  ),
                  Text('Mati'),
                  SizedBox(width: 20),
                  Radio<String>(
                    value: 'Dijual',
                    groupValue: _statusHewan,
                    onChanged: (String? value) {
                      setState(() {
                        _statusHewan = value!;
                      });
                    },
                  ),
                  Text('Dijual'),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Form khusus untuk status "Dijual"
              if (_statusHewan == 'Dijual') ...[
                TextFormField(
                  controller: _tanggalDijualController,
                  decoration: InputDecoration(labelText: 'Tanggal Dijual'),
                  readOnly: true,
                  onTap: () => _selectDate(context, _tanggalDijualController, _tanggalDijual),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan tanggal dijual';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _hargaJualController,
                  decoration: InputDecoration(
                    labelText: 'Harga Jual (Rp)',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _hargaJual = double.tryParse(value) ?? 0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan harga jual';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Silakan masukkan harga yang valid';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _keteranganJualController,
                  decoration: InputDecoration(labelText: 'Keterangan Penjualan'),
                  maxLines: 3,
                  onSaved: (value) => _keteranganJual = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan keterangan penjualan';
                    }
                    return null;
                  },
                ),
              ] else ...[
                // Form untuk status "Sakit" dan "Mati"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Kategori Gejala',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._gejala.keys.map((String key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: _gejala[key],
                    onChanged: (bool? value) {
                      setState(() {
                        _gejala[key] = value!;
                        if (value) {
                          _estimasiBiayaPerawatan += _hargaGejala[key] ?? 0;
                        } else {
                          _estimasiBiayaPerawatan -= _hargaGejala[key] ?? 0;
                        }
                      });
                    },
                  );
                }).toList(),
                
                TextFormField(
                  decoration: InputDecoration(labelText: 'Keluhan'),
                  onSaved: (value) => _keluhan = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan keluhan';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 10),
                TextFormField(
                  controller: _penangananController,
                  decoration: InputDecoration(labelText: 'Penanganan yang Diberikan'),
                  maxLines: 3,
                  onSaved: (value) => _penanganan = value ?? '',
                ),
                
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tanggalSakitController,
                        decoration: InputDecoration(labelText: 'Tanggal Sakit'),
                        readOnly: true,
                        onTap: () => _selectDate(context, _tanggalSakitController, _tanggalSakit),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _statusHewan == 'Sakit'
                          ? TextFormField(
                              controller: _estimasiSembuhController,
                              decoration: InputDecoration(labelText: 'Estimasi Sembuh'),
                              readOnly: true,
                              onTap: () => _selectDate(context, _estimasiSembuhController, _estimasiSembuh),
                            )
                          : TextFormField(
                              controller: _tanggalMatiController,
                              decoration: InputDecoration(labelText: 'Tanggal Kematian'),
                              readOnly: true,
                              onTap: () => _selectDate(context, _tanggalMatiController, _tanggalMati),
                              validator: (value) {
                                if (_statusHewan == 'Mati' && (value == null || value.isEmpty)) {
                                  return 'Silakan masukkan tanggal kematian';
                                }
                                return null;
                              },
                            ),
                    ),
                  ],
                ),
                
                // Penyebab Kematian (hanya muncul jika status Mati)
                if (_statusHewan == 'Mati')
                  TextFormField(
                    controller: _penyebabKematianController,
                    decoration: InputDecoration(labelText: 'Penyebab Kematian'),
                    maxLines: 3,
                    onSaved: (value) => _penyebabKematian = value ?? '',
                    validator: (value) {
                      if (_statusHewan == 'Mati' && (value == null || value.isEmpty)) {
                        return 'Silakan masukkan penyebab kematian';
                      }
                      return null;
                    },
                  ),
                
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      "Estimasi biaya perawatan: ", 
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    Text(
                      'Rp ${_estimasiBiayaPerawatan.toString()}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
              
              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();

                    // Validasi khusus berdasarkan status
                    if (_statusHewan == 'Mati' && _tanggalMati == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silakan masukkan tanggal kematian')),
                      );
                      return;
                    }

                    if (_statusHewan == 'Dijual' && _tanggalDijual == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silakan masukkan tanggal dijual')),
                      );
                      return;
                    }

                    if (_selectedHewanId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silakan pilih hewan terlebih dahulu')),
                      );
                      return;
                    }

                    try {
                      // Format tanggal
                      String formattedTanggalSakit = DateFormat('dd-MM-yyyy').format(_tanggalSakit);
                      String? formattedEstimasiSembuh = _estimasiSembuh != null
                          ? DateFormat('dd-MM-yyyy').format(_estimasiSembuh!)
                          : null;
                      String? formattedTanggalMati = _tanggalMati != null
                          ? DateFormat('dd-MM-yyyy').format(_tanggalMati!)
                          : null;
                      String? formattedTanggalDijual = _tanggalDijual != null
                          ? DateFormat('dd-MM-yyyy').format(_tanggalDijual!)
                          : null;

                      // Buat data dasar
                      Map<String, dynamic> laporanData = {
                        'ownerId': _selectedHewanOwnerId,
                        'nomor_hewan': _selectedHewanNomor,
                        'jenis_hewan': _selectedHewanJenis,
                        'image_url': _imageUrl,
                        'status_hewan': _statusHewan,
                      };

                      // Tambahkan data khusus berdasarkan status
                      if (_statusHewan == 'Dijual') {
                        laporanData['tanggal_dijual'] = formattedTanggalDijual;
                        laporanData['harga_jual'] = _hargaJual;
                        laporanData['keterangan_jual'] = _keteranganJual;
                      } else {
                        // Untuk status Sakit dan Mati
                        Map<String, bool> gejalaTerpilih = Map.fromEntries(
                            _gejala.entries.where((entry) => entry.value)
                        );
                        
                        laporanData['deskripsi_keluhan'] = _keluhan;
                        laporanData['tanggal_sakit'] = formattedTanggalSakit;
                        laporanData['gejala'] = gejalaTerpilih;
                        laporanData['penanganan'] = _penanganan;

                        if (_statusHewan == 'Sakit') {
                          laporanData['estimasi_sembuh'] = formattedEstimasiSembuh;
                          laporanData['biaya'] = _estimasiBiayaPerawatan;
                          laporanData['status_pembayaran'] = 'pending';
                        } else if (_statusHewan == 'Mati') {
                          laporanData['tanggal_mati'] = formattedTanggalMati;
                          laporanData['penyebab_kematian'] = _penyebabKematian;
                          laporanData['biaya'] = _estimasiBiayaPerawatan;
                          laporanData['status_pembayaran'] = 'pending';
                        }
                      }

                      // Simpan data laporan kesehatan ke database
                      DatabaseReference laporanRef = _database.ref().child("laporan_kesehatan").push();
                      await laporanRef.set(laporanData);

                      // Buat tagihan kesehatan jika ada biaya (untuk status Sakit dan Mati)
                      if (_statusHewan != 'Dijual' && _estimasiBiayaPerawatan > 0) {
                        DatabaseReference tagihanRef = _database.ref().child("tagihan/kesehatan").push();
                        Map<String, dynamic> tagihanData = {
                          'ownerId': _selectedHewanOwnerId,
                          'nomor_hewan': _selectedHewanNomor,
                          'gejala': Map.fromEntries(_gejala.entries.where((entry) => entry.value)),
                          'deskripsi_keluhan': _keluhan,
                          'tanggal_sakit': formattedTanggalSakit,
                          'biaya': _estimasiBiayaPerawatan,
                          'status_pembayaran': 'pending',
                        };
                        
                        if (_statusHewan == 'Mati') {
                          tagihanData['status_hewan'] = 'Mati';
                          tagihanData['tanggal_mati'] = formattedTanggalMati;
                          tagihanData['penyebab_kematian'] = _penyebabKematian;
                        }
                        
                        await tagihanRef.set(tagihanData);
                      }

                      // Update status hewan di database (hanya untuk status Sakit)
                      if (_statusHewan == 'Sakit') {
                        await updateHewanStatus(_statusHewan);
                      }

                      // Jika status adalah Mati atau Dijual, pindahkan ke riwayat dan hapus dari database utama
                      if (_statusHewan == 'Mati' || _statusHewan == 'Dijual') {
                        Map<String, dynamic> additionalData = {};
                        
                        if (_statusHewan == 'Mati') {
                          additionalData = {
                            'tanggal_sakit': formattedTanggalSakit,
                            'gejala': Map.fromEntries(_gejala.entries.where((entry) => entry.value)),
                            'penyebab_kematian': _penyebabKematian,
                            'penanganan': _penanganan,
                            'biaya_perawatan': _estimasiBiayaPerawatan,
                            'keluhan': _keluhan,
                          };
                        } else if (_statusHewan == 'Dijual') {
                          additionalData = {
                            'harga_jual': _hargaJual,
                            'keterangan_jual': _keteranganJual,
                          };
                        }

                        // Pindahkan hewan ke riwayat dan hapus dari database utama
                        await moveHewanToHistoryAndDelete(_statusHewan, additionalData);
                      }

                      // Tambahkan catatan kematian jika hewan mati
                      if (_statusHewan == 'Mati') {
                        DatabaseReference kematianRef = _database.ref().child("kematian_hewan").push();
                        await kematianRef.set({
                          'hewan_id': _selectedHewanId,
                          'nomor_hewan': _selectedHewanNomor,
                          'jenis_hewan': _selectedHewanJenis,
                          'ownerId': _selectedHewanOwnerId,
                          'tanggal_sakit': formattedTanggalSakit,
                          'tanggal_mati': formattedTanggalMati,
                          'gejala': Map.fromEntries(_gejala.entries.where((entry) => entry.value)),
                          'penyebab_kematian': _penyebabKematian,
                          'penanganan': _penanganan,
                          'image_url': _imageUrl,
                          'timestamp': ServerValue.timestamp,
                        });
                      }

                      // Tambahkan catatan penjualan jika hewan dijual
                      if (_statusHewan == 'Dijual') {
                        DatabaseReference penjualanRef = _database.ref().child("penjualan_hewan").push();
                        await penjualanRef.set({
                          'hewan_id': _selectedHewanId,
                          'nomor_hewan': _selectedHewanNomor,
                          'jenis_hewan': _selectedHewanJenis,
                          'ownerId': _selectedHewanOwnerId,
                          'tanggal_dijual': formattedTanggalDijual,
                          'harga_jual': _hargaJual,
                          'keterangan_jual': _keteranganJual,
                          'image_url': _imageUrl,
                          'timestamp': ServerValue.timestamp,
                        });
                      }

                      // Reset form atau navigasi kembali
                      String statusMessage = _statusHewan == 'Dijual' 
                          ? 'Penjualan Hewan $_selectedHewanNomor dengan harga Rp ${_hargaJual.toStringAsFixed(0)} - Hewan dipindahkan ke riwayat'
                          : _statusHewan == 'Mati'
                              ? 'Kematian Hewan $_selectedHewanNomor - Hewan dipindahkan ke riwayat'
                              : 'Sakit Hewan $_selectedHewanNomor';
                      
                      Color bgColor = _statusHewan == 'Mati' 
                          ? Colors.red 
                          : _statusHewan == 'Dijual' 
                              ? Colors.green 
                              : Colors.blue;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Laporan berhasil dikirim: $statusMessage'),
                          backgroundColor: bgColor,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      
                      // Reset form setelah berhasil
                      _formKey.currentState?.reset();
                      setState(() {
                        _selectedHewanId = null;
                        _selectedHewanNomor = null;
                        _selectedHewanJenis = null;
                        _selectedHewanOwnerId = null;
                        _selectedHewanData = null;
                        _statusHewan = 'Sakit';
                        _estimasiBiayaPerawatan = 0;
                        _keluhan = '';
                        _penanganan = '';
                        _penyebabKematian = '';
                        _hargaJual = 0;
                        _keteranganJual = '';
                        _imageUrl = null;
                        _imageName = null;
                        _tanggalSakit = DateTime.now();
                        _estimasiSembuh = null;
                        _tanggalMati = null;
                        _tanggalDijual = null;
                        _gejala.updateAll((key, value) => false);
                      });
                      
                      // Reset controllers
                      _tanggalSakitController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
                      _estimasiSembuhController.clear();
                      _tanggalMatiController.clear();
                      _tanggalDijualController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
                      _penyebabKematianController.clear();
                      _penangananController.clear();
                      _hargaJualController.clear();
                      _keteranganJualController.clear();
                      
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Terjadi kesalahan: $e'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      print('Error dalam proses pelaporan: $e');
                    }
                  }
                },
                child: Text('Kirim Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusHewan == 'Mati' 
                      ? Colors.red 
                      : _statusHewan == 'Dijual' 
                          ? Colors.green 
                          : Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}