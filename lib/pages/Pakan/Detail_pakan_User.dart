import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DetailPakanUserPage extends StatefulWidget {
  final Map<String, dynamic> pakan;
  final String pakanId;

  DetailPakanUserPage({
    required this.pakan,
    required this.pakanId,
  });

  @override
  _DetailPakanUserPageState createState() => _DetailPakanUserPageState();
}

class _DetailPakanUserPageState extends State<DetailPakanUserPage> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.reference();
  List<Map<String, dynamic>> konsumsiHarian = [];

  @override
  void initState() {
    super.initState();
    loadKonsumsiHarian();
  }

  void loadKonsumsiHarian() {
    databaseReference
        .child('pakans/${widget.pakanId}/konsumsi_harian')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          konsumsiHarian = (event.snapshot.value as Map<Object?, Object?>)
              .entries
              .map((e) => {
                    'tanggal': e.key.toString(),
                    'jumlah': (e.value as Map<Object?, Object?>)['jumlah'],
                    'keterangan': (e.value as Map<Object?, Object?>)['keterangan'],
                  })
              .toList();
          konsumsiHarian.sort((a, b) => b['tanggal'].compareTo(a['tanggal']));
        });
      }
    });
  }

  void showKonsumsiDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _jumlahKonsumsiController = TextEditingController();
    final _keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Catat Konsumsi Pakan'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: _jumlahKonsumsiController,
                    decoration: InputDecoration(labelText: 'Jumlah Konsumsi (kg)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap isi jumlah konsumsi';
                      }
                      if (int.parse(value) > widget.pakan['jumlah_kg']) {
                        return 'Jumlah melebihi stok yang tersedia';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _keteranganController,
                    decoration: InputDecoration(labelText: 'Keterangan'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap isi keterangan';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Simpan'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  int jumlahKonsumsi = int.parse(_jumlahKonsumsiController.text);

                  // Update jumlah pakan yang tersisa
                  int sisaPakan = widget.pakan['jumlah_kg'] - jumlahKonsumsi;

                  // Update data pakan
                  Map<String, dynamic> updates = {};
                  updates['pakans/${widget.pakanId}/jumlah_kg'] = sisaPakan;
                  updates['pakans/${widget.pakanId}/konsumsi_harian/$today'] = {
                    'jumlah': jumlahKonsumsi,
                    'keterangan': _keteranganController.text,
                  };

                  databaseReference.update(updates).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Konsumsi pakan berhasil dicatat')),
                    );
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mencatat konsumsi: $error')),
                    );
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? nutrisi = widget.pakan['nutrisi'] != null
        ? Map<String, dynamic>.from(widget.pakan['nutrisi'] as Map<Object?, Object?>)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pakan'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => showKonsumsiDialog(context ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pakan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(),
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Jenis Pakan', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(widget.pakan['jenis_pakan']),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Kandang'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(widget.pakan['kandangId']),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Jumlah Tersisa'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('${widget.pakan['jumlah_kg']} kg'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Harga per Kilo'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Rp ${widget.pakan['harga_per_kilo']}'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Total Harga'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Rp ${widget.pakan['total_harga']}'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Status'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(widget.pakan['status']),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Status Pembayaran'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(widget.pakan['status_pembayaran']),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Tanggal Permintaan'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(widget.pakan['tanggal_permintaan']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (nutrisi != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Nutrisi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[200]),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Nutrisi', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Kandungan', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Protein Kasar (PK)'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('${nutrisi['PK']}%'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Serat Kasar (SK)'),
                              ),
                              Padding(
                              padding: EdgeInsets.all(8),
                                child: Text('${nutrisi['SK']}%'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Energi Metabolik (EM)'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('${nutrisi['EM']} MJ/kg'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Konsumsi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    if (konsumsiHarian.isEmpty)
                      Text('Belum ada data konsumsi')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: konsumsiHarian.length,
                        itemBuilder: (context, index) {
                          final konsumsi = konsumsiHarian[index];
                          return ListTile(
                            title: Text('Tanggal: ${konsumsi['tanggal']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jumlah: ${konsumsi['jumlah']} kg'),
                                Text('Keterangan: ${konsumsi['keterangan']}'),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}