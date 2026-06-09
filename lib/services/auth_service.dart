import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // On web, clientId is needed. On Android, serverClientId is required to retrieve the idToken.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '837987113396-032hs7p88g0cnr0qpum1lodult1ihbah.apps.googleusercontent.com'
        : null,
    serverClientId: '837987113396-032hs7p88g0cnr0qpum1lodult1ihbah.apps.googleusercontent.com',
  );
  final FirestoreService _firestoreService = FirestoreService();

  // Sign up with additional data - creates email/password account and Firestore profile via linking
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String skillsHave,
    required String skillsWant,
    String? phone,
  }) async {
    try {
      // Create email/password credential
      final credential = EmailAuthProvider.credential(email: email, password: password);
      // Link with existing (phone) user if present
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
        await currentUser.updateDisplayName(name);
      } else {
        // No current user, fallback to creating a new email user
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        currentUser = result.user;
        if (currentUser != null) {
          await currentUser.updateDisplayName(name);
        }
      }

      if (currentUser != null) {
        UserModel newUser = UserModel(
          uid: currentUser.uid,
          name: name,
          email: email,
          bio: 'Hey there! I am using SkillMate to swap skills.',
          skillsHave: skillsHave,
          skillsWant: skillsWant,
          phone: phone,
        );
        await _firestoreService.createUserProfile(newUser);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign up.';
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // Link Email/Password to the current user
  Future<String?> linkEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String skillsHave,
    required String skillsWant,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        await currentUser.linkWithCredential(credential);
        await currentUser.updateDisplayName(name);

        UserModel newUser = UserModel(
          uid: currentUser.uid,
          name: name,
          email: email,
          bio: 'Hey there! I am using SkillMate to swap skills.',
          skillsHave: skillsHave,
          skillsWant: skillsWant,
          phone: currentUser.phoneNumber,
        );
        await _firestoreService.createUserProfile(newUser);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during linking.';
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // Login
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed.';
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On Web: use signInWithPopup for better UX
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // On Android/iOS: use google_sign_in package
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return "Sign in cancelled";

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      User? user = userCredential.user;

      if (user != null) {
        UserModel? existingUser = await _firestoreService.getUserProfile(user.uid);
        if (existingUser == null) {
          UserModel newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'SkillMate User',
            email: user.email ?? '',
            bio: 'Hey there! I am using SkillMate to swap skills.',
            skillsHave: 'Not specified yet',
            skillsWant: 'Not specified yet',
          );
          await _firestoreService.createUserProfile(newUser);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return "Sign in cancelled";
      }
      return e.message ?? 'Google Sign-In failed.';
    } catch (e, stack) {
      debugPrint("Google Sign-In Exception: $e");
      debugPrint("Stack trace: $stack");
      return "An unexpected error occurred during Google Sign-In: $e";
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // --- Phone Auth: Send OTP ---
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String message) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android — handled silently
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed("${e.code}: ${e.message ?? 'No additional details provided.'}");
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onVerificationFailed("Failed to send OTP: ${e.toString()}");
    }
  }

  // --- Phone Auth: Verify OTP ---
  Future<UserCredential?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Invalid OTP. Please try again.');
    } catch (e) {
      throw Exception("An unexpected error occurred during OTP verification.");
    }
  }

  // Auth state stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;
}
