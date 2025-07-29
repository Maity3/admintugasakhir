import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DetailHewanPage extends StatefulWidget {
  final String nomorHewan;

  DetailHewanPage({required this.nomorHewan});

  @override
  _DetailHewanPageState createState() => _DetailHewanPageState();
}

class _DetailHewanPageState extends State<DetailHewanPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DatabaseReference bobotRef = FirebaseDatabase.instance.ref().child('bobot');
  final DatabaseReference hargaRef = FirebaseDatabase.instance.ref().child('harga');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _hewanData;
  bool _canEditOrDelete = false;
  DateTime selectedDate = DateTime.now();
  String _currentPrice = 'Belum ditetapkan'; // Variable to store the current price
  String _priceUpdateInfo = ''; // Variable to store price update info

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _checkAuthAndFetchData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("User email: ${user.email}");
      _fetchHewanData(user.uid, user.email); // Pass user ID to fetch data
      _fetchHargaHewan(widget.nomorHewan); // Fetch price data for this animal
    } else {
      print("User not authenticated");
    }
  }

  // Metode untuk mengambil data harga dari hewan
  Future<void> _fetchHargaHewan(String nomorHewan) async {
    try {
      // Pertama, coba ambil harga dari dokumen hewan langsung (jika menggunakan format baru)
      DatabaseReference hewanRef = _database.ref().child("hewan/$nomorHewan");
      DataSnapshot snapshot = await hewanRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> hewanData = Map<String, dynamic>.from(snapshot.value as Map);
        
      // Cek apakah data hewan memiliki field harga
        if (hewanData.containsKey('harga')) {
          // Format harga dengan currency
          double price = double.parse(hewanData['harga']?.toString() ?? '0');
          final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          String formattedPrice = formatCurrency.format(price);
          
          // Tambahkan info update harga jika ada
          String updateInfo = '';
          if (hewanData.containsKey('update_harga_info') && hewanData['update_harga_info'] != null) {
            updateInfo = hewanData['update_harga_info'];
          }
          
          setState(() {
            _currentPrice = formattedPrice;
            _priceUpdateInfo = updateInfo;
          });
          return; // Keluar dari fungsi jika sudah mendapatkan harga
        }
      }
      
      // Jika tidak ada harga di dokumen hewan, coba ambil dari node harga terpisah
      DataSnapshot hargaSnapshot = await hargaRef.get();
      
      if (hargaSnapshot.exists && hargaSnapshot.value != null) {
        Map<String, dynamic> allHargaData = Map<String, dynamic>.from(hargaSnapshot.value as Map);
        List<Map<String, dynamic>> filteredData = [];

        allHargaData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            Map<String, dynamic> hargaEntry = Map<String, dynamic>.from(value);
            if (hargaEntry['nomor_hewan'] == nomorHewan) {
              hargaEntry['key'] = key; // Simpan key untuk referensi
              filteredData.add(hargaEntry);
            }
          }
        });

        if (filteredData.isNotEmpty) {
          // Urutkan berdasarkan tanggal terbaru jika ada field tanggal
          if (filteredData.first.containsKey('tanggal')) {
            filteredData.sort((a, b) => DateTime.parse(b['tanggal'])
                .compareTo(DateTime.parse(a['tanggal'])));
          }
          
          // Format harga dengan currency
          double price = double.parse(filteredData.first['harga']?.toString() ?? '0');
          final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          String formattedPrice = formatCurrency.format(price);
          
          setState(() {
            _currentPrice = formattedPrice;
          });
        }
      }
    } catch (e) {
      print("Error saat mengambil data harga: $e");
    }
  }

  Future<String> _getBobotHewan(String nomorHewan) async {
    try {
      DataSnapshot snapshot = await bobotRef.get();

      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> allBobotData =
            Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> filteredData = [];

        allBobotData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            Map<String, dynamic> bobotEntry = Map<String, dynamic>.from(value);
            if (bobotEntry['nomor_hewan'] == nomorHewan) {
              bobotEntry['key'] = key; // Save the key for reference
              filteredData.add(bobotEntry);
            }
          }
        });

        if (filteredData.isNotEmpty) {
          // Sort by date in descending order
          filteredData.sort((a, b) => DateTime.parse(b['tanggal'])
              .compareTo(DateTime.parse(a['tanggal'])));
          String latestBobot =
              filteredData.first['bobot']?.toString() ?? 'Belum dimiliki';
          String latestTanggal =
              filteredData.first['tanggal'] ?? 'Tanggal tidak tersedia';
          return '$latestBobot';
        }
      }
      return 'Belum dimiliki';
    } catch (e) {
      print("Error saat mengambil data: $e");
      return 'Belum dimiliki';
    }
  }

  Future<void> _fetchHewanData(String userId, String? email) async {
    try {
      DatabaseReference hewanRef =
          _database.ref().child("hewan/${widget.nomorHewan}");
      DataSnapshot snapshot = await hewanRef.get();
      if (snapshot.exists) {
        setState(() {
          _hewanData = Map<String, dynamic>.from(snapshot.value as Map);
        });

        // Check if the user is admin or owns the animal
        bool isAdmin = email ==
            'admin1@gmail.com'; // Ganti dengan logika yang sesuai untuk memeriksa admin
        bool isOwner = _hewanData!['ownerId'] == userId;

        // Simpan status akses untuk digunakan di UI
        _canEditOrDelete = isAdmin || isOwner;
      } else {
        print("No data available");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hewanData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Detail Hewan'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Hewan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(
                  text: 'Jenis Hewan: ${_hewanData!['jenis_hewan']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Nomor Hewan: ${_hewanData!['nomor_hewan']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Kelamin: ${_hewanData!['jenis_kelamin']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            FutureBuilder<String>(
              future: _getBobotHewan(_hewanData?['nomor_hewan']),
              builder: (context, snapshot) {
                return TextField(
                  controller: TextEditingController(
                      text: 'Bobot: ${snapshot.data ?? 'Belum dimiliki'} Kg'),
                  readOnly: true,
                  style: TextStyle(fontSize: 18),
                );
              },
            ),
            // Add price display field
            TextField(
              controller: TextEditingController(
                  text: 'Harga: $_currentPrice'),
              readOnly: true,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixIcon: _priceUpdateInfo.isNotEmpty ? 
                  Tooltip(
                    message: _priceUpdateInfo,
                    child: Icon(Icons.info_outline),
                  ) : null,
              ),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Umur Hewan: ${_hewanData!['umur_hewan']} Bulan'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Status: ${_hewanData!['kesehatan']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Kategori: ${_hewanData!['kategori']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Tanggal Masuk: ${_hewanData!['tanggal_masuk']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: TextEditingController(
                  text: 'Di Kandang: ${_hewanData!['kandangId']}'),
              readOnly: true,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (_canEditOrDelete) ...[
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _editHewan(_hewanData!);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteHewan(context, _hewanData!['id_hewan']);
                },
              ),
              // Add button to edit price
              IconButton(
                icon: Icon(Icons.attach_money),
                onPressed: () {
                  _editHargaHewan(_hewanData!);
                },
                tooltip: 'Edit Harga',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Method untuk mengedit harga hewan
  void _editHargaHewan(Map<String, dynamic> hewan) async {
    // Cari harga saat ini tanpa format mata uang
    String currentPriceRaw = _currentPrice.replaceAll('Rp ', '').replaceAll('.', '');
    if (currentPriceRaw.contains('(')) {
      // Hapus info update harga jika ada
      currentPriceRaw = currentPriceRaw.substring(0, currentPriceRaw.indexOf('(')).trim();
    }
    
    if (currentPriceRaw == 'Belum ditetapkan') {
      currentPriceRaw = '0';
    }
    
    final TextEditingController hargaController = 
        TextEditingController(text: currentPriceRaw);
    final TextEditingController infoController = 
        TextEditingController(text: hewan['update_harga_info'] ?? 'Update Harga Kambing ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}');

    // Initialize selectedDate with current date
    setState(() {
      selectedDate = DateTime.now();
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Harga Hewan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: hargaController,
                      decoration: InputDecoration(
                        labelText: "Harga (Rp)",
                        prefixText: "Rp ",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: infoController,
                      decoration: InputDecoration(
                        labelText: "Info Update Harga",
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Tanggal: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _selectDate(context);
                            setDialogState(() {}); // Update dialog state to show new date
                          },
                          child: Text("Pilih Tanggal"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      double hargaValue = double.parse(hargaController.text);
                      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                      String updateInfo = infoController.text;

                      // Perbarui data harga di dokumen hewan
                      DatabaseReference hewanRef = FirebaseDatabase.instance
                          .ref("hewan/${widget.nomorHewan}");
                      await hewanRef.update({
                        'harga': hargaValue,
                        'update_harga_info': updateInfo,
                      });

                      // Simpan juga riwayat perubahan harga
                      DatabaseReference hargaHistoryRef = FirebaseDatabase.instance.ref("harga").push();
                      await hargaHistoryRef.set({
                        'nomor_hewan': widget.nomorHewan,
                        'harga': hargaValue,
                        'tanggal': formattedDate,
                        'update_info': updateInfo,
                      });

                      // Refresh data
                      _fetchHargaHewan(widget.nomorHewan);

                      // Tutup dialog
                      Navigator.of(context).pop();

                      // Tampilkan notifikasi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Harga berhasil diperbarui'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal memperbarui harga: $e'),
                        ),
                      );
                    }
                  },
                  child: Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editHewan(Map<String, dynamic> hewan) async {
    final TextEditingController kelaminController =
        TextEditingController(text: hewan['jenis_kelamin']);
    final TextEditingController beratController =
        TextEditingController(text: hewan['bobot'].toString());
    final TextEditingController statusController =
        TextEditingController(text: hewan['kesehatan']);
        final TextEditingController umurController =
        TextEditingController(text: hewan['umur_hewan']);
    final TextEditingController kategoriController =
        TextEditingController(text: hewan['kategori']);

    // Initialize selectedDate with current date
    setState(() {
      selectedDate = DateTime.now();
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Data Hewan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: kelaminController,
                      decoration: InputDecoration(labelText: "Kelamin"),
                    ),
                    FutureBuilder<String>(
                      future: _getBobotHewan(
                          hewan['nomor_hewan']), // Ambil bobot terbaru
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(); // Tampilkan loading indicator
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error: ${snapshot.error}'); // Tampilkan pesan error
                        } else {
                          // Set nilai bobot terbaru ke controller
                          beratController.text =
                              snapshot.data ?? hewan['bobot'].toString();
                          return TextField(
                            controller: beratController,
                            decoration: InputDecoration(labelText: "Bobot"),
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 18),
                          );
                        }
                      },
                    ),
                    TextField(
                      controller: umurController,
                      decoration: InputDecoration(labelText: "Umur"),
                    ),
                    TextField(
                      controller: statusController,
                      decoration: InputDecoration(labelText: "Status"),
                    ),
                    TextField(
                      controller: kategoriController,
                      decoration: InputDecoration(labelText: "Kategori"),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Tanggal: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _selectDate(context);
                            setDialogState(
                                () {}); // Update dialog state to show new date
                          },
                          child: Text("Pilih Tanggal"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      double beratValue = double.parse(beratController.text);
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(selectedDate);

                      // Update data hewan
                      DatabaseReference ref = FirebaseDatabase.instance.ref("hewan/${widget.nomorHewan}");
                      await ref.update({
                        'jenis_kelamin': kelaminController.text,
                        'kesehatan': statusController.text,
                        'kategori': kategoriController.text,
                        'umur_hewan': umurController.text,
                      });

                      // Simpan riwayat bobot
                      DatabaseReference bobotHistoryRef =
                          FirebaseDatabase.instance.ref("bobot").push();
                      await bobotHistoryRef.set({
                        'nomor_hewan': widget.nomorHewan,
                        'bobot': beratValue,
                        'tanggal': formattedDate,
                      });

                      // Refresh data
                      _checkAuthAndFetchData();

                      // Tutup dialog
                      Navigator.of(context).pop();

                      // Tampilkan notifikasi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Data berhasil diperbarui dan riwayat bobot disimpan')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal memperbarui data: $e')),
                      );
                    }
                  },
                  child: Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteHewan(BuildContext context, String hewanId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menghapus data hewan ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                DatabaseReference ref =
                    FirebaseDatabase.instance.ref("hewan/$hewanId");
                ref.remove().then((_) {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pop(true); // Kembali ke halaman sebelumnya
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data berhasil dihapus')));
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus data: $error')));
                });
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}