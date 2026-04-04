const admin = require('firebase-admin');

const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function updateAdminStatus() {
  const uid = process.argv[2];
  
  if (!uid) {
    console.error('Usage: node update-admin.js <uid>');
    process.exit(1);
  }
  
  try {
    await auth.setCustomUserClaims(uid, { role: 'admin' });
    console.log(`Set custom claims for user: ${uid}`);
    
    await db.collection('users').doc(uid).update({
      isAdmin: true,
      role: 'admin'
    });
    console.log(`Updated Firestore user document for: ${uid}`);
    
    console.log(`\n✅ Success! User ${uid} is now an admin.`);
    console.log(`\n⚠️ Important: The user must log out and log back in to refresh their JWT token.`);
  } catch (error) {
    console.error('Error updating admin status:', error);
  } finally {
    process.exit();
  }
}

updateAdminStatus();