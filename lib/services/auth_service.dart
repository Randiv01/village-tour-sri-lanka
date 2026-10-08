import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user ID
  String? get currentUid => _auth.currentUser?.uid;

  // Sign In with Email & Password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // TEMPORARY FIX: Automatically create/repair the admin's Firestore profile 
      // if they log in with the admin email.
      if (email.trim().toLowerCase() == 'admin@villagetour.com') {
        final docRef = _firestore.collection('users').doc(cred.user!.uid);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          await docRef.set({
            'uid': cred.user!.uid,
            'email': email.trim().toLowerCase(),
            'fullName': 'System Admin',
            'phoneNumber': '',
            'role': 'admin',
            'isActive': true,
            'isEmailVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final user = await getUserProfile(cred.user!.uid);
      
      if (user == null) {
        // Fallback for missing profile
        await _auth.signOut();
        throw 'No profile found for this account. Please contact support.';
      }
      
      if (!user.isActive) {
        await _auth.signOut();
        throw 'Your account has been deactivated. Please contact support.';
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign Up with Email & Password
  Future<UserModel?> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async {
    UserCredential? cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = UserModel(
        uid: cred.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        isActive: true,
        isEmailVerified: cred.user!.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toMap());
      } catch (e) {
        // If Firestore creation fails, clean up the created Firebase Auth user
        await cred.user?.delete();
        throw 'Unable to complete registration. Please try again.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        throw 'Sign in with Google was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'An unexpected error occurred during Google Sign In.';
    }
  }

  // Phone Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      throw 'Failed to start phone verification. Please try again.';
    }
  }

  Future<UserCredential> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Failed to verify OTP. Please try again.';
    }
  }

  // Create User Profile directly (used after Google/Phone sign in for new users)
  Future<UserModel> createUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    String? profileImageUrl,
    String? authProvider,
  }) async {
    final user = UserModel(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      role: role,
      isActive: true,
      profileImageUrl: profileImageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set({
      ...user.toMap(),
      'authProvider': authProvider,
    });
    return user;
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to load user profile.';
    }
  }

  // Update User Profile
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null || currentUid != uid) {
        throw 'Unauthorized: You can only update your own profile.';
      }

      // Prevent updating immutable fields
      data.remove('uid');
      data.remove('role');
      data.remove('isVerified');
      data.remove('isEmailVerified');

      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(data);

      if (data.containsKey('fullName') && data['fullName'] is String) {
        await _auth.currentUser?.updateDisplayName(data['fullName'] as String);
      }
      if (data.containsKey('profileImageUrl') && data['profileImageUrl'] is String) {
        await _auth.currentUser?.updatePhotoURL(data['profileImageUrl'] as String);
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account was found with these credentials.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Please sign in using your existing sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Unable to connect. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'invalid-verification-code':
        return 'The SMS verification code is invalid.';
      default:
        return 'Error [${e.code}]: ${e.message}';
    }
  }
}
