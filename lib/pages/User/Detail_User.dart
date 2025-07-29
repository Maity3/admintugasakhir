import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sobatternak_admin_web/pages/Kandang/Kandang_User.dart';


class DetailUserPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  DetailUserPage({required this.userData});

  @override
  _DetailUserPageState createState() => _DetailUserPageState();
}

class _DetailUserPageState extends State<DetailUserPage> {
  String? selectedKandang;
  Map<String, String>? selectedkandangData;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _loadSelectedkandangData();
  }

  Future<void> _loadSelectedkandangData() async {
    String? kandangId = widget.userData['selectedKandang'];
    if (kandangId != null) {
      await _fetchSelectedkandangData(kandangId);
    }
  }

  Future<void> tambahKandangKePengguna(String userId, Map<String, dynamic> dataKandang) async {
  try {
    DatabaseReference kandangRef = _database.ref().child("users").child(userId).child("kandangs").push();
    await kandangRef.set(dataKandang);
    print("Kandang berhasil ditambahkan ke pengguna dengan ID: $userId");
  } catch (e) {
    print("Kesalahan saat menambahkan kandang: $e");
    rethrow;
  }
}

  Future<void> _fetchSelectedkandangData(String kandangId) async {
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang").child(kandangId);
    DataSnapshot snapshot;
    try {
      snapshot = await kandangRef.get();
      if (snapshot.exists) {
        if (!mounted) return;
        setState(() {
          selectedkandangData = {
            'nomor_kandang': snapshot.child('nomor_kandang').value as String,
            'nama_kandang': snapshot.child('nama_kandang').value as String,
            'lokasi_kandang': snapshot.child('lokasi_kandang').value as String,
            'kapasitas_kandang': snapshot.child('kapasitas_kandang').value?.toString() ?? 'N/A',
            'kategori': snapshot.child('kategori').value?.toString() ?? 'N/A',
            'ukuran_kandang': snapshot.child('ukuran_kandang').value as String,
            'ownerId' : snapshot.child('ownerId').value as String,
            'statusKepemilikan': snapshot.child('ownerId').value != null ? 'Sudah Dimiliki' : 'Belum Dimiliki',
          };
        });
      } else {
        print('Kandang details not found');
      }
    } catch (e) {
      print('Error fetching kandang details: $e');
    }
  }

  int _getKapasitas(String ukuranKandang) {
    switch (ukuranKandang) {
      case "1x2":
        return 4;
      case "2x4":
        return 6;
      case "4x6":
        return 8;
      case "4x8":
        return 10;
      case "6x8":
        return 12;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userData['name']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, widget.userData['uid']);
                  },
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(labelText: 'ID Pengguna'),
              controller: TextEditingController(text: widget.userData['uid']),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Nama'),
              controller: TextEditingController(text: widget.userData['name']),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: widget.userData['email']),
              readOnly: true,
            ),
            SizedBox(height: 16),
            Text(
              'Daftar Kandang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            FutureBuilder<List<Map<String, String>>>(
              future: _fetchUserKandangs(widget.userData['uid']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Belum ada kandang');
                } else {
                  return Column(
                    children: snapshot.data!.map((kandang) {
                      return ListTile(
                        title: Text(kandang['nomor_kandang']!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteKandangConfirmationDialog(context, kandang['id']!, widget.userData['uid']);
                              },
                            ),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KandangUserPage(
                                kandangData: kandang,
                               
                                userId: widget.userData['uid'],),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                _showKandangDialog(context);
              },
              child: Text('Tambah Kandang'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditDialog(context, widget.userData);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showKandangDialog(BuildContext context) async {
    List<Map<String, String>> kandangList = await _fetchKandangNames();

    if (kandangList.isEmpty) {
      print('No kandang available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Kandang"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: selectedKandang,
                hint: Text("Pilih Kandang"),
                items: kandangList.map((Map<String, String> kandang) {
                  return DropdownMenuItem<String>(
                    value: kandang['id'],
                    child: Text(kandang['nomor_kandang'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedKandang = newValue;
                  });
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Tutup"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedKandang != null) {
                  await _saveSelectedKandang(widget.userData['uid'], selectedKandang!);
                  await _fetchSelectedkandangData(selectedKandang!);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kandang berhasil dipilih')),
                  );
                  setState(() {});
                } else {
                  print('Kandang terpilih bernilai null');
                }
              },
              child: Text("Pilih"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateKandangStatus(String kandangId, String userId) async {
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang").child(kandangId);
    try {
      await kandangRef.update({
        'status': 'dimiliki',
        'ownerId': userId,
      });
      print('Status kandang berhasil diperbarui');
    } catch (e) {
      print('Error memperbarui status kandang: $e');
    }
  }

  Future<void> _saveSelectedKandang(String userId, String kandangId) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userId);
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang").child(kandangId);
    DataSnapshot snapshot;

    try {
      snapshot = await kandangRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> kandangData = {
          'nomor_kandang': snapshot.child('nomor_kandang').value as String,
          'nama_kandang': snapshot.child('nama_kandang').value as String,
          'lokasi_kandang': snapshot.child('lokasi_kandang').value as String,
          'ukuran_kandang': snapshot.child('ukuran_kandang').value as String,
          'kategori': snapshot.child('kategori').value as String,
          
        };
        
        // Simpan data kandang ke user
        await userRef.child("kandangs").child(kandangId).set(kandangData);
        
        // Perbarui data user dengan kandang yang dipilih

        // Ambil nama user
        DataSnapshot userSnapshot = await userRef.child('name').get();

        // Perbarui status kandang
        await _updateKandangStatus(kandangId, userId);

        print('Kandang terpilih berhasil ditambahkan untuk pengguna $userId');
      } else {
        print('Detail kandang tidak ditemukan');
      }
    } catch (e) {
      print('Error menambahkan kandang terpilih untuk pengguna $userId: $e');
    }
  }

  Future<List<Map<String, String>>> _fetchKandangNames() async {
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang");
    DataSnapshot snapshot;
    List<Map<String, String>> kandangList = [];

    try {
      snapshot = await kandangRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> kandangData = snapshot.value as Map<dynamic, dynamic>;
        kandangData.forEach((key, value) {
          if (value['nomor_kandang'] != null) {
            kandangList.add({
              'id': key,
              'nomor_kandang': value['nomor_kandang'] ?? 'Unknown'
            });
          } else {
            print('Kandang with key $key has no nomor_kandang');
          }
        });
      } else {
        print('Snapshot does not exist');
      }
    } catch (e) {
      print('Error fetching kandang names: $e');
    }

    return kandangList;
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> userData) {
    String uid = userData['uid'];
    TextEditingController nameController = TextEditingController(text: userData['name']);
    TextEditingController emailController = TextEditingController(text: userData['email']);
    TextEditingController namaKandangController = TextEditingController(text: selectedkandangData?['name']);
    TextEditingController lokasiKandangController = TextEditingController(text: selectedkandangData?['lokasi']);
    String? selectedUkuranKandang = selectedkandangData?['ukuran'];
    String? selectedKategoriKandang = selectedkandangData?['kategori'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Data Pengguna dan Kandang"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Nama'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    if (selectedkandangData != null) ...[
                      TextField(
                        controller: namaKandangController,
                        decoration: InputDecoration(labelText: "Nama Kandang"),
                      ),
                      TextField(
                        controller: lokasiKandangController,
                        decoration: InputDecoration(labelText: "Lokasi Kandang"),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedUkuranKandang,
                        items: ["1x2", "2x4", "4x6", "4x8", "6x8"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(labelText: "Ukuran Kandang"),
                        onChanged: (newValue) {
                          setState(() {
                            selectedUkuranKandang = newValue;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedKategoriKandang,
                        items: ["penggemukan","pemeliharaan"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(labelText: "Ukuran Kandang"),
                        onChanged: (newValue) {
                          setState(() {
                            selectedUkuranKandang = newValue;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    _updateUserData(uid, {
                      "name": nameController.text,
                      "email": emailController.text,
                    });
                    if (selectedkandangData != null) {
                      DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang").child(selectedkandangData!['id']!);
                      await kandangRef.update({
                        'nama_kandang': namaKandangController.text,
                        'lokasi_kandang': lokasiKandangController.text,
                        'ukuran_kandang': selectedUkuranKandang,
                      });
                      setState(() {
                        selectedkandangData = {
                          'id': selectedkandangData!['id']!,
                          'nama_kandang': namaKandangController.text,
                          'lokasi_kandang': lokasiKandangController.text,
                          'ukuran_kandang': selectedUkuranKandang!,
                          'statusKepemilikan': selectedkandangData!['statusKepemilikan']!,
                          'kategori': selectedKategoriKandang!,
                        };
                      });
                    }
                    Navigator.of(context).pop();
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

  void _showDeleteKandangConfirmationDialog(BuildContext context, String kandangId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus Kandang"),
          content: Text("Apakah Anda yakin ingin menghapus kandang ini dari daftar Anda?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                await _removeKandangFromUser(kandangId, userId);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeKandangFromUser (String kandangId, String userId) async {
  try {
    // Hapus kandang dari data user
    DatabaseReference userKandangRef = FirebaseDatabase.instance.ref().child("users").child(userId).child("kandangs").child(kandangId);
    await userKandangRef.remove();
    print("Kandang berhasil dihapus dari daftar user");

    // Periksa apakah kandang masih ada di data_kandang
    DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang").child(kandangId);
    DataSnapshot snapshot = await kandangRef.get();

    if (snapshot.exists) {
      var kandangData = snapshot.value as Map?;
      if (kandangData != null && kandangData['ownerId'] == userId) {
        // Hapus field ownerId dan status dari data kandang
        await kandangRef.child('ownerId').remove(); // Hapus ownerId
        await kandangRef.child('status').remove(); // Hapus status
        print("ownerId dan status berhasil dihapus dari kandang: $kandangId");
      }
    } else {
      print("Kandang tidak ditemukan.");
    }

  } catch (e) {
    if (e.toString().contains("permission_denied")) {
      print("Tidak dapat mengakses atau memperbarui data kandang: Izin ditolak");
    } else {
      print("Error saat menghapus atau memperbarui kandang: $e");
    }
  }

    // Refresh data
    setState(() {});
  }

  void _showDeleteConfirmationDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus"),
          content: Text("Apakah Anda yakin ingin menghapus data ini?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUserData(uid);
              },
              child: Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserData(String uid) async {
  // Referensi ke data pengguna
  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(uid);
  
  // Ambil data kandang yang memiliki ownerId sama dengan uid
  DatabaseReference kandangRef = FirebaseDatabase.instance.ref().child("kandang");
  DataSnapshot kandangSnapshot = await kandangRef.get();

  if (kandangSnapshot.exists) {
    for (var child in kandangSnapshot.children) {
      var kandangData = child.value as Map?;
      if (kandangData != null && kandangData['ownerId'] == uid) {
        // Hapus field ownerId dan status dari data kandang
        await child.ref.child('ownerId').remove(); // Hapus ownerId
        await child.ref.child('status').remove(); // Hapus status
      }
    }
  }

  // Hapus data pengguna
  await userRef.remove();
  
  // Optionally, refresh data or state
  print("User  and related kandang data deleted successfully.");
}

  Future<void> _updateUserData(String uid, Map<String, dynamic> newData) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(uid);
    await userRef.update(newData);
    // Optionally, refresh data or state
  }
}

Future<List<Map<String, String>>> _fetchUserKandangs(String userId) async {
  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userId).child("kandangs");
  DataSnapshot snapshot;
  List<Map<String, String>> kandangList = [];

  try {
    snapshot = await userRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> kandangData = snapshot.value as Map<dynamic, dynamic>;
      kandangData.forEach((key, value) {
        kandangList.add({
          'id': key,
          'nomor_kandang': value['nomor_kandang'] ?? 'Unknown',
          'nama_kandang': value['nama_kandang'] ?? 'Unknown',
          'lokasi_kandang': value['lokasi_kandang'] ?? 'Unknown',
          'ukuran_kandang': value['ukuran_kandang'] ?? 'Unknown',
        });
      });
    } else {
      print('Snapshot does not exist');
    }
  } catch (e) {
    print('Error fetching user kandangs: $e');
  }

  return kandangList;
}