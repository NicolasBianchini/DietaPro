import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // Getter para o usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream de mudanças de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Faz login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Nenhum usuário encontrado com este email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Senha incorreta.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Esta conta foi desabilitada.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Muitas tentativas. Tente novamente mais tarde.');
      } else {
        throw Exception('Erro ao fazer login: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Cria uma nova conta com email e senha
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualizar o nome do usuário no Firebase Auth
      await userCredential.user?.updateDisplayName(name);

      // Criar perfil inicial no Firestore
      final userProfile = UserProfile(
        id: userCredential.user?.uid,
        email: email.trim(),
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore.saveUserProfile(userProfile);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('A senha é muito fraca.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Este email já está em uso.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido.');
      } else {
        throw Exception('Erro ao criar conta: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao criar conta: $e');
    }
  }

  /// Faz logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Envia email de recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Nenhum usuário encontrado com este email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email inválido.');
      } else {
        throw Exception('Erro ao enviar email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar email de recuperação: $e');
    }
  }

  /// Busca o perfil do usuário atual
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await _firestore.getUserProfile(user.uid);
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Verifica se o email já está em uso
  Future<bool> isEmailAlreadyRegistered(String email) async {
    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
      return signInMethods.isNotEmpty;
    } catch (e) {
      // Se houver erro, assumimos que não está registrado
      return false;
    }
  }

  /// Atualiza a senha do usuário
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Reautenticar o usuário
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Atualizar a senha
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Senha atual incorreta.');
      } else if (e.code == 'weak-password') {
        throw Exception('A nova senha é muito fraca.');
      } else {
        throw Exception('Erro ao atualizar senha: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar senha: $e');
    }
  }
}

