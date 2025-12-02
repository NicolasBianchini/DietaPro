import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Detecta a extensão e contentType do arquivo de imagem
  Map<String, String> _getImageMetadata(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return {'ext': 'jpg', 'contentType': 'image/jpeg'};
      case 'png':
        return {'ext': 'png', 'contentType': 'image/png'};
      case 'heic':
        return {'ext': 'heic', 'contentType': 'image/heic'};
      case 'heif':
        return {'ext': 'heif', 'contentType': 'image/heif'};
      case 'webp':
        return {'ext': 'webp', 'contentType': 'image/webp'};
      default:
        // Por padrão, usa jpg
        return {'ext': 'jpg', 'contentType': 'image/jpeg'};
    }
  }

  /// Faz upload de uma foto de perfil e retorna a URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      debugPrint('📤 Iniciando upload da foto para userId: $userId');

      // Detectar formato da imagem
      final metadata = _getImageMetadata(imageFile.path);
      final extension = metadata['ext']!;
      final contentType = metadata['contentType']!;
      
      debugPrint('🖼️ Formato detectado: $extension (contentType: $contentType)');

      // Criar referência no Storage usando o userId do Firestore
      final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final Reference storageRef = _storage.ref().child('profile_photos/$fileName');
      
      debugPrint('📁 Caminho do arquivo: profile_photos/$fileName');
      
      // Verificar tamanho do arquivo (máximo 5MB)
      final fileSize = await imageFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        throw Exception('A foto é muito grande. Tamanho máximo: 5MB');
      }
      
      debugPrint('📏 Tamanho do arquivo: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Fazer upload
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFormat': extension,
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

