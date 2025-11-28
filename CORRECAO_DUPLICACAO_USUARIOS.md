# 🔧 Correção: Duplicação de Usuários no Firestore

## ❌ Problema Identificado

Ao criar um usuário, estavam sendo criados **2 documentos** no Firestore:

### Documento 1 (Incompleto):
```javascript
{
  email: "nicolas@gmail.com",
  name: "Nicolas Tresoldi",
  passwordHash: "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c9a...",
  termsAccepted: true,
  termsAcceptedAt: "2025-11-28T15:07:37.548882"
}
```

### Documento 2 (Completo):
```javascript
{
  activityLevel: "sedentary",
  dateOfBirth: "2004-10-03T00:00:00.000",
  email: "nicolas@gmail.com",
  gender: "male",
  goal: "gainWeight",
  height: 177,
  id: "0I3irHV19u2swAW6mxZz",
  mealsPerDay: 3,
  name: "Nicolas Tresoldi",
  weight: 58
}
```

---

## 🔍 Causa do Problema

### Fluxo ANTIGO (com duplicação):

```
1. Registro → Salva perfil (Cria ID1)
2. Onboarding Step 1 → Salva novamente (Cria ID2) ❌
3. Onboarding Step 2 → Salva de novo (Usa ID2)
4. Onboarding Step 3 → Salva de novo (Usa ID2)
5. Onboarding Complete → Salva de novo (Usa ID2)

Resultado: 2 documentos (ID1 e ID2)
```

---

## ✅ Solução Implementada

### Fluxo NOVO (sem duplicação):

```
1. Registro → Salva perfil (Cria ID1)
2. Registro → Passa ID1 para Onboarding ✅
3. Onboarding Step 1 → Atualiza ID1 ✅
4. Onboarding Step 2 → Atualiza ID1 ✅
5. Onboarding Step 3 → Atualiza ID1 ✅
6. Onboarding Complete → Atualiza ID1 ✅

Resultado: 1 documento (ID1) com tudo!
```

---

## 🛠️ Mudanças no Código

### 1. `register_screen.dart`
```dart
// ANTES ❌
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => OnboardingWrapper(
      email: email,
      name: name,
      // ❌ Não passava o ID!
    ),
  ),
);

// DEPOIS ✅
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => OnboardingWrapper(
      email: email,
      name: name,
      userId: userId, // ✅ Passa o ID!
    ),
  ),
);
```

### 2. `onboarding_wrapper.dart`
```dart
// ANTES ❌
class OnboardingWrapper extends StatefulWidget {
  final String email;
  final String name;
  // ❌ Sem userId

// DEPOIS ✅  
class OnboardingWrapper extends StatefulWidget {
  final String email;
  final String name;
  final String? userId; // ✅ Recebe o ID

@override
void initState() {
  super.initState();
  _userProfile = UserProfile(
    id: widget.userId, // ✅ Usa o ID recebido
    email: widget.email,
    name: widget.name,
  );
}
```

### 3. `login_screen.dart`
```dart
// DEPOIS ✅
if (!userProfile.isComplete) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => OnboardingWrapper(
        email: email,
        name: userProfile.name,
        userId: userProfile.id, // ✅ Passa o ID também
      ),
    ),
  );
}
```

---

## 🧹 Limpar Usuários Duplicados

### Passo 1: Identificar Duplicatas

No Console do Firestore, identifique:

**Documento Completo** (tem todos os campos):
- ✅ activityLevel
- ✅ dateOfBirth
- ✅ gender
- ✅ goal
- ✅ height
- ✅ mealsPerDay
- ✅ weight
- ⚠️ **Falta** passwordHash

**Documento Incompleto** (tem senha):
- ✅ email
- ✅ name
- ✅ passwordHash
- ⚠️ **Falta** outros campos

### Passo 2: Mesclar os Documentos

Você tem 2 opções:

#### Opção A: Copiar passwordHash Manualmente

1. Abra o **documento incompleto** (tem passwordHash)
2. **Copie** o valor do campo `passwordHash`
3. Abra o **documento completo**
4. **Adicione** o campo `passwordHash` com o valor copiado
5. **Delete** o documento incompleto

#### Opção B: Deletar Tudo e Criar Novo

```
1. Delete AMBOS os documentos do usuário
2. Crie uma nova conta no app
3. ✅ Agora vai criar apenas 1 documento!
```

---

## 🧪 Testar a Correção

### Teste 1: Criar Nova Conta

```bash
flutter run

# Tela de Registro:
Nome: Teste Único
Email: unico@teste.com
Senha: teste123
[✓] Aceitar termos

# Completar Onboarding:
# Step 1, 2, 3, 4...

# Verificar no Firestore Console:
# ✅ Deve ter apenas 1 documento
# ✅ Documento deve ter passwordHash E todos os campos
```

### Teste 2: Verificar No Firestore

**Estrutura esperada:**
```javascript
users/
  └── {userId}/  ← APENAS 1 DOCUMENTO!
      ├── activityLevel: "sedentary"
      ├── dateOfBirth: "2004-10-03T00:00:00.000"
      ├── email: "usuario@teste.com"
      ├── gender: "male"
      ├── goal: "gainWeight"
      ├── height: 177
      ├── id: "{userId}"
      ├── mealsPerDay: 3
      ├── name: "Nome Usuário"
      ├── passwordHash: "abc123..." ← TEM SENHA
      ├── weight: 58
      ├── createdAt: Timestamp
      └── updatedAt: Timestamp
```

---

## 📊 Antes vs Depois

### Antes ❌
```
Firestore:
users/
  ├── ID1_incompleto/
  │   ├── email
  │   ├── name
  │   └── passwordHash
  └── ID2_completo/
      ├── email
      ├── name
      ├── activityLevel
      ├── gender
      └── ... (sem passwordHash!)
```

### Depois ✅
```
Firestore:
users/
  └── ID1_completo/
      ├── email
      ├── name
      ├── passwordHash     ← TEM!
      ├── activityLevel
      ├── gender
      ├── goal
      ├── height
      ├── weight
      └── ... (tudo junto!)
```

---

## 🔒 Segurança Mantida

- ✅ `passwordHash` continua sendo salvo
- ✅ Validação de senha funciona normalmente
- ✅ Apenas 1 documento por usuário
- ✅ Todos os dados no mesmo lugar

---

## 📝 Logs de Debug

O código agora mostra no console:

```bash
# Ao iniciar onboarding:
🎯 Onboarding iniciado com ID: bDBStySTDdwHYp6cpSSv

# Ao salvar cada step:
✅ Perfil atualizado: bDBStySTDdwHYp6cpSSv
```

Se o ID for o mesmo em todos os logs = ✅ Correto!

---

## 🆘 Problema Persistindo?

### Verificar se o ID está sendo passado:

```dart
// Em register_screen.dart:
print('🔑 ID criado no registro: $userId');

// Em onboarding_wrapper.dart:
print('🎯 ID recebido no onboarding: ${widget.userId}');

// Devem ser IGUAIS!
```

### Se ainda criar 2 documentos:

1. Execute `flutter clean`
2. Reinstale: `flutter pub get`
3. Rode novamente: `flutter run`
4. Verifique os logs do console

---

## ✅ Checklist

- [ ] Código atualizado em 3 arquivos
- [ ] Executei `flutter clean && flutter pub get`
- [ ] Deletei usuários antigos duplicados
- [ ] Criei nova conta de teste
- [ ] Verifiquei: apenas 1 documento criado
- [ ] Documento tem passwordHash E todos os campos
- [ ] Login funciona com a senha

---

**Data:** 28 de novembro de 2025  
**Versão:** 1.4  
**Status:** 🔧 Duplicação Corrigida ✅

