import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sobatternak_admin_web/pages/pemberitahuan/detail_laporanHewan.dart';

class PemberitahuanHewan extends StatefulWidget {
  @override
  _PemberitahuanHewanState createState() => _PemberitahuanHewanState();
}

class _PemberitahuanHewanState extends State<PemberitahuanHewan> with SingleTickerProviderStateMixin {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final List<NotificationCard> _pendingNotifications = [];
  final List<NotificationCard> _approvedNotifications = [];
  late StreamSubscription<DatabaseEvent> _notificationSubscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHewanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription.cancel();
    super.dispose();
  }

 void _fetchHewanData() async {
  try {
    DataSnapshot snapshot = await _database.child('hewan').get();
    if (snapshot.exists) {
      snapshot.children.forEach((child) {
        var hewanData = child.value as Map<dynamic, dynamic>;
        
        // Ambil data dengan status 'pending'
        if (hewanData['status'] == 'pending') {
          NotificationCard notificationCard = NotificationCard(
            key: ValueKey(child.key),
            nomor: _pendingNotifications.length + 1,
            tanggal: hewanData['tanggal_masuk'] ?? '',
            pengirim: hewanData['nomor_hewan'] ?? '',
            ownerId: hewanData['ownerId'] ?? '',
            kandangId: hewanData['kandangId'] ?? '',
            pesan: '${hewanData['nomor_hewan']} menunggu persetujuan',
            jenisHewan: hewanData['jenis_hewan'] ?? '',
            bobot: (hewanData['bobot'] ?? 0).toDouble(),
            namaPelapor: '',
            onEdit: () => _editNotification(child.key),
            onDelete: () => _deleteNotification(child.key),
            onApprove: () => _approveNotification(child.key, hewanData['ownerId']),
          );
          _pendingNotifications.add(notificationCard);
        }
        
        // Ambil data dengan status 'dimiliki'
        if (hewanData['status'] == 'dimiliki') {
          NotificationCard approvedNotificationCard = NotificationCard(
            key: ValueKey(child.key),
            nomor: _approvedNotifications.length + 1,
            tanggal: hewanData['tanggal_masuk'] ?? '',
            pengirim: hewanData['nomor_hewan'] ?? '',
            ownerId: hewanData['ownerId'] ?? '',
            kandangId: hewanData['kandangId'] ?? '',
            pesan: '${hewanData['nomor_hewan']} telah disetujui',
            jenisHewan: hewanData['jenis_hewan'] ?? '',
            bobot: (hewanData['bobot'] ?? 0).toDouble(),
            namaPelapor: '',
            onEdit: () => _editNotification(child.key),
            onDelete: () => _deleteNotification(child.key),
            onApprove: () {}, // Tidak perlu onApprove di sini
          );
          _approvedNotifications.add(approvedNotificationCard);
        }
      });
      setState(() {}); // Update UI setelah data diambil
    } else {
      print("Tidak ada data tersedia");
    }
  } catch (e) {
    print("Kesalahan mengambil data: $e");
  }
}

  Future<String> _getUserName(String userId) async {
    DataSnapshot snapshot = await _database.child('users').child(userId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData['name']?.toString() ?? 'Belum dimiliki';
    }
    return 'Belum dimiliki';
  }

  void _editNotification(String? key) {
    final user = FirebaseAuth.instance.currentUser  ;
    if (user != null) {
      if (user.email == 'admin1@gmail.com') {
        print('Edit notifikasi dengan key: $key');
      } else {
        print('User   tidak memiliki izin untuk mengedit notifikasi');
      }
    } else {
      print('Tidak ada pengguna yang terautentikasi');
    }
  }

  void _deleteNotification(String? key) {
    final user = FirebaseAuth.instance.currentUser  ;
    if (user != null) {
      if (user.email == 'admin1@gmail.com') {
        _database.child('Hewan').child(key!).remove().then((_) {
          setState(() {
            _pendingNotifications.removeWhere((notif) => notif.key == ValueKey(key));
          });
          print('Notifikasi dihapus dengan key: $key');
        }).catchError((error) {
          print('Error saat menghapus notifikasi: $error');
        });
      } else {
        print('User    tidak memiliki izin untuk menghapus notifikasi');
      }
    } else {
      print('Tidak ada pengguna yang terautentikasi');
    }
  }

  void _approveNotification(String? key, String pengirim) {
  final user = FirebaseAuth.instance.currentUser ;
  if (user != null) {
    if (user.email == 'admin1@gmail.com') {
      _database.child('hewan').child(key!).update({'status': 'dimiliki'}).then((_) {
        setState(() {
          final index = _pendingNotifications.indexWhere((notif) => notif.key == ValueKey(key));
          if (index != -1) {
            // Menambahkan notifikasi ke approvedNotifications
            NotificationCard approvedNotification = NotificationCard(
              key: ValueKey(key),
              nomor: _approvedNotifications.length + 1,
              tanggal: _pendingNotifications[index].tanggal,
              pengirim: _pendingNotifications[index].pengirim,
              ownerId: _pendingNotifications[index].ownerId,
              kandangId: _pendingNotifications[index].kandangId,
              pesan: '${_pendingNotifications[index].pengirim} telah disetujui',
              jenisHewan: _pendingNotifications[index].jenisHewan,
              bobot: _pendingNotifications[index].bobot,
              namaPelapor: '',
              onEdit: () => _editNotification(key),
              onDelete: () => _deleteNotification(key),
              onApprove: () {}, // Tidak perlu onApprove di sini
            );
            _approvedNotifications.add(approvedNotification);
            _pendingNotifications.removeAt(index);
          }
        });
        _sendApprovalNotification(pengirim, key);
      }).catchError((error) {
        print('Error saat menyetujui notifikasi: $error');
      });
    } else {
      print('User  tidak memiliki izin untuk menyetujui notifikasi');
    }
  } else {
    print('Tidak ada pengguna yang terautentikasi');
  }
}

  void _sendApprovalNotification(String ownerId, String key) {
    _database.child('users').child(ownerId).child('histori_pakan').child(key).update({
      'status': 'disetujui',
      'message': 'Hewan Anda telah disetujui',
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      print('Notifikasi persetujuan dikirim ke: $ownerId');
    }).catchError((error) {
      print('Error saat mengirim notifikasi persetujuan: $error');
    });
  }

  Widget _buildNotificationPage() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Tanggal Masuk')),
            DataColumn(label: Text('Nomor Hewan')),
            DataColumn(label: Text('Pemilik')),
            DataColumn(label: Text('Jenis Hewan')),
            DataColumn(label: Text('Bobot')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _pendingNotifications.isNotEmpty
              ? _pendingNotifications.map<DataRow>((notification) {
                  return DataRow(cells: <DataCell>[
                    DataCell(Text(notification.nomor.toString())),
                    DataCell(Text(notification.tanggal)),
                    DataCell(Text(notification.pengirim)),
                    DataCell(FutureBuilder<String>(
                      future: _getUserName(notification.ownerId), // Ambil nama pemilik
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Memuat...');
                        } else if (snapshot.hasError) {
                          return Text('Error');
                        } else {
                          return Text(snapshot.data ?? 'Tidak ada nama');
                        }
                      },
                    )),
                    DataCell(Text(notification.jenisHewan)),
                    DataCell(Text(notification.bobot.toString())),
                    DataCell(
                      GestureDetector(
                        onTap: () => _showDetailDialog(notification),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(184, 137, 220, 0.922),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info, color: Colors.white),
                              SizedBox(width: 5),
                              Text('Detail', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList()
              : [
                  DataRow(cells: [
                    DataCell(Text('Tidak ada notifikasi')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ]),
                ],
        ),
      ),
    );
  }

  void _showDetailDialog(NotificationCard notification) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Detail Laporan'),
        content: Container(
          width: 800,
          height: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailLaporanHewan(
                nomor: notification.nomor,
                tanggal: notification.tanggal,
                pengirim: notification.pengirim,
                pesan: notification.pesan,
                namaPelapor: '', hewanId: '', ownerId: notification.ownerId, kandangId: notification.kandangId,
              ),
              SizedBox(height: 16), // Jarak antara DetailLaporan dan nama pemilik
              FutureBuilder<String>(
                future: _getUserName(notification.ownerId), // Ambil nama pemilik
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Memuat nama pemilik...');
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Text('Pemilik: ${snapshot.data ?? 'Tidak ada nama'}');
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Tutup'),
          ),
        ],
      );
    },
  );
}

  Widget _buildApprovedPage() {
  return Container(
    padding: const EdgeInsets.all(8.0),
    child: SingleChildScrollView(
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Pengirim')),
          DataColumn(label: Text('Pesan')),
        ],
        rows: _approvedNotifications.map<DataRow>((notification) {
          return DataRow(cells: <DataCell>[
            DataCell(Text(notification.nomor.toString())),
            DataCell(Text(notification.tanggal)),
            DataCell(Text(notification.pengirim)),
            DataCell(Text(notification.pesan)),
          ]);
        }).toList(),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 224, 219, 219),
        title: Text('Pemberitahuan Hewan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 8),
                  Text('Informasi'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text('Approved'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildNotificationPage(),
          _buildApprovedPage(),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final int nomor;
  final String tanggal;
  final String pengirim;
  final String ownerId; // Tambahkan ownerId
  final String kandangId;
  final String pesan;
  final String jenisHewan;
  final double bobot;
  final String namaPelapor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;

  NotificationCard({
    required Key key,
    required this.nomor,
    required this.tanggal,
    required this.pengirim,
    required this.ownerId, // Tambahkan ownerId
    required this.kandangId,
    required this.pesan,
    required this.jenisHewan,
    required this.bobot,
    required this.namaPelapor,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No: $nomor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Tanggal: $tanggal'),
            SizedBox(height: 8),
            Text('Pengirim: $pengirim'),
            SizedBox(height: 8),
            Text('Pemilik: $ownerId'), // Tampilkan ownerId
            SizedBox(height: 8),
            Text('Pesan: $pesan'),
            SizedBox(height: 8),
            Text('Jenis Hewan: $jenisHewan'),
            SizedBox(height: 8),
            Text('Bobot: $bobot'),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: onEdit,
                  child: Text('Edit'),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text('Delete'),
                ),
                TextButton(
                  onPressed: onApprove,
                  child: Text('Setujui'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}