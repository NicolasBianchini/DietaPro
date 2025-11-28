# 📸 Funcionalidade: Foto de Perfil

## ✅ O que foi implementado?

Agora os usuários podem adicionar, trocar e remover foto de perfil no app!

---

## 🎯 Funcionalidades

### 1. **Adicionar Foto**
- Tirar foto com a câmera 📷
- Escolher da galeria 🖼️
- Upload automático para Firebase Storage
- Atualiza perfil no Firestore

### 2. **Trocar Foto**
- Deleta foto antiga automaticamente
- Upload da nova foto
- Perfil atualizado instantaneamente

### 3. **Remover Foto**
- Remove foto do Storage
- Volta para avatar com iniciais
- Dados salvos no Firestore

---

## 🏗️ Arquitetura

### Firebase Storage
```
profile_photos/
  ├── profile_{userId}_{timestamp}.jpg
  ├── profile_{userId}_{timestamp}.jpg
  └── ...
```

### Firestore
```javascript
users/{userId}/
  ├── email: "usuario@email.com"
  ├── name: "Nome"
  ├── photoURL: "https://firebasestorage.../profile_123.jpg"  ← NOVO!
  └── ...outros campos
```

---

## 📁 Arquivos Criados/Modificados

### Novos Arquivos:
1. ✅ `lib/services/storage_service.dart`
   - `uploadProfilePhoto()` - Upload de foto
   - `deleteProfilePhoto()` - Delete foto antiga
   - `updateProfilePhoto()` - Atualiza foto (delete + upload)

### Arquivos Modificados:
2. ✅ `lib/models/user_profile.dart`
   - Adicionado campo `photoURL`

3. ✅ `lib/screens/home_screen.dart`
   - Avatar agora mostra foto
   - Botão de câmera no avatar
   - `_showPhotoOptions()` - Modal com opções
   - `_pickImage()` - Seleciona e faz upload
   - `_removePhoto()` - Remove foto

4. ✅ `ios/Runner/Info.plist`
   - Permissões de câmera
   - Permissões de galeria

5. ✅ `pubspec.yaml`
   - `image_picker` - Selecionar fotos
   - `firebase_storage` - Armazenar fotos
   - `path_provider` - Cache local

---

## 🎨 Interface

### Avatar com Foto:
```
┌─────────────┐
│   [FOTO]    │  ← Mostra foto se existir
│             │
│      📷     │  ← Botão câmera (canto inferior direito)
└─────────────┘
```

### Avatar sem Foto:
```
┌─────────────┐
│             │
│     NT      │  ← Iniciais do nome
│             │
│      📷     │  ← Botão câmera
└─────────────┘
```

### Modal de Opções:
```
─────────────────────
  Foto de Perfil
─────────────────────
📷  Tirar Foto
🖼️  Escolher da Galeria
🗑️  Remover Foto (se tem foto)
─────────────────────
```

---

## 🔐 Segurança

### Regras do Firebase Storage

Adicione essas regras no Firebase Console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Fotos de perfil
    match /profile_photos/{fileName} {
      // Permitir leitura para todos (fotos públicas)
      allow read: if true;
      
      // Permitir escrita apenas para o próprio usuário
      // NOTA: Como não estamos usando Firebase Auth, 
      // temporariamente permitir escrita para todos
      allow write: if true;
      
      // EM PRODUÇÃO: Implementar autenticação adequada
      // allow write: if request.auth != null 
      //   && request.auth.uid == getUserIdFromFileName(fileName);
    }
  }
}
```

**⚠️ Atenção:** As regras acima são permissivas para desenvolvimento. Em produção, implemente validação adequada!

---

## 📱 Como Usar

### 1. **Adicionar Foto (Primeira Vez)**

```
1. Abra o app
2. Vá para aba "Perfil" (👤)
3. Toque no ícone de câmera (📷) no avatar
4. Escolha:
   - "Tirar Foto" → Abre câmera
   - "Escolher da Galeria" → Abre galeria
5. Selecione/Tire a foto
6. ✅ Foto é enviada automaticamente!
7. Avatar atualiza com a foto
```

### 2. **Trocar Foto**

```
1. Toque no ícone de câmera (📷)
2. Escolha nova fonte (câmera ou galeria)
3. ✅ Foto antiga é deletada
4. ✅ Nova foto é enviada
5. Avatar atualiza
```

### 3. **Remover Foto**

```
1. Toque no ícone de câmera (📷)
2. Toque em "Remover Foto" 🗑️
3. ✅ Foto é deletada do Storage
4. Avatar volta para mostrar iniciais
```

---

## 🧪 Testar a Funcionalidade

### Teste 1: Adicionar Foto da Galeria
```bash
flutter run

