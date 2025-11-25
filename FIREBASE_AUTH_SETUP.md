# Configuração do Firebase Authentication

## Erro: CONFIGURATION_NOT_FOUND

Este erro ocorre quando o Firebase Authentication não está habilitado no console do Firebase.

## Solução Passo a Passo

### 1. Acessar o Console do Firebase

1. Vá para: https://console.firebase.google.com/
2. Selecione o projeto: **dietapro-f1b95**

### 2. Habilitar Firebase Authentication

1. No menu lateral, clique em **"Authentication"** (Autenticação)
2. Se você ver uma tela de "Get Started", clique em **"Get Started"**
3. Se já estiver configurado, vá para a aba **"Sign-in method"** (Método de login)

### 3. Habilitar Email/Password

1. Na lista de provedores, encontre **"Email/Password"**
2. Clique nele
3. **Ative o primeiro toggle** (Enable)
4. **Ative o segundo toggle** (Email link - opcional, mas recomendado)
5. Clique em **"Save"** (Salvar)

### 4. Verificar Configuração

Após habilitar, você deve ver:
- ✅ Email/Password com status "Enabled"
- ✅ Um ícone de check verde

## Verificação Rápida

Após configurar, teste novamente:
1. Pare o app completamente
2. Execute: `flutter run -d macos` (ou iOS)
3. Tente criar uma conta ou fazer login

## Outros Métodos de Autenticação (Opcional)

Se quiser adicionar outros métodos no futuro:
- **Google Sign-In**: Para login com Google
- **Apple Sign-In**: Para login com Apple (iOS/macOS)
- **Phone**: Para autenticação por SMS

## Troubleshooting

Se o erro persistir após habilitar:

1. **Verifique se está no projeto correto**
   - Projeto: `dietapro-f1b95`
   - Verifique no `firebase_options.dart`

2. **Reconfigure o Firebase**
   ```bash
   flutterfire configure
   ```

3. **Limpe e reconstrua**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Verifique os arquivos de configuração**
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - macOS: `macos/Runner/GoogleService-Info.plist`
   - Android: `android/app/google-services.json` (se tiver)

## Status Esperado

Após configurar corretamente, você deve ver no console:
- ✅ Authentication habilitado
- ✅ Email/Password habilitado
- ✅ Usuários podem ser criados e autenticados

