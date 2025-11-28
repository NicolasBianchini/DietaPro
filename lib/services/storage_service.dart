import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Faz upload de uma foto de perfil e retorna a URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Criar referência no Storage
      final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('profile_photos/$fileName');

      // Fazer upload
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Aguardar conclusão
      final TaskSnapshot snapshot = await uploadTask;

      // Obter URL de download
      final String downloadURL = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Foto enviada com sucesso: $downloadURL');
      return downloadURL;
    } catch (e) {
      debugPrint('❌ Erro ao fazer upload da foto: $e');
      throw Exception('Erro ao fazer upload da foto: $e');
    }
  }

  /// Deleta uma foto de perfil antiga
  Future<void> deleteProfilePhoto(String photoURL) async {
    try {
      // Extrair o path da URL
      final Uri uri = Uri.parse(photoURL);
      final String path = uri.pathSegments.last;

      // Deletar
      final Reference storageRef = _storage.ref().child('profile_photos/$path');
      await storageRef.delete();

      debugPrint('✅ Foto antiga deletada com sucesso');
    } catch (e) {
      debugPrint('⚠️ Erro ao deletar foto antiga: $e');
      // Não lançar exceção, apenas logar
    }
  }

  /// Atualiza foto de perfil (deleta antiga e faz upload da nova)
  Future<String> updateProfilePhoto({
    required String userId,
    required File imageFile,
    String? oldPhotoURL,
  }) async {
    try {
      // Fazer upload da nova foto
      final String newPhotoURL = await uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );

      // Deletar foto antiga se existir
      if (oldPhotoURL != null && oldPhotoURL.isNotEmpty) {
        await deleteProfilePhoto(oldPhotoURL);
      }

      return newPhotoURL;
    } catch (e) {
      throw Exception('Erro ao atualizar foto: $e');
    }
  }
}

