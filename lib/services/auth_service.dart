import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '837987113396-032hs7p88g0cnr0qpum1lodult1ihbah.apps.googleusercontent.com',
  );
  final FirestoreService _firestoreService = FirestoreService();

  // Signup with additional data - creates email/password account and Firestore profile
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String skillsHave,
    required String skillsWant,
    String? phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);

        UserModel newUser = UserModel(
          uid: user.uid,
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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Sign in cancelled";

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
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
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      return e.message ?? 'Google Sign-In failed.';
    } catch (e, stack) {
      print("Google Sign-In Exception: $e");
      print("Stack trace: $stack");
      return "An unexpected error occurred during Google Sign-In: $e";
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
