const admin = require('firebase-admin');

// Initialize Firebase Admin
// You need to download service account key from Firebase Console
// Project Settings > Service Accounts > Generate new private key
const serviceAccount = require('./service-account.json'); // Place your service account file here

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateAdminStatus() {
  const uid = process.argv[2];
  
  if (!uid) {
    console.error('Usage: node update-admin.js <uid>');
    process.exit(1);
  }
  
  try {
    await db.collection('users').doc(uid).update({
      isAdmin: true
    });
    console.log(`Successfully updated admin status for user: ${uid}`);
  } catch (error) {
    console.error('Error updating admin status:', error);
  } finally {
    process.exit();
  }
}

updateAdminStatus();