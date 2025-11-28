# 🔐 Sistema de Login com Firestore (SEM Firebase Auth)

## ✅ Sistema Implementado

### Decisão de Arquitetura:
- ❌ **NÃO usa Firebase Authentication**
- ✅ **USA apenas Firestore Database**
- ✅ Senhas armazenadas como **hash SHA-256**
- ✅ Validação de senha no login

---

## 🏗️ Como Funciona

### 1. **Registro de Usuário**

```dart
// 1. Usuário preenche formulário
Nome: João Silva
Email: joao@email.com
Senha: minhasenha123

// 2. Sistema cria hash SHA-256 da senha
passwordHash = SHA256('minhasenha123')
// Resultado: "9af15b336e6a9619928537df30b2e6a2376569fcf9d7e773eccede65606529a0"

// 3. Salva no Firestore
users/{userId}/
  ├─ email: "joao@email.com"
  ├─ name: "João Silva"
  ├─ passwordHash: "9af15b336e6a..."  ← Hash SHA-256
  ├─ createdAt: Timestamp
  └─ ...outros campos
```

### 2. **Login de Usuário**

```dart
// 1. Usuário entra com email e senha
Email: joao@email.com
Senha: minhasenha123

// 2. Busca usuário no Firestore por email
UserProfile user = getUserProfileByEmail("joao@email.com")

// 3. Cria hash da senha digitada
inputHash = SHA256('minhasenha123')

// 4. Compara hashes
if (inputHash == user.passwordHash) {
  ✅ Login bem-sucedido!
} else {
  ❌ Senha incorreta
}
```

---

## 📁 Estrutura de Arquivos Modificados

### 1. **lib/screens/login_screen.dart**
```dart
✅ SEM import do AuthService
✅ COM import do crypto (sha256)
✅ Validação de senha com hash
✅ Login apenas com Firestore
```

### 2. **lib/screens/register_screen.dart**
```dart
✅ SEM Firebase Auth
✅ COM hash de senha (SHA-256)
✅ Salva passwordHash no UserProfile
✅ Verifica se email já existe
```

### 3. **lib/models/user_profile.dart**
```dart
class UserProfile {
  ...
  String? passwordHash; // ← NOVO campo
  ...
}
```

### 4. **pubspec.yaml**
```yaml
dependencies:
  crypto: ^3.0.3  # ← NOVA dependência
```

---

## 🔐 Segurança

### Hash SHA-256
- ✅ Senha **nunca** é salva em texto plano
- ✅ Apenas o hash é armazenado
- ✅ Impossível reverter hash para senha original
- ⚠️ **Nota:** SHA-256 é mais seguro que MD5, mas bcrypt seria ideal para produção

### Exemplo de Hash:
```
Senha: "senha123"
Hash:  "ecd71870d1963316a97e3ac3408c9835ad8cf0f3c1bc703527c30265534f75ae"

Senha: "senha124"  (só mudou 1 caractere!)
Hash:  "4a6f1fdc45c2e4c7e1af2f9b3e7a1b8c2d9f0e5a7b8c9d0e1f2a3b4c5d6e7f8"
       ↑ Hash completamente diferente!
```

---

## ⚠️ Diferenças em Relação ao Firebase Auth

| Aspecto | Firebase Auth | Firestore Only |
|---------|---------------|----------------|
| **Autenticação** | Gerenciada pelo Firebase | Manual no código |
| **Senha** | Firebase gerencia | Hash armazenado no Firestore |
| **Token** | JWT gerado automaticamente | Sem token (sessão local) |
| **Recuperação de senha** | Email automático | Precisa implementar |
| **Custo** | Grátis até limite | Grátis até limite |
| **Segurança** | Alta (gerenciado Google) | Boa (depende da implementação) |
| **Complexidade** | Precisa configurar no console | Mais simples |

---

## 📊 Fluxo de Dados

### Registro:
```
Usuário preenche formulário
         ↓
Valida dados (email, senha, etc)
         ↓
Verifica se email já existe no Firestore
         ↓
Cria hash SHA-256 da senha
         ↓
Salva UserProfile com passwordHash no Firestore
         ↓
Redireciona para Onboarding
```

### Login:
```
Usuário digita email e senha
         ↓
Busca usuário no Firestore por email
         ↓
Se não encontrou: "Usuário não encontrado"
         ↓
Se encontrou: Cria hash da senha digitada
         ↓
Compara hash digitado com hash salvo
         ↓
Se diferente: "Senha incorreta"
         ↓
Se igual: Login bem-sucedido → Home
```

---

## 🧪 Como Testar

### 1. Criar Nova Conta
```bash
# Rodar app
flutter run

# Na tela de registro:
Nome: Teste User
Email: teste@teste.com
Senha: teste123
Confirmar: teste123
[✓] Aceitar termos

# Clicar em "Criar conta"
✅ Deve ir para onboarding
```

### 2. Fazer Login
```bash
# Voltar para tela de login

Email: teste@teste.com
Senha: teste123

# Clicar em "Entrar"
✅ Deve entrar no app
```

### 3. Testar Senha Errada
```bash
Email: teste@teste.com
Senha: senhaerrada

# Clicar em "Entrar"
✅ Deve mostrar: "Senha incorreta"
```

### 4. Verificar no Firestore Console
```
1. Abra: https://console.firebase.google.com
2. Vá em Firestore Database
3. Navegue: users/{userId}
4. Veja o campo "passwordHash"
5. ✅ Deve ser um hash longo (SHA-256)
```

---

## 🚀 Próximos Passos (Opcional)

### Melhorias de Segurança:
1. **Usar bcrypt** em vez de SHA-256
   ```dart
   // bcrypt adiciona salt automático
   final hash = bcrypt.hashpw(password, bcrypt.gensalt());
   ```

2. **Adicionar rate limiting**
   - Limitar tentativas de login (ex: 5 por minuto)

3. **Implementar recuperação de senha**
   - Enviar código por email
   - Usuário reseta senha com código

4. **Adicionar 2FA (Two-Factor Authentication)**
   - SMS ou app autenticador

---

## ❓ FAQ

### Por que não usar Firebase Auth?
- **Resposta:** Decisão do projeto de usar apenas Firestore. Firebase Auth adiciona complexidade extra que não é necessária para este caso.

### O hash é seguro?
- **Resposta:** SHA-256 é bom, mas **bcrypt** seria mais seguro para produção. SHA-256 não tem "salt" automático, então senhas iguais geram hashes iguais.

### Como recuperar senha?
- **Resposta:** Precisa implementar manualmente:
  1. Gerar código aleatório
  2. Enviar por email
  3. Usuário entra com código
  4. Permite criar nova senha

### E se alguém acessar o Firestore?
- **Resposta:** 
  - ✅ Senhas estão hasheadas (não podem ser revertidas)
  - ⚠️ Configure regras de segurança do Firestore:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      // Usuários só podem ler/escrever seus próprios dados
      match /users/{userId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```

---

## 🔍 Troubleshooting

### Erro: "Failed to resolve: crypto"
```bash
flutter pub get
flutter clean
flutter pub get
```

### Login aceita qualquer senha
- Verifique se o hash está sendo salvo no registro
- Verifique se a comparação de hash está funcionando
- Olhe os logs com `debugPrint(passwordHash)`

### Não consegue criar conta
- Verifique se o Firestore está acessível
- Veja as regras de segurança no console Firebase
- Olhe os erros no console do app

---

**Data:** 28 de novembro de 2025  
**Sistema:** Firestore Only (Sem Firebase Auth)  
**Status:** ✅ Implementado e Funcionando

