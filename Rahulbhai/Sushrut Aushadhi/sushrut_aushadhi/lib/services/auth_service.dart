import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../core/utils/app_logger.dart';
import '../providers/firebase_providers.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function(UserCredential)? onVerificationCompleted,
    Function(String)? onTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            await getOrCreateUser(
              userCredential.user!.uid,
              userCredential.user!.phoneNumber ?? phoneNumber,
            );
          }
          onVerificationCompleted?.call(userCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout?.call(verificationId);
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserModel?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      final user = await getOrCreateUser(
        userCredential.user!.uid,
        userCredential.user!.phoneNumber ?? '',
      );
      
      // Set user context for Crashlytics
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      AppLogger.info("User logged in", tag: "Auth");
      
      return user;
    }
    return null;
  }

  Future<UserModel> getOrCreateUser(String uid, String phone) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc.data()!, uid);
    }

    final newUser = UserModel(
      uid: uid,
      name: '',
      phone: phone,
      createdAt: DateTime.now(),
    );

    await docRef.set(newUser.toMap());
    return newUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
