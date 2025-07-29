import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sobatternak_admin_web/Homepage.dart';
import 'package:universal_html/html.dart' as html;

class TambahHewanForm extends StatefulWidget {
  @override
  _TambahHewanFormState createState() => _TambahHewanFormState();
}

class _TambahHewanFormState extends State<TambahHewanForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomorHewanController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  DateTime _tanggalMasuk = DateTime.now();
  String _jenisHewan = 'Kambing Lokal';
  String _kelamin = 'Jantan';
  String _status = 'Sehat';
  String _kategori = 'Penggemukan';
  String _umurHewan = '3';
  String? _imageUrl;
  String? _imageName;
  bool _isUploading = false;
  String? _selectedKandang;
  int _hargaHewan = 1000000; // Default harga untuk Jantan 3 bulan
  final String _updateHargaInfo = 'Update Harga Kambing Mei 2025';
  
  // Map harga berdasarkan jenis kelamin dan umur
  final Map<String, Map<String, int>> _hargaKambing = {
    'Jantan': {
      '3': 1000000,
      '6': 1600000,
      '8': 2300000,
      '12': 2600000,
    },
    'Betina': {
      '3': 800000,
      '6': 1300000,
      '8': 1800000,
      '12': 2300000,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchKandangNames();
    _updateHarga(); // Set harga awal
  }

  // Method untuk memperbarui harga berdasarkan jenis kelamin dan umur
  void _updateHarga() {
    setState(() {
      _hargaHewan = _hargaKambing[_kelamin]![_umurHewan]!;
    });
  }

  Future<void> _fetchKandangNames() async {
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang");
    DataSnapshot snapshot = await kandangRef.get();
    if (snapshot.exists) {
      List<Map<String, String>> kandangList = [];
      snapshot.children.forEach((child) {
        Map<String, dynamic> kandangData = Map<String, dynamic>.from(child.value as Map);
        kandangList.add({
          'id': child.key!,
          'name': kandangData['nama_kandang'] ?? 'Unknown',
        });
      });
      setState(() {
      });
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Flutter Web
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
              final storageRef = FirebaseStorage.instance.ref().child('hewan_images/${files[0].name}');
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah gambar: $e')));
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
          final storageRef = FirebaseStorage.instance.ref().child('hewan_images/${image.name}');
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah gambar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Hewan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomorHewanController,
                  decoration: InputDecoration(labelText: 'Nomer Hewan'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan Nomer hewan';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _jenisHewan,
                  decoration: InputDecoration(labelText: 'Jenis Hewan'),
                  items: <String>['Kambing Lokal']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _jenisHewan = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap pilih jenis hewan';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 5),
                Text('Kelamin'),
                Row(
                  children: [
                    Radio(
                      value: 'Jantan',
                      groupValue: _kelamin,
                      onChanged: (value) {
                        setState(() {
                          _kelamin = value.toString();
                          _updateHarga(); // Update harga ketika kelamin berubah
                        });
                      },
                    ),
                    Text('Jantan'),
                    Radio(
                      value: 'Betina',
                      groupValue: _kelamin,
                      onChanged: (value) {
                        setState(() {
                          _kelamin = value.toString();
                          _updateHarga(); // Update harga ketika kelamin berubah
                        });
                      },
                    ),
                    Text('Betina'),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _beratController,
                        decoration: InputDecoration(labelText: 'Berat (Kg)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap masukkan berat';
                          }
                          try {
                            double.parse(value);
                          } catch (e) {
                            return 'Harap masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanggal Masuk'),
                          TextButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _tanggalMasuk,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null && pickedDate != _tanggalMasuk) {
                                setState(() {
                                  _tanggalMasuk = pickedDate;
                                });
                              }
                            },
                            child: Text(DateFormat('dd-MM-yyyy').format(_tanggalMasuk)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _umurHewan,
                  decoration: InputDecoration(labelText: 'Umur Hewan'),
                  items: <String>['3', '6', '8', '12']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value + ' Bulan'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _umurHewan = newValue!;
                      _updateHarga(); // Update harga ketika umur berubah
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap pilih umur hewan';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                // Menampilkan harga hewan
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(184, 137, 220, 0.922),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color.fromRGBO(184, 137, 220, 0.922)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _updateHargaInfo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Harga: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(_hargaHewan)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${_kelamin}, ${_umurHewan} bulan',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text('Status Kesehatan'),
                Row(
                  children: [
                    Radio(
                      value: 'Sehat',
                      groupValue: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value.toString();
                        });
                      },
                    ),
                    Text('Sehat'),
                    Radio(
                      value: 'Sakit',
                      groupValue: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value.toString();
                        });
                      },
                    ),
                    Text('Sakit'),
                  ],
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _kategori,
                  decoration: InputDecoration(labelText: 'Kategori'),
                  items: <String>['Penggemukan', 'Pembiakan']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _kategori = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap pilih kategori';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Tambah Foto Hewan'),
                ),
                if (_isUploading) CircularProgressIndicator(), // Tampilkan indikator proses saat mengunggah
                if (_imageName != null) Text('Nama File: $_imageName'), // Tampilkan nama file gambar
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Ambil data dari form
                      String jenisHewan = _jenisHewan;  // Gunakan variabel dropdown
                      String nomorHewan = _nomorHewanController.text;
                      double berat = double.parse(_beratController.text);
                      String tanggalMasuk = DateFormat('yyyy-MM-dd').format(_tanggalMasuk);

                      // Periksa apakah pengguna terautentikasi
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anda harus login terlebih dahulu')));
                        return;
                      }

                      try {
                        // Simpan data ke Firebase
                        DatabaseReference ref = FirebaseDatabase.instance.ref("hewan/$nomorHewan");
                        await ref.set({
                          'jenis_hewan': jenisHewan,
                          'nomor_hewan': nomorHewan,
                          'jenis_kelamin': _kelamin,
                          'kesehatan': _status,
                          'kategori': _kategori,
                          'umur_hewan': _umurHewan,
                          'tanggal_masuk': tanggalMasuk,
                          'image_url': _imageUrl,  // Simpan URL gambar
                          'ownerId': '',  // Simpan ID pengguna yang memiliki hewan
                          'kandangId': _selectedKandang,  // Simpan ID kandang tempat hewan berada
                          'harga': _hargaHewan,  // Simpan harga hewan
                          'update_harga_info': _updateHargaInfo,  // Simpan informasi update harga
                        });

                        DatabaseReference api = FirebaseDatabase.instance.ref("bobot").push();
                        await api.set({
                          'nomor_hewan':nomorHewan,
                          'bobot': berat,
                          'tanggal' : tanggalMasuk,
                        });

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => Homepage())
                        );
                        // Kembali ke halaman sebelumnya setelah berhasil menyimpan data
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil ditambahkan')));
                      } catch (e) {
                        // Tangani kesalahan saat menyimpan data
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
                      }
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}