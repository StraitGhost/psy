import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<UserModel?> register(
      String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        id: result.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      return newUser;
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}