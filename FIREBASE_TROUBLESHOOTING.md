# Solução de Problemas do Firebase

## Erro: "Unable to establish connection on channel"

Este erro geralmente ocorre quando:

1. **Hot Reload/Restart**: O Firebase não consegue se reconectar após hot reload/restart
   - **Solução**: Pare o app completamente e inicie novamente (não use hot reload)
   - Execute: `flutter run` novamente
   - ⚠️ **IMPORTANTE**: Hot restart não é suficiente - você precisa parar e iniciar o app do zero

2. **Plugins nativos não instalados**: Os plugins do Firebase não foram instalados corretamente
   - **Solução Rápida**: Execute o script `./fix_firebase.sh`
   - **Solução Manual**: Execute:
     ```bash
     flutter clean
     flutter pub get
     cd ios && pod install && cd ..  # Para iOS
     cd macos && pod install && cd ..  # Para macOS
     flutter run
     ```

3. **Arquivos de configuração ausentes**: Faltam arquivos de configuração do Firebase
   - **Android**: `android/app/google-services.json`
   - **iOS**: `ios/Runner/GoogleService-Info.plist`
   - **macOS**: `macos/Runner/GoogleService-Info.plist`
   - **Solução**: Execute `flutterfire configure` novamente

## Verificações

### 1. Verificar se o Firebase está inicializado

O código em `main.dart` agora verifica se o Firebase já foi inicializado antes de tentar inicializar novamente. Isso ajuda com hot restart.

### 2. Reconstruir o app completamente

```bash
# Limpar build
flutter clean

# Reinstalar dependências
flutter pub get

# Para iOS, reinstalar pods
cd ios
pod install
cd ..

# Executar novamente
flutter run
```

### 3. Verificar configuração do Firebase

Certifique-se de que:
- O projeto Firebase está configurado corretamente
- Os arquivos de configuração estão nos lugares corretos
- O `firebase_options.dart` está atualizado

### 4. Para desenvolvimento

O app agora continua funcionando mesmo se o Firebase falhar na inicialização. Isso permite desenvolvimento sem Firebase, mas recursos do Firestore não estarão disponíveis.

## Comandos úteis

```bash
# Script automático para corrigir problemas
./fix_firebase.sh

# Verificar configuração do Firebase
flutterfire configure

# Limpar e reconstruir
flutter clean && flutter pub get && flutter run

# Reinstalar pods do iOS
cd ios && pod install && cd ..

# Reinstalar pods do macOS
cd macos && pod install && cd ..

# Verificar dependências
flutter pub outdated

# Verificar erros
flutter analyze
```

## ⚠️ Solução Rápida para o Erro Atual

Se você está vendo o erro "Unable to establish connection on channel":

1. **Pare completamente o app** (não apenas hot restart)
   - Pressione `q` no terminal onde o app está rodando
   - Ou feche o app no simulador/dispositivo

2. **Execute o script de correção**:
   ```bash
   ./fix_firebase.sh
   ```

3. **Inicie o app novamente**:
   ```bash
   flutter run
   ```

**NÃO use hot reload ou hot restart** - o Firebase precisa de uma inicialização completa do app.

## Próximos passos

Se o erro persistir:
1. Verifique os logs completos do erro
2. Certifique-se de que o Firebase está configurado no console
3. Verifique se todas as dependências estão instaladas
4. Tente executar em um dispositivo físico ao invés de emulador

