import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sobatternak_admin_web/pages/User/Detail_User.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> userDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print('UserPage diinisialisasi');
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      print('Pengguna tidak terautentikasi');
      return;
    }

    DatabaseReference usersRef = _database.ref().child("users");
    try {
      DataSnapshot snapshot = await usersRef.get();
      if (snapshot.exists) {
        print('Snapshot exists');
        Map<String, dynamic> usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> tempList = [];

        for (var entry in usersMap.entries) {
          String uid = entry.key;
          Map<String, dynamic> userData = Map<String, dynamic>.from(entry.value);
          bool hasKandang = userData.containsKey('kandangs') && (userData['kandangs'] as Map).isNotEmpty;

          tempList.add({
            "uid": uid,
            "name": userData['name'] ?? '',
            "email": userData['email'] ?? '',
            "hasKandang": hasKandang,
          });
        }

        setState(() {
          userDataList = tempList.reversed.toList();
          isLoading = false;
        });
        print('Data Pengguna berhasil diambil: $userDataList');
      } else {
        setState(() {
          isLoading = false;
        });
        print('Tidak ada data pengguna yang ditemukan');
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 224, 219, 219),
        title: Text("Data Pengguna"),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : userDataList.isEmpty
                ? Text("No data available")
                : ListView.builder(
                    itemCount: userDataList.length,
                    itemBuilder: (context, index) {
                      print('Menampilkan data pengguna: ${userDataList[index]}');
                      return buildUserCard(userDataList[index], index);
                    },
                  ),
      ),
    );
  }

  Widget buildUserCard(Map<String, dynamic> userData, int index) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ID Pengguna: ${userData['uid']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Nama: ${userData['name']}'),
                SizedBox(height: 8),
                Text('Email: ${userData['email']}'),
                SizedBox(height: 8),
                Text(
                  'Status Kandang: ${userData['hasKandang'] ? 'Sudah memiliki kandang' : 'Belum memiliki kandang'}',
                  style: TextStyle(
                    color: userData['hasKandang'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailUserPage(userData: userData),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}