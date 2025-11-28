# 🚨 Solução: Erro CONFIGURATION_NOT_FOUND - Firebase Auth

## ❌ Erro Atual

```
Error Domain=FIRAuthErrorDomain Code=17999
'An internal error has occurred'
message = 'CONFIGURATION_NOT_FOUND'
code = 400
```

## 🔍 Causa do Erro

O **Firebase Authentication não está habilitado** no Console do Firebase para o projeto `dietapro-f1b95`.

---

## ✅ SOLUÇÃO (Passo a Passo)

### 1️⃣ Acesse o Console do Firebase

Abra o navegador e vá para:
```
https://console.firebase.google.com
```

### 2️⃣ Selecione o Projeto

- Clique no projeto: **dietapro-f1b95**

### 3️⃣ Vá para Authentication

- No menu lateral esquerdo
- Clique em **"Build"** (Compilar)
- Clique em **"Authentication"**

### 4️⃣ Inicie o Authentication (se aparecer)

Se aparecer uma tela de boas-vindas:
- Clique no botão **"Get Started"** ou **"Começar"**

### 5️⃣ Habilite Email/Password

1. Clique na aba **"Sign-in method"** (Método de login)
2. Procure por **"Email/Password"** (Email/Senha) na lista
3. Clique nele para editar
4. **IMPORTANTE:** Ative os dois toggles:
   - ✅ **Enable** (Ativar) - LIGA
   - ❌ **Email link (passwordless sign-in)** - DEIXA DESLIGADO
5. Clique em **"Save"** (Salvar)

### 6️⃣ Limpe e Recompile o App

No terminal:

```bash
# 1. Pare o app se estiver rodando
# Pressione Ctrl+C no terminal

# 2. Limpe o cache
flutter clean

# 3. Reinstale dependências
flutter pub get

# 4. (iOS) Reinstale pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# 5. Rode novamente
flutter run
```

---

## 📸 Visual do Console Firebase

### Como deve ficar após habilitar:

**Authentication > Sign-in method**

| Provider | Status |
|----------|--------|
| Email/Password | ✅ **Enabled** |
| Google | Disabled |
| Facebook | Disabled |
| Apple | Disabled |

---

## 🧪 Teste Após Configurar

### 1. Criar uma Conta Nova

1. Abra o app
2. Clique em "Criar nova conta"
3. Preencha:
   - Nome: Teste
   - Email: teste@teste.com
   - Senha: teste123
4. ✅ Deve criar a conta com sucesso

### 2. Fazer Login

1. Tela de login
2. Email: teste@teste.com
3. Senha: teste123
4. ✅ Deve entrar no app

### 3. Testar Senha Errada

1. Tela de login
2. Email: teste@teste.com
3. Senha: senhaerrada
4. ✅ Deve mostrar: "Senha incorreta"

---

## 🔐 Verificar Se Funcionou

### No Console Firebase:

1. Vá em **Authentication** > **Users**
2. ✅ Deve aparecer o usuário `teste@teste.com` na lista

### No App:

1. Criar conta deve funcionar
2. Login deve funcionar
3. Senha errada deve dar erro específico
4. ❌ Não deve mais aparecer "CONFIGURATION_NOT_FOUND"

---

## 📱 Outros Erros na Tela (Não Críticos)

Esses avisos podem ser ignorados:

### "Reporter disconnected"
- ⚠️ Warning normal do Flutter
- Não afeta funcionamento
- Pode ignorar

### "Snapshotting a view"
- ⚠️ Warning do iOS
- Não afeta funcionamento
- Relacionado ao teclado

### "unable to decode ShellSceneKit"
- ⚠️ Warning do iOS
- Não afeta funcionamento
- Pode ignorar

---

## 🆘 Se Ainda Não Funcionar

### Verificar GoogleService-Info.plist

1. Abra: `ios/Runner/GoogleService-Info.plist`
2. Confirme que tem:
   ```xml
   <key>PROJECT_ID</key>
   <string>dietapro-f1b95</string>
   ```

### Baixar Novamente do Firebase

Se o arquivo estiver desatualizado:

1. Console Firebase > Project Settings (⚙️)
2. Role até "Your apps"
3. Clique no app iOS
4. Clique em "Download GoogleService-Info.plist"
5. Substitua o arquivo em `ios/Runner/`

### Reconfigurar Firebase

```bash
# Reinstalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Reconfigurar
flutterfire configure

# Selecione:
# - Project: dietapro-f1b95
# - Platforms: iOS, Android
```

---

## 📋 Checklist Final

Execute na ordem:

- [ ] Acessei console.firebase.google.com
- [ ] Selecionei projeto dietapro-f1b95
- [ ] Abri Authentication
- [ ] Cliquei em "Get Started" (se apareceu)
- [ ] Habilitei Email/Password em Sign-in method
- [ ] Salvei as alterações
- [ ] Executei `flutter clean`
- [ ] Executei `flutter pub get`
- [ ] Executei `pod install` no iOS
- [ ] Rodei o app novamente
- [ ] Testei criar uma conta
- [ ] Testei fazer login
- [ ] Não aparece mais erro CONFIGURATION_NOT_FOUND

---

## 💡 Por que isso aconteceu?

O Firebase Authentication precisa ser **explicitamente habilitado** no console. Apenas ter o SDK instalado no código não é suficiente.

Configuração necessária:
1. ✅ SDK instalado (já estava)
2. ✅ GoogleService-Info.plist (já estava)
3. ❌ **Authentication habilitado no console** ← Faltava isso!

---

**IMPORTANTE:** Após habilitar no console Firebase, aguarde 1-2 minutos para as configurações se propagarem, então recompile o app.

---

**Data:** 28 de novembro de 2025  
**Erro:** CONFIGURATION_NOT_FOUND  
**Status:** 🔧 Solução Documentada