# No app:
1. Vá para aba Perfil
2. Toque no botão de câmera
3. Escolha "Escolher da Galeria"
4. Selecione uma foto
5. ✅ Foto deve aparecer no avatar
```

### Teste 2: Tirar Foto com Câmera
```bash
# No dispositivo físico (não funciona no simulador):
1. Toque no botão de câmera
2. Escolha "Tirar Foto"
3. Tire uma foto
4. ✅ Foto deve aparecer no avatar
```

### Teste 3: Verificar no Firebase
```
1. Abra: https://console.firebase.google.com
2. Vá em Storage
3. ✅ Deve ver pasta "profile_photos/"
4. ✅ Deve ter arquivo profile_{userId}_{timestamp}.jpg
5. Clique na foto → "Get download URL"
6. Cole URL no navegador
7. ✅ Deve abrir a foto
```

### Teste 4: Remover Foto
```bash
1. Com foto já adicionada
2. Toque no botão de câmera
3. Toque em "Remover Foto"
4. ✅ Avatar volta para iniciais
5. ✅ No Firebase Storage, foto deve ser deletada
```

---

## 📊 Fluxo de Upload

```
Usuário escolhe foto
         ↓
ImagePicker abre câmera/galeria
         ↓
Usuário seleciona foto
         ↓
Loading aparece
         ↓
StorageService.updateProfilePhoto()
    ├─ Upload nova foto para Storage
    ├─ Recebe URL de download
    └─ Delete foto antiga (se existir)
         ↓
Atualiza UserProfile.photoURL no Firestore
         ↓
Loading fecha
         ↓
Tela recarrega com nova foto
         ↓
✅ Snackbar: "Foto atualizada!"
```

---

## 🔧 Configuração do Firebase Storage

### Passo 1: Habilitar Storage

1. **Console Firebase:** https://console.firebase.google.com
2. **Storage** (menu lateral)
3. **Get Started** ou **Iniciar**
4. **Escolher modo:**
   - Produção (com regras)
   - Teste (sem regras - mais fácil para dev)
5. **Selecionar região:** us-central (ou sua preferência)
6. **Concluir**

### Passo 2: Configurar Regras

```javascript
// Modo Desenvolvimento (permissivo):
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Só para desenvolvimento!**

### Passo 3: Verificar

```
1. Storage > Files
2. Deve estar vazio (por enquanto)
3. Aguardar primeiro upload do app
```

---

## 💡 Otimizações Implementadas

### 1. **Compressão de Imagem**
```dart
maxWidth: 800,
maxHeight: 800,
imageQuality: 85,
```
- Reduz tamanho do arquivo
- Upload mais rápido
- Menos uso de Storage

### 2. **Delete Automático**
```dart
// Ao trocar foto, antiga é deletada
await _storageService.updateProfilePhoto(
  userId: userId,
  imageFile: newImage,
  oldPhotoURL: oldURL, // ← Deleta esta
);
```

### 3. **Loading Indicator**
```dart
// Mostra loading durante upload
showDialog(...CircularProgressIndicator...);
```

### 4. **Error Handling**
```dart
try {
  // Upload
} catch (e) {
  // Mostra erro ao usuário
  ScaffoldMessenger.showSnackBar(...);
}
```

---

## ⚠️ Problemas Comuns

### "Permissão negada" ao abrir câmera

**Solução:**
1. iOS: Verificar `Info.plist` tem as permissões
2. Desinstalar e reinstalar o app
3. Ir em Ajustes do iPhone → DietaPro → Permitir acesso

### Foto não aparece após upload

**Verificar:**
1. Firebase Storage está habilitado?
2. Regras do Storage permitem leitura?
3. URL foi salva no Firestore?
4. Console do app mostra erros?

### Upload muito lento

**Otimizar:**
1. Reduzir `imageQuality` (ex: 70)
2. Reduzir `maxWidth/maxHeight` (ex: 600)
3. Verificar conexão de internet

---

## 🚀 Próximos Passos (Opcional)

### Melhorias Futuras:
1. **Crop/Edição** de foto antes do upload
2. **Múltiplos tamanhos** (thumbnail, medium, full)
3. **Filtros** de foto
4. **Detecção de rosto** para centralizar
5. **Avatar padrão** customizado por gênero
6. **Galeria de avatares** pré-definidos

---

## ✅ Checklist de Implementação

- [x] Adicionar dependências ao `pubspec.yaml`
- [x] Criar `StorageService`
- [x] Adicionar campo `photoURL` no `UserProfile`
- [x] Adicionar permissões no `Info.plist`
- [x] Modificar avatar no `home_screen.dart`
- [x] Implementar `_showPhotoOptions()`
- [x] Implementar `_pickImage()`
- [x] Implementar `_removePhoto()`
- [x] Habilitar Firebase Storage no console
- [x] Configurar regras do Storage
- [ ] Testar no dispositivo físico
- [ ] Testar upload de foto
- [ ] Testar remoção de foto

---

**Data:** 28 de novembro de 2025  
**Versão:** 1.5  
**Status:** 📸 Foto de Perfil Implementada ✅

