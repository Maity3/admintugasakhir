import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:sobatternak_admin_web/Homepage.dart';

class TambahKandangForm extends StatefulWidget {
  const TambahKandangForm({Key? key}) : super(key: key);

  @override
  State<TambahKandangForm> createState() => _TambahKandangFormState();
}

class _TambahKandangFormState extends State<TambahKandangForm> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomorKandangControllerController = TextEditingController();
  final TextEditingController _lokasiKandangController = TextEditingController();
  final TextEditingController _namaKandangController = TextEditingController();
  final List<String> _ukuranKandangList = ["4x3", "6x4", "8x6"];
  final List<String> _kategoriKandangList = ["Penggemukan", "Pemeliharaan"];

  String _nomorKandangController = "";
  String _namaKandang = "";
  String _lokasiKandang = "";
  String? _ukuranKandang = "4x3";
  String? _kategoriKandang = "Penggemukan"; // Default kategori adalah Penggemukan
  int _kapasitasKandang = 0; // Tetapkan nilai awal
  String _kategoriDescription = "Kandang untuk proses penggemukan kambing."; // Keterangan default

  void _tambahKandang() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _nomorKandangController = _nomorKandangControllerController.text;
    _namaKandang = _namaKandangController.text;
    _lokasiKandang = _lokasiKandangController.text;

    // Mengatur kapasitas kandang berdasarkan ukuran kandang
    switch (_ukuranKandang) {
      case "4x3":
        _kapasitasKandang = 6;
        break;
      case "6x4":
        _kapasitasKandang = 8;
        break;
      case "8x6":
        _kapasitasKandang = 12;
        break;
      default:
        _kapasitasKandang = 0;
    }

    try {
      DatabaseReference kandangRef = FirebaseDatabase.instance.ref("kandang/$_nomorKandangController");

      await kandangRef.set({
        "nomor_kandang": _nomorKandangController,
        "nama_kandang": _namaKandang,
        "lokasi_kandang": _lokasiKandang,
        "kapasitas_kandang": _kapasitasKandang,
        "ukuran_kandang": _ukuranKandang,
        "kategori": _kategoriKandang,
        "deskripsi_kategori": _kategoriDescription, // Keterangan kategori kandang
      });

      _showFlushBar("Kandang telah ditambahkan", Colors.green, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      });
    } catch (e) {
      _showFlushBar("Penambahan kandang gagal: $e", Colors.red, () {});
    }
  }

  void _showFlushBar(String message, Color color, VoidCallback onDismiss) {
    Flushbar(
      message: message,
      backgroundColor: color,
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      onStatusChanged: (status) {
        if (status == FlushbarStatus.DISMISSED) {
          onDismiss();
        }
      },
    )..show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/icon/empty_livestock.png',
                          width: 100,
                          height: 100,
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Tambah Kandang",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _nomorKandangControllerController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                      ),
                      labelText: "Nomor Kandang",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Masukkan Nomor Kandang";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _nomorKandangController = value;
                      });
                    },
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _namaKandangController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                      ),
                      labelText: "Nama Kandang",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Masukkan Nama Kandang";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _namaKandang = value;
                      });
                    },
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _lokasiKandangController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                      ),
                      labelText: "Lokasi Kandang",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Masukkan Lokasi Kandang";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _lokasiKandang = value;
                      });
                    },
                  ),
                  SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _ukuranKandang,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                      ),
                      labelText: "Ukuran Kandang",
                    ),
                    items: _ukuranKandangList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _ukuranKandang = newValue!;
                        // Mengatur kapasitas kandang berdasarkan ukuran kandang
                        switch (_ukuranKandang) {
                          case "4x3":
                            _kapasitasKandang = 6;
                            break;
                          case "6x4":
                            _kapasitasKandang = 8;
                            break;
                          case "8x6":
                            _kapasitasKandang = 12;
                            break;
                          default:
                            _kapasitasKandang = 0;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Kapasitas Kandang: $_kapasitasKandang",
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _kategoriKandang,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                      ),
                      labelText: "Kategori Kandang",
                    ),
                    items: _kategoriKandangList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _kategoriKandang = newValue!;
                        // Mengatur keterangan kategori berdasarkan pilihan
                        if (_kategoriKandang == "Penggemukan") {
                          _kategoriDescription = "Kandang untuk proses penggemukan kambing.";
                        } else if (_kategoriKandang == "Pemeliharaan") {
                          _kategoriDescription = "Kandang untuk pemeliharaan kambing jangka panjang.";
                        }
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Keterangan: $_kategoriDescription",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _tambahKandang,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(85, 35, 124, 0.923),
                    ),
                    child: Text("Tambah", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
