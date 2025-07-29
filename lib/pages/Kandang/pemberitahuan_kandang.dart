import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sobatternak_admin_web/pages/pemberitahuan/detail_laporanHewan.dart';
import 'package:sobatternak_admin_web/pages/pemberitahuan/detail_laporanKandang.dart';

class pemberitahuanKandang extends StatefulWidget {
  @override
  _pemberitahuanKandangState createState() => _pemberitahuanKandangState();
}

class _pemberitahuanKandangState extends State<pemberitahuanKandang>
    with SingleTickerProviderStateMixin {
  final _database = FirebaseDatabase.instance.reference();
  final List<NotificationCard> _pendingNotifications = [];
  final List<NotificationCard> _approvedNotifications = [];
  late StreamSubscription<DatabaseEvent> _notificationSubscription;
  late TabController _tabController;
  String? _selectedAction;
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenForNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription.cancel();
    super.dispose();
  }

  void _listenForNotifications() async {
  try {
    DataSnapshot snapshot = await _database.child('kandang').get();
    if (snapshot.exists) {
      snapshot.children.forEach((child) {
        var kandangData = child.value as Map<dynamic, dynamic>;
        
        // Ambil data dengan status 'pending'
        if (kandangData['status'] == 'pending') {
          NotificationCard notificationCard = NotificationCard(
            key: ValueKey(child.key),
            nomor: _pendingNotifications.length + 1,
            tanggal: kandangData['tanggal_masuk'] ?? '',
            pengirim: kandangData['nama_kandang'] ?? '',
            ownerId: kandangData['ownerId'] ?? '',
            kandangId: kandangData['nomor_kandang'] ?? '',
            pesan: '${kandangData['nama_kandang']} menunggu persetujuan',

            onEdit: () => _editNotification(child.key),
            onDelete: () => _deleteNotification(child.key),
            onApprove: () => _approveNotification(child.key, kandangData['ownerId']), onReject: () {  },
          );
          _pendingNotifications.add(notificationCard);
        }
        
        // Ambil data dengan status 'dimiliki'
        if (kandangData['status'] == 'dimiliki') {
          NotificationCard approvedNotificationCard = NotificationCard(
            key: ValueKey(child.key),
            nomor: _approvedNotifications.length + 1,
            tanggal: kandangData['tanggal_masuk'] ?? '',
            pengirim: kandangData['nama_kandang'] ?? '',
            ownerId: kandangData['ownerId'] ?? '',
            kandangId: kandangData['nomor_kandang'] ?? '',
            pesan: '${kandangData['nama_kandang']} telah disetujui',
            onEdit: () => _editNotification(child.key),
            onDelete: () => _deleteNotification(child.key),
            onApprove: () {}, onReject: () {  }, // Tidak perlu onApprove di sini
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


  void _editNotification(String? key) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Email pengguna saat ini: ${user.email}');
      if (user.email == 'admin1@gmail.com') {
        print('Edit notifikasi dengan key: $key');
      } else {
        print('User  tidak memiliki izin untuk mengedit notifikasi');
      }
    } else {
      print('Tidak ada pengguna yang terautentikasi');
    }
  }

  void _deleteNotification(String? key) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Email pengguna saat ini: ${user.email}');
      if (user.email == 'admin1@gmail.com') {
        print('User  terautentikasi: ${user.uid}');
        _database.child('kandang').child(key!).remove().then((_) {
          setState(() {
            _pendingNotifications
                .removeWhere((notif) => notif.key == ValueKey(key));
          });
          print('Notifikasi dihapus dengan key: $key');
        }).catchError((error) {
          print('Error saat menghapus notifikasi: $error');
        });
      } else {
        print('User  tidak memiliki izin untuk menghapus notifikasi');
      }
    } else {
      print('Tidak ada pengguna yang terautentikasi');
    }
  }

  void _rejectNotification(String? key, String pengirim) {
  final user = FirebaseAuth.instance.currentUser ;
  if (user != null) {
    print('Email pengguna saat ini: ${user.email}');
    if (user.email == 'admin1@gmail.com') {
      print('Notifikasi ditolak dengan key: $key');
      _database.child('kandang').child(key!).remove().then((_) {
        setState(() {
          _pendingNotifications.removeWhere((notif) => notif.key == ValueKey(key));
        });
        _removeKandangFromUser (pengirim, key);
      }).catchError((error) {
        print('Error saat menolak notifikasi: $error');
      });
    } else {
      print('User  tidak memiliki izin untuk menolak notifikasi');
    }
  } else {
    print('Tidak ada pengguna yang terautentikasi');
  }
}

void _removeKandangFromUser (String pengirim, String key) {
  print('Menghapus kandang dari pengguna: $pengirim dengan key: $key');
  _database.child('users').child(pengirim).child('kandangs').child(key).remove().then((_) {
    print('Kandang berhasil dihapus dari pengguna: $pengirim');
  }).catchError((error) {
    print('Error saat menghapus kandang dari pengguna: $error');
  });
}

  void _approveNotification(String? key, String pengirim) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Email pengguna saat ini: ${user.email}');
      if (user.email == 'admin1@gmail.com') {
        print('Not ifikasi disetujui dengan key: $key');
        _database
            .child('kandang')
            .child(key!)
            .update({'status': 'approved'}).then((_) {
          setState(() {
            // Move notification from pending to approved
            final index = _pendingNotifications.indexWhere((notif) => notif.key == ValueKey(key));
            if (index != -1) {
              NotificationCard approvedNotification = NotificationCard(
                key: ValueKey(key), 
                nomor: _approvedNotifications.length + 1, 
                tanggal: _pendingNotifications[index].tanggal, 
                pengirim: _pendingNotifications[index].pengirim, 
                pesan: _pendingNotifications[index].pesan, 
                kandangId: _pendingNotifications[index].kandangId, 
                ownerId: _pendingNotifications[index].ownerId, 
                onEdit: () => _editNotification(key), 
                onDelete: () => _deleteNotification(key), 
                onApprove: () {}, 
                onReject: () {}
                );
              _approvedNotifications.add(_pendingNotifications[index]);
              _pendingNotifications.removeAt(index);
            }
          });
          _sendApprovalNotification(pengirim, key);
        }).catchError((error) {
          print('Error saat menyetujui notifikasi: $error');
        });
      } else {
        print('User   tidak memiliki izin untuk menyetujui notifikasi');
      }
    } else {
      print('Tidak ada pengguna yang terautentikasi');
    }
  }

  void _sendApprovalNotification(String ownerId, String key) {
    print('Mengirim notifikasi persetujuan ke user: $ownerId dengan key: $key');
    _database
        .child('users')
        .child(ownerId)
        .child('fcm_token')
        .child(key)
        .update({
      'status': 'disetujui',
      'message': 'Kandang Anda telah disetujui',
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
            DataColumn(label: Text('Id')),
            DataColumn(label: Text('Pengirim')),
            DataColumn(label: Text('Pesan')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _pendingNotifications.isNotEmpty
              ? _pendingNotifications.map<DataRow>((notification) {
                  return DataRow(cells: <DataCell>[
                    DataCell(Text(notification.nomor.toString())),
                    DataCell(Text(notification.kandangId)),
                    DataCell(Text(notification.pengirim)),
                    DataCell(Text(notification.pesan)),
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
                              Text(
                                'Detail',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList()
              : [],
        ),
      ),
    );
  }

  void _showDetailDialog(NotificationCard notification) {
    // Tampilkan dialog dengan konten DetailLaporan
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Laporan'),
          content: Container(
            width: 800, // Atur lebar maksimum dialog
            height: 800, // Atur tinggi maksimum dialog
            child: DetailLaporanKandang(
              nomor: notification.nomor,
              tanggal: notification.tanggal,
              pengirim: notification.pengirim,
              namaPelapor: '',
              pesan: notification.pesan,
              ownerId: notification.ownerId,
              kandangId: notification.kandangId,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
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
        title: Text('Pemberitahuan Kandang'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, size: 20), // Ikon untuk Informasi
                  SizedBox(width: 8), // Jarak antara ikon dan teks
                  Text('Informasi'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20), // Ikon untuk Approved
                  SizedBox(width: 8), // Jarak antara ikon dan teks
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
  final String pesan;
  final String kandangId;
  final VoidCallback onEdit;
  final String ownerId;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  NotificationCard({
    required Key key,
    required this.nomor,
    required this.tanggal,
    required this.pengirim,
    required this.pesan,
    required this.kandangId,
    required this.ownerId,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
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
            Text('Pesan: $pesan'),
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
                TextButton(
                  onPressed: onReject, // Tambahkan fungsi onReject
                  child: Text('Tolak'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
