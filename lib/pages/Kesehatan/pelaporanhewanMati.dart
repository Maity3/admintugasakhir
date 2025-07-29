import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sobatternak_admin_web/pages/Kesehatan/cummonFungtion.dart';
import 'package:universal_html/html.dart' as html;

class PelaporanMatiPage extends StatefulWidget {
  @override
  _PelaporanMatiPageState createState() => _PelaporanMatiPageState();
}

class _PelaporanMatiPageState extends State<PelaporanMatiPage> {
  final _formKey = GlobalKey<FormState>();
  int _estimasiBiayaPerawatan = 0;
  String _keluhan = '';
  String? _imageUrl;
  String? _imageName;
  String? _selectedHewanId;
  String? _selectedHewanNomor;
  String? _selectedHewanOwnerId;
  String? _selectedHewanJenis;
  String? _selectedHewanKandangId; // Tambahan untuk kandang ID
  Map<String, dynamic>? _selectedHewanData;
  bool _isUploading = false;
  DateTime _tanggalSakit = DateTime.now();
  DateTime? _tanggalMati;
  String _penyebabKematian = '';
  String _penanganan = '';

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
  TextEditingController _tanggalMatiController = TextEditingController();
  TextEditingController _penyebabKematianController = TextEditingController();
  TextEditingController _penangananController = TextEditingController();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _tanggalSakitController.text =
        DateFormat('dd-MM-yyyy').format(_tanggalSakit);
  }

  @override
  void dispose() {
    _tanggalSakitController.dispose();
    _tanggalMatiController.dispose();
    _penyebabKematianController.dispose();
    _penangananController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
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
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (controller == _tanggalMatiController) {
          if (picked.isBefore(_tanggalSakit)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Tanggal kematian tidak boleh sebelum tanggal sakit')),
            );
            return;
          }
          _tanggalMati = picked;
        } else if (controller == _tanggalSakitController) {
          _tanggalSakit = picked;
        }
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _pilihHewan() async {
    final result = await CommonFunctions.pilihHewan(context, _database);
    if (result != null) {
      print('Data result dari pilihHewan: $result'); // Debug print

      setState(() {
        _selectedHewanId = result['id']?.toString();
        _selectedHewanNomor = result['nomor_hewan']?.toString();
        _selectedHewanJenis = result['jenis_hewan']?.toString();
        _selectedHewanOwnerId = result['ownerId']?.toString();

        // Casting yang lebih aman untuk data
        if (result['data'] != null) {
          if (result['data'] is Map) {
            _selectedHewanData =
                Map<String, dynamic>.from(result['data'] as Map);
          } else {
            _selectedHewanData = null;
          }
        } else {
          _selectedHewanData = null;
        }

        // Ambil kandangId dari dalam objek data dengan casting yang aman
        if (_selectedHewanData != null &&
            _selectedHewanData!['kandangId'] != null) {
          _selectedHewanKandangId = _selectedHewanData!['kandangId'].toString();
          print(
              'Kandang ID dari result.data: ${_selectedHewanData!['kandangId']}');
        } else if (result['kandangid'] != null) {
          // Fallback jika kandangId ada di level atas
          _selectedHewanKandangId = result['kandangid'].toString();
          print('Kandang ID dari result: ${result['kandangid']}');
        } else if (result['kandangId'] != null) {
          // Fallback dengan huruf besar I
          _selectedHewanKandangId = result['kandangId'].toString();
          print('Kandang ID dari result (kandangId): ${result['kandangId']}');
        } else {
          print('Kandang ID tidak ditemukan dalam result');
          _selectedHewanKandangId = '';
        }
      });
    }
  }

  Future<void> _getKandangId(String hewanId) async {
    try {
      // Coba ambil dari child hewanId langsung
      DatabaseReference hewanRef =
          _database.ref().child("hewan").child(hewanId);
      DataSnapshot snapshot = await hewanRef.get();

      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> hewanData =
            Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _selectedHewanKandangId = hewanData['kandangid'];
        });
        print('Kandang ID ditemukan: ${hewanData['kandangid']}');
        return;
      }

      // Jika tidak ditemukan, coba cari berdasarkan nomor_hewan
      DatabaseReference allHewanRef = _database.ref().child("hewan");
      DataSnapshot allSnapshot = await allHewanRef.get();

      if (allSnapshot.exists && allSnapshot.value != null) {
        Map<String, dynamic> allHewanData =
            Map<String, dynamic>.from(allSnapshot.value as Map);

        // Cari hewan berdasarkan nomor_hewan
        for (var entry in allHewanData.entries) {
          if (entry.value is Map) {
            Map<String, dynamic> hewanInfo =
                Map<String, dynamic>.from(entry.value);
            if (hewanInfo['nomor_hewan'] == _selectedHewanNomor) {
              setState(() {
                _selectedHewanKandangId = hewanInfo['kandangid'];
              });
              print(
                  'Kandang ID ditemukan berdasarkan nomor_hewan: ${hewanInfo['kandangid']}');
              return;
            }
          }
        }
      }

      print('Kandang ID tidak ditemukan');
      setState(() {
        _selectedHewanKandangId = '';
      });
    } catch (e) {
      print('Error getting kandangid: $e');
      setState(() {
        _selectedHewanKandangId = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pelaporan Hewan Mati'),
        backgroundColor: Color.fromRGBO(184, 137, 220, 0.922),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_isUploading) CircularProgressIndicator(),
              if (_imageName != null) Text('Nama File: $_imageName'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hewan Terpilih: $_selectedHewanNomor (${_selectedHewanJenis ?? "Tidak diketahui"})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_selectedHewanKandangId != null && _selectedHewanKandangId!.isNotEmpty)
                          Text(
                            'Kandang: $_selectedHewanKandangId',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600]),
                          ),
                      ],
                    )),
              SizedBox(height: 20),
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
                decoration:
                    InputDecoration(labelText: 'Penanganan yang Diberikan'),
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
                      onTap: () => _selectDate(
                          context, _tanggalSakitController, _tanggalSakit),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tanggalMatiController,
                      decoration:
                          InputDecoration(labelText: 'Tanggal Kematian'),
                      readOnly: true,
                      onTap: () => _selectDate(
                          context, _tanggalMatiController, _tanggalMati),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Silakan masukkan tanggal kematian';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _penyebabKematianController,
                decoration: InputDecoration(labelText: 'Penyebab Kematian'),
                maxLines: 3,
                onSaved: (value) => _penyebabKematian = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan penyebab kematian';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text("Estimasi biaya perawatan: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Rp ${_estimasiBiayaPerawatan.toString()}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();

                    if (_tanggalMati == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Silakan masukkan tanggal kematian')),
                      );
                      return;
                    }

                    // Debug: Print semua data sebelum menyimpan
                    print('=== DEBUG SEBELUM MENYIMPAN ===');
                    print('Selected Hewan ID: $_selectedHewanId');
                    print('Selected Hewan Nomor: $_selectedHewanNomor');
                    print(
                        'Selected Hewan Kandang ID: $_selectedHewanKandangId');
                    print('Selected Hewan Data: $_selectedHewanData');

                    if (_selectedHewanId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Silakan pilih hewan terlebih dahulu')),
                      );
                      return;
                    }

                    try {
                      String formattedTanggalSakit =
                          DateFormat('dd-MM-yyyy').format(_tanggalSakit);
                      String formattedTanggalMati =
                          DateFormat('dd-MM-yyyy').format(_tanggalMati!);

                      Map<String, dynamic> laporanData = {
                        'ownerId': _selectedHewanOwnerId,
                        'nomor_hewan': _selectedHewanNomor,
                        'jenis_hewan': _selectedHewanJenis,
                        'kandangid':
                            _selectedHewanKandangId, // Tambahan kandang ID
                        'image_url': _imageUrl,
                        'status_hewan': 'Mati',
                        'deskripsi_keluhan': _keluhan,
                        'tanggal_sakit': formattedTanggalSakit,
                        'gejala': Map.fromEntries(
                            _gejala.entries.where((entry) => entry.value)),
                        'penanganan': _penanganan,
                        'tanggal_mati': formattedTanggalMati,
                        'penyebab_kematian': _penyebabKematian,
                        'biaya': _estimasiBiayaPerawatan,
                        'status_pembayaran': 'pending',
                      };

                      DatabaseReference laporanRef =
                          _database.ref().child("laporan_kesehatan").push();
                      await laporanRef.set(laporanData);

                      if (_estimasiBiayaPerawatan > 0) {
                        DatabaseReference tagihanRef =
                            _database.ref().child("tagihan/kesehatan").push();
                        Map<String, dynamic> tagihanData = {
                          'ownerId': _selectedHewanOwnerId,
                          'nomor_hewan': _selectedHewanNomor,
                          'kandangid':
                              _selectedHewanKandangId, // Tambahan kandang ID
                          'gejala': Map.fromEntries(
                              _gejala.entries.where((entry) => entry.value)),
                          'deskripsi_keluhan': _keluhan,
                          'tanggal_sakit': formattedTanggalSakit,
                          'biaya': _estimasiBiayaPerawatan,
                          'status_pembayaran': 'pending',
                          'status_hewan': 'Mati',
                          'tanggal_mati': formattedTanggalMati,
                          'penyebab_kematian': _penyebabKematian,
                        };
                        await tagihanRef.set(tagihanData);
                      }

                      // Pindahkan hewan ke riwayat dan hapus dari database utama
                      Map<String, dynamic> additionalData = {
                        'tanggal_sakit': formattedTanggalSakit,
                        'gejala': Map.fromEntries(
                            _gejala.entries.where((entry) => entry.value)),
                        'penyebab_kematian': _penyebabKematian,
                        'penanganan': _penanganan,
                        'biaya_perawatan': _estimasiBiayaPerawatan,
                        'keluhan': _keluhan,
                        'kandangid':
                            _selectedHewanKandangId, // Tambahan kandang ID
                      };

                      await CommonFunctions.moveHewanToHistoryAndDelete(
                          _selectedHewanId!,
                          _selectedHewanData!,
                          _selectedHewanNomor!,
                          _selectedHewanJenis!,
                          _selectedHewanOwnerId!,
                          'Mati',
                          additionalData,
                          _database,
                          tanggalKeluar: _tanggalMati!,
                          kandangId:
                              _selectedHewanKandangId // Tambahan parameter kandang ID
                          );

                      // Tambahkan catatan kematian
                      DatabaseReference kematianRef =
                          _database.ref().child("kematian_hewan").push();
                      await kematianRef.set({
                        'hewan_id': _selectedHewanId,
                        'nomor_hewan': _selectedHewanNomor,
                        'jenis_hewan': _selectedHewanJenis,
                        'ownerId': _selectedHewanOwnerId,
                        'kandangid':
                            _selectedHewanKandangId, // Tambahan kandang ID
                        'tanggal_sakit': formattedTanggalSakit,
                        'tanggal_mati': formattedTanggalMati,
                        'gejala': Map.fromEntries(
                            _gejala.entries.where((entry) => entry.value)),
                        'penyebab_kematian': _penyebabKematian,
                        'penanganan': _penanganan,
                        'image_url': _imageUrl,
                        'timestamp': ServerValue.timestamp,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Kematian Hewan $_selectedHewanNomor - Hewan dipindahkan ke riwayat'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Terjadi kesalahan: $e'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                child: Text('Kirim Laporan Kematian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
