import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PerawatanKandangPage extends StatefulWidget {
  final String kandangId;
  final String ownerId;

  PerawatanKandangPage({required this.kandangId, required this.ownerId});

  @override
  _PerawatanKandangPageState createState() => _PerawatanKandangPageState();
}

class _PerawatanKandangPageState extends State<PerawatanKandangPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> _perawatanKandang = [];
  int _tarifPerawatan = 0;
  String tanggalPerawatan = DateFormat('dd-MM-yyyy').format(DateTime.now());

  void _savePerawatanKandang() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save(); // Simpan nilai dari form

    try {
      // Ambil tanggal saat ini dengan format yang valid
      String tanggalPerawatan = DateFormat('dd-MM-yyyy').format(DateTime.now());
      // Gabungkan semua perawatan menjadi satu string, dipisahkan oleh koma
      String perawatanString = _perawatanKandang.join(", ");

      // Buat data perawatan
      Map<String, dynamic> perawatanData = {
        'tanggal': tanggalPerawatan,
        'perawatan': perawatanString, // Simpan sebagai string tunggal
        'tarif': _tarifPerawatan,
        'kandangId': widget.kandangId,
        'ownerId': widget.ownerId,
        'status_pembayaran': 'pending'
      };

      // Simpan ke Firebase
      DatabaseReference perawatanRef = FirebaseDatabase.instance
          .ref()
          .child('riwayat_perawatan')
          .child(widget.kandangId)// Gunakan format tanggal yang valid
          .push();

      await perawatanRef.set(perawatanData);

      print("Perawatan kandang berhasil disimpan");

      DatabaseReference tagihanRef = FirebaseDatabase.instance
          .ref()
          .child('tagihan/perawatan')
          .push();  // Menggunakan push() untuk membuat ID unik
      
      await tagihanRef.set(perawatanData);

      print("Perawatan kandang dan tagihan berhasil disimpan");

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perawatan kandang berhasil disimpan')),
      );

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    } catch (e) {
      print("Kesalahan menyimpan perawatan kandang: $e");

      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan perawatan kandang: $e')),
      );
    }
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Perawatan Kandang'),
    ),
    body: Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Perawatan Kandang"),
            CheckboxListTile(
              title: Text("Kebersihan Kandang"),
              value: _perawatanKandang.contains("Kebersihan Kandang"),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _perawatanKandang.add("Kebersihan Kandang");
                    _tarifPerawatan += 70000;
                  } else {
                    _perawatanKandang.remove("Kebersihan Kandang");
                    _tarifPerawatan -= 70000;
                  }
                });
              },
            ),
            CheckboxListTile(
              title: Text("Kebersihan Hewan"),
              value: _perawatanKandang.contains("Kebersihan Hewan"),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _perawatanKandang.add("Kebersihan Hewan");
                    _tarifPerawatan += 70000;
                  } else {
                    _perawatanKandang.remove("Kebersihan Hewan");
                    _tarifPerawatan -= 70000;
                  }
                });
              },
            ),
            CheckboxListTile(
              title: Text("Pemberian Pakan"),
              value: _perawatanKandang.contains("Pemberian Pakan"),
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _perawatanKandang.add("Pemberian Pakan");
                    _tarifPerawatan += 50000;
                  } else {
                    _perawatanKandang.remove("Pemberian Pakan");
                    _tarifPerawatan -= 50000;
                  }
                });
              },
            ),
            SizedBox(height: 16),
            Text("Harga Perawatan"),
            Text(_tarifPerawatan.toString()),
            SizedBox(height: 10),
            Text('Perawat Kandang (dilakukan setiap 2 minggu)'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _savePerawatanKandang,
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    ),
  );
}
}