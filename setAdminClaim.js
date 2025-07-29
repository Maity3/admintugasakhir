// setAdminClaim.js
const admin = require('firebase-admin');

// Inisialisasi Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(require('./config/st-akhir-firebase-adminsdk-n5lbh-e301789191.json')), // Jalur yang benar
  databaseURL: "https://st-akhir-default-rtdb.firebaseio.com"
});

// UID pengguna yang ingin Anda jadikan admin
const uid = 'hjEuY0divWhfZQ4PVvgNaLGoRr83'; // Ganti dengan UID pengguna yang relevan

// Menambahkan klaim admin ke pengguna
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('Klaim admin berhasil ditambahkan');
  })
  .catch(error => {
    console.log('Error menambahkan klaim admin:', error);
  });