import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sobatternak_admin_web/pages/Kesehatan/cummonFungtion.dart';
import 'package:universal_html/html.dart' as html;


class PelaporanDijualPage extends StatefulWidget {
  @override
  _PelaporanDijualPageState createState() => _PelaporanDijualPageState();
}

class _PelaporanDijualPageState extends State<PelaporanDijualPage> {
  final _formKey = GlobalKey<FormState>();
  String? _imageUrl;
  String? _imageName;
  String? _selectedHewanId;
  String? _selectedHewanNomor;
  String? _selectedHewanOwnerId;
  String? _selectedHewanJenis;
  String? _selectedHewanKandangId; // Tambahan untuk kandang ID
  Map<String, dynamic>? _selectedHewanData;
  bool _isUploading = false;
  DateTime? _tanggalDijual;
  double _hargaJual = 0;
  String _keteranganJual = '';

  TextEditingController _tanggalDijualController = TextEditingController();
  TextEditingController _hargaJualController = TextEditingController();
  TextEditingController _keteranganJualController = TextEditingController();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _tanggalDijualController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _tanggalDijual = DateTime.now();
  }

  @override
  void dispose() {
    _tanggalDijualController.dispose();
    _hargaJualController.dispose();
    _keteranganJualController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
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
        _tanggalDijual = picked;
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
            _selectedHewanData = Map<String, dynamic>.from(result['data'] as Map);
          } else {
            _selectedHewanData = null;
          }
        } else {
          _selectedHewanData = null;
        }
        
        // Ambil kandangId dari dalam objek data dengan casting yang aman
        if (_selectedHewanData != null && _selectedHewanData!['kandangId'] != null) {
          _selectedHewanKandangId = _selectedHewanData!['kandangId'].toString();
          print('Kandang ID dari result.data: ${_selectedHewanData!['kandangId']}');
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
      DatabaseReference hewanRef = _database.ref().child("hewan").child(hewanId);
      DataSnapshot snapshot = await hewanRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> hewanData = Map<String, dynamic>.from(snapshot.value as Map);
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
        Map<String, dynamic> allHewanData = Map<String, dynamic>.from(allSnapshot.value as Map);
        
        // Cari hewan berdasarkan nomor_hewan
        for (var entry in allHewanData.entries) {
          if (entry.value is Map) {
            Map<String, dynamic> hewanInfo = Map<String, dynamic>.from(entry.value);
            if (hewanInfo['nomor_hewan'] == _selectedHewanNomor) {
              setState(() {
                _selectedHewanKandangId = hewanInfo['kandangid'];
              });
              print('Kandang ID ditemukan berdasarkan nomor_hewan: ${hewanInfo['kandangid']}');
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
        title: Text('Pelaporan Hewan Dijual'),
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
              if (_isUploading)
                CircularProgressIndicator(),
              if (_imageName != null)
                Text('Nama File: $_imageName'),
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
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              SizedBox(height: 20),

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
              
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Penjualan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_selectedHewanNomor != null)
                      Text('Hewan: $_selectedHewanNomor'),
                    if (_tanggalDijual != null)
                      Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(_tanggalDijual!)}'),
                    if (_hargaJual > 0)
                      Text(
                        'Harga: Rp ${_hargaJual.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();

                    if (_tanggalDijual == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silakan masukkan tanggal dijual')),
                      );
                      return;
                    }

                    // Debug: Print semua data sebelum menyimpan
                    print('=== DEBUG SEBELUM MENYIMPAN ===');
                    print('Selected Hewan ID: $_selectedHewanId');
                    print('Selected Hewan Nomor: $_selectedHewanNomor');
                    print('Selected Hewan Kandang ID: $_selectedHewanKandangId');
                    print('Selected Hewan Data: $_selectedHewanData');

                    if (_selectedHewanId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silakan pilih hewan terlebih dahulu')),
                      );
                      return;
                    }

                    try {
                      String formattedTanggalDijual = DateFormat('dd-MM-yyyy').format(_tanggalDijual!);

                      Map<String, dynamic> laporanData = {
                        'ownerId': _selectedHewanOwnerId,
                        'nomor_hewan': _selectedHewanNomor,
                        'jenis_hewan': _selectedHewanJenis,
                        'kandangid': _selectedHewanKandangId, // Tambahan kandang ID
                        'image_url': _imageUrl,
                        'status_hewan': 'Dijual',
                        'tanggal_dijual': formattedTanggalDijual,
                        'harga_jual': _hargaJual,
                        'keterangan_jual': _keteranganJual,
                      };

                      DatabaseReference laporanRef = _database.ref().child("laporan_kesehatan").push();
                      await laporanRef.set(laporanData);

                      // Pindahkan hewan ke riwayat dan hapus dari database utama
                      Map<String, dynamic> additionalData = {
                        'harga_jual': _hargaJual,
                        'keterangan_jual': _keteranganJual,
                        'kandangid': _selectedHewanKandangId, // Tambahan kandang ID
                      };
                      
                      await CommonFunctions.moveHewanToHistoryAndDelete(
                        _selectedHewanId!, 
                        _selectedHewanData!, 
                        _selectedHewanNomor!, 
                        _selectedHewanJenis!, 
                        _selectedHewanOwnerId!, 
                        'Dijual', 
                        additionalData, 
                        _database,
                        tanggalKeluar: _tanggalDijual!,
                        kandangId: _selectedHewanKandangId // Tambahan parameter kandang ID
                      );

                      // Tambahkan catatan penjualan
                      DatabaseReference penjualanRef = _database.ref().child("penjualan_hewan").push();
                      await penjualanRef.set({
                        'hewan_id': _selectedHewanId,
                        'nomor_hewan': _selectedHewanNomor,
                        'jenis_hewan': _selectedHewanJenis,
                        'ownerId': _selectedHewanOwnerId,
                        'kandangid': _selectedHewanKandangId, // Tambahan kandang ID
                        'tanggal_dijual': formattedTanggalDijual,
                        'harga_jual': _hargaJual,
                        'keterangan_jual': _keteranganJual,
                        'image_url': _imageUrl,
                        'timestamp': ServerValue.timestamp,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Penjualan Hewan $_selectedHewanNomor dengan harga Rp ${_hargaJual.toStringAsFixed(0)} - Hewan dipindahkan ke riwayat'),
                          backgroundColor: Colors.green,
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
                child: Text('Kirim Laporan Penjualan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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