import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sobatternak_admin_web/pages/Kandang/DetailKandang.dart';
import 'package:sobatternak_admin_web/pages/Kandang/Tambah_Kandang_Form.dart';
import 'package:sobatternak_admin_web/pages/Kandang/pemberitahuan_kandang.dart';

class DataKandangPage extends StatefulWidget {
  @override
  _DataKandangPageState createState() => _DataKandangPageState();
}

class _DataKandangPageState extends State<DataKandangPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _kandangList = [];
  final List<String> _ukuranKandangList = ["4x3", "6x4", "8x6"];
  final List<String> _kategoriKandangList = ["Penggemukan", "Pemeliharaan"];
  int _stockKandang = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  void _checkAuthAndFetchData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("User email: ${user.email}");
      if (user.email == 'admin1@gmail.com') {
        _fetchKandangData();
      } else {
        print("Pengguna tidak memiliki izin");
      }
    } else {
      print("Pengguna tidak terautentikasi");
    }
  }


  Future<List<Map<String, dynamic>>> fetchKandangData() async {
    try {
      DatabaseReference kandangRef = _database.ref().child("kandang");
      DataSnapshot snapshot = await kandangRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> kandangList = [];
        snapshot.children.forEach((child) {
          var kandangData = child.value as Map?;
          if (kandangData != null) {
            kandangList.add(Map<String, dynamic>.from(kandangData));
          }
        });
        print("Data kandang fetched from Firebase: $kandangList");
        return kandangList;
      } else {
        print("No data available");
        return [];
      }
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

 Future<void> _fetchKandangData() async {
    List<Map<String, dynamic>> kandangList = await fetchKandangData();
    setState(() {
      _kandangList = kandangList;
      _stockKandang = kandangList.length; // Memperbarui jumlah stock kandang
    });
    await _updateKandangStatus();
  }

  void _editKandang(Map<String, dynamic> kandang) async {
    TextEditingController namaController = TextEditingController(text: kandang['nama_kandang']);
    TextEditingController lokasiController = TextEditingController(text: kandang['lokasi_kandang']);
    String? selectedUkuranKandang = kandang['ukuran_kandang'];
    String? selectedKategoriKandang = kandang['kategori_kandang'];
    String nomor_kandang = kandang['nomor_kandang'];

    void _updateKapasitasKandang(String? ukuran) {
      switch (ukuran) {
        case "4x3":
          kandang['kapasitas_kandang'] = 6;
          break;
        case "6x4":
          kandang['kapasitas_kandang'] = 8;
          break;
        case "8x6":
          kandang['kapasitas_kandang'] = 12;
          break;
        default:
          kandang['kapasitas_kandang'] = 0;
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey,
              title: Text("Edit Kandang"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: InputDecoration(labelText: "Nama Kandang"),
                    ),
                    TextField(
                      controller: lokasiController,
                      decoration: InputDecoration(labelText: "Lokasi Kandang"),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedUkuranKandang,
                      items: _ukuranKandangList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(85, 35, 124, 0.923)),
                        ),
                        labelText: "Ukuran Kandang",
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          selectedUkuranKandang = newValue;
                          _updateKapasitasKandang(newValue);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Pilih Ukuran Kandang";
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedKategoriKandang, // Tambahkan kategori kandang
                      items: _kategoriKandangList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "Kategori Kandang",
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          selectedKategoriKandang = newValue;
                        });
                      },
                    ),
                    if (selectedUkuranKandang != null)
                      Text(
                        "Kapasitas maksimum: ${kandang['kapasitas_kandang']} hewan",
                        style: TextStyle(color: Colors.black),
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
                      User? user = _auth.currentUser;
                      if (user != null) {
                        print("User email: ${user.email}");
                        if (user.email == 'admin1@gmail.com') {
                          DatabaseReference kandangRef = _database.ref().child("kandang").child(nomor_kandang);
                          print("Updating kandang with ID: $nomor_kandang");
                          await kandangRef.update({
                            'nomorkandang': nomor_kandang,
                            'nama_kandang': namaController.text,
                            'lokasi_kandang': lokasiController.text,
                            'kapasitas_kandang': kandang['kapasitas_kandang'],
                            'ukuran_kandang': selectedUkuranKandang,
                            'kategori_kandang': selectedKategoriKandang,
                          });
                          setState(() {
                            kandang['nama_kandang'] = namaController.text;
                            kandang['lokasi_kandang'] = lokasiController.text;
                            kandang['ukuran_kandang'] = selectedUkuranKandang;
                            kandang['kategori_kandang'] = selectedKategoriKandang;
                          });
                          print("Kandang dengan ID $nomor_kandang berhasil diperbarui di Firebase");
                          Navigator.of(context).pop();
                        } else {
                          print("User does not have permission");
                        }
                      } else {
                        print("User not authenticated");
                      }
                    } catch (e) {
                      print("Error updating kandang: $e");
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

  void _deleteKandang(String kandangId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email == 'admin1@gmail.com') {
        DatabaseReference kandangRef = _database.ref().child("kandang").child(kandangId);
        print("Deleting kandang with ID: $kandangId");
        await kandangRef.remove();
        setState(() {
          _kandangList.removeWhere((kandang) => kandang['nomor_kandang'] == kandangId);
        });
        print("Kandang dengan ID $kandangId berhasil dihapus dari Firebase");
      } else {
        print("User does not have permission");
      }
    } catch (e) {
      print("Error deleting kandang: $e");
    }
  }

  Future<void> _updateKandangStatus() async {
    for (var kandang in _kandangList) {
      String kandangId = kandang['nomor_kandang'];
      DatabaseReference kandangRef = _database.ref().child("kandang").child(kandangId);
      DataSnapshot snapshot = await kandangRef.child('ownerId').get();

      if (snapshot.exists && snapshot.value != null) {
        String userId = snapshot.value as String;
        DatabaseReference userRef = _database.ref().child("users").child(userId);
        DataSnapshot userSnapshot = await userRef.child('selectedKandang').get();
        if (userSnapshot.exists && userSnapshot.value == kandangId) {
          // Jika user masih memiliki kandang ini, tidak perlu update
          continue;
        }
      } else {
        
        continue;
      }
    }
    setState(() {});
  }

  Future<String> _getUserName(String userId) async {
    DataSnapshot snapshot = await userRef.child(userId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      print('User  data: $userData');
      return userData['name']?.toString() ?? 'Belum dimiliki';
    }
    print('User  not found or data is null');
    return 'Belum dimiliki';
  }

  Future<void> _saveSelectedKandang(String userId, String kandangId) async {
    DatabaseReference userRef = _database.ref().child("users").child(userId);
    try {
      await userRef.update({'selectedKandang': kandangId});
      print('Selected kandang updated successfully for user $userId');
    } catch (e) {
      print('Error updating selected kandang for user $userId: $e');
      return;
    }

    DatabaseReference kandangRef = _database.ref().child("kandang").child(kandangId);
    DataSnapshot snapshot;
    try {
      snapshot = await kandangRef.get();
      print('Snapshot data: ${snapshot.value}');
    } catch (e) {
      print('Error fetching kandang details: $e');
      return;
    }

    if (snapshot.exists) {
      var kandangData = snapshot.value as Map?;
      if (kandangData != null) {
        setState(() {
          _kandangList = _kandangList.map((kandang) {
            if (kandang['nomor_kandang'] == kandangId) {
              return {
                'nomor_kandang': kandangId,
                'nama_kandang': kandangData['nama_kandang'] as String,
                'lokasi_kandang': kandangData['lokasi_kandang'] as String,
                'kapasitas_kandang': kandangData['kapasitas_kandang']?.toString() ?? 'N/A',
                'ukuran_kandang': kandangData['ukuran_kandang'] as String,
                'kategori': kandangData['kategori']?.toString() ?? 'N/A',
                'ownerId': kandangData['ownerId'] as String,
              };
            }
            return kandang;
          }).toList();
        });
        print('Kandang details updated: ${_kandangList.firstWhere((kandang) => kandang['nomor_kandang'] == kandangId)}');
      } else {
        print('Kandang data is null');
      }
    } else {
      print('Kandang details not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Kandang"),
        actions: [
           Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
              icon: Icon(Icons.notifications),
              onPressed: (){
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => pemberitahuanKandang()),
                );
              },
            ),
            IconButton(
                icon: Icon(Icons.add), // Icon + untuk menambah kandang
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TambahKandangForm()), // Navigasi ke halaman tambahKandangForm
                  );
                },
              ),
              Text("Stock Kandang: $_stockKandang"), // Menampilkan jumlah stock kandang
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _fetchKandangData, // Pastikan ini memperbarui _stockKandang
              ),
            ],
          ),
        ],
      ),
      body: _kandangList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _kandangList.length,
              itemBuilder: (context, index) {
                final kandang = _kandangList[index];
                String statusDisplay = kandang['status'] ?? 'Belum dimiliki';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailKandangPage(
                          kandangId: kandang['nomor_kandang'],
                          kandangData: kandang,
                        ),
                      ),
                    );
                    print("Kandang dipilih: ${kandang['nama_kandang']}");
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nomor Kandang: ${kandang['nomor_kandang']}"),
                            Text("Nama Kandang: ${kandang['nama_kandang']}"),
                            Text("Lokasi Kandang: ${kandang['lokasi_kandang']}"),
                            Text("Kapasitas Kandang: ${kandang['kapasitas_kandang']}"),
                            Text("Ukuran Kandang: ${kandang['ukuran_kandang']}"),
                            Text("Kategori Kandang: ${kandang['kategori']}"),
                            FutureBuilder<String>(
                          future: _getUserName(kandang['ownerId'] ?? ''),
                          builder: (context, snapshot) {
                            return Text("Dimiliki oleh: ${snapshot.data ?? 'Belum Dimiliki'}");
                          },
                        ),
                          //  Text("Status: ${isOwned ? 'Dimiliki oleh ${kandang['ownerId']}' : 'Tidak dimiliki'}"),
                            Text("Status Kepemilikan: $statusDisplay"),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editKandang(kandang),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteKandang(kandang['nomor_kandang']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}