import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/logger/app_logger.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signUpWithEmail(String email, String password);
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data);
}

class AuthServiceImpl implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppLogger _logger;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthServiceImpl(this._auth, this._firestore, this._logger);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      _logger.warning('Sign in failed: ${e.code}');
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nickname': user.email!.split('@')[0].toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
        'bio': '',
      });
      await user.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      _logger.warning('Sign up failed: ${e.code}');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nickname': user.email!.split('@')[0].toLowerCase(),
        'photoUrl': user.photoURL ?? '',
        'bio': '',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return user;
    } catch (e, stack) {
      await _logger.error('Google sign in failed', error: e, stack: stack);
      return null;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}