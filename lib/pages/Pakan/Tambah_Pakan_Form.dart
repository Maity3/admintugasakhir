import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:sobatternak_admin_web/Homepage.dart';

class TambahPakanForm extends StatefulWidget {
  const TambahPakanForm({Key? key}) : super(key: key);

  @override
  _TambahPakanFormState createState() => _TambahPakanFormState();
}

class _TambahPakanFormState extends State<TambahPakanForm> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _stockPakanController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Nutrisi data
  final Map<String, dynamic> nutrisiData = {
    'Rumput Gajah': {"PK": 10.0, "SK": 30.0, "EM": 1.8},
    'Rumput Ilalang': {"PK": 8.0, "SK": 35.0, "EM": 1.5},
    'Bekatul': {"PK": 11.0, "SK": 14.0, "EM": 2.7},
    'Daun Singkong': {"PK": 25.0, "SK": 18.0, "EM": 2.4},
    'Jagung Giling': {"PK": 9.0, "SK": 3.0, "EM": 3.3},
    'Bungkil Kedelai': {"PK": 45.0, "SK": 6.0, "EM": 2.8},
    'Tepung Ikan': {"PK": 60.0, "SK": 2.0, "EM": 4.0},
  };

  // Harga per kilo
  final Map<String, double> hargaPakan = {
    'Rumput Gajah': 4000,
    'Rumput Ilalang': 3000,
    'Bekatul': 7000,
    'Daun Singkong': 5000,
    'Jagung Giling': 6000,
    'Bungkil Kedelai': 10000,
    'Tepung Ikan': 20000,
  };

  String? _selectedJenisPakan;
  double? _currentPricePerKilo;
  Map<String, double>? _currentNutrisi;

  void _updateDetails() {
    if (_selectedJenisPakan != null) {
      _currentPricePerKilo = hargaPakan[_selectedJenisPakan];
      _currentNutrisi = nutrisiData[_selectedJenisPakan];
    } else {
      _currentPricePerKilo = null;
      _currentNutrisi = null;
    }
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _expirationDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String jenisPakan = _selectedJenisPakan!;
    double stockPakan = double.tryParse(_stockPakanController.text) ?? 0;

    try {
      DatabaseReference pakanRef = FirebaseDatabase.instance.ref("pakan").push();
      await pakanRef.set({
        "jenis_pakan": jenisPakan,
        "quality_stock": stockPakan,
        "harga_per_kilo": _currentPricePerKilo,
        "tanggal_kedaluwarsa": _expirationDateController.text,
        "deskripsi": _descriptionController.text,
        "nutrisi": _currentNutrisi,
      });

      _showFlushBar("Pakan telah ditambahkan", Colors.green, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      });
    } catch (e) {
      _showFlushBar("Penambahan pakan gagal: $e", Colors.red, () {});
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
        title: Text('Tambah Pakan'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedJenisPakan,
                    decoration: InputDecoration(labelText: 'Jenis Pakan'),
                    items: hargaPakan.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedJenisPakan = value;
                        _updateDetails();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Harap pilih jenis pakan';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _stockPakanController,
                    decoration: InputDecoration(labelText: 'Stock Pakan (kg)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap isi stock pakan';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _expirationDateController,
                    decoration: InputDecoration(labelText: 'Tanggal Kedaluwarsa'),
                    readOnly: true,
                    onTap: () => _selectExpirationDate(context),
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Deskripsi Pakan'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap isi deskripsi pakan';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  if (_currentPricePerKilo != null) // Display price per kilo if available
                    Text(
                      'Harga per Kilo: Rp ${_currentPricePerKilo!.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  SizedBox(height: 20),
                  // Display Nutrisi in Table Format
                  if (_currentNutrisi != null)
                    DataTable(
                      columns: [
                        DataColumn(label: Text('Nutrisi')),
                        DataColumn(label: Text('Kandungan')),
                      ],
                      rows: [
                        DataRow(cells: [
                          DataCell(Text('Protein Kasar (PK)')),
                          DataCell(Text('${_currentNutrisi!['PK']} %')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Serat Kasar (SK)')),
                          DataCell(Text('${_currentNutrisi!['SK']} %')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Energi Metabolik (EM)')),
                          DataCell(Text('${_currentNutrisi!['EM']} MJ/kg')),
                        ]),
                      ],
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleSignUp,
                    child: Text('Tambah Pakan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stockPakanController.dispose();
    _expirationDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
