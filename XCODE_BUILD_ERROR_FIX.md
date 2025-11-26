# Correção do Erro "Command PhaseScriptExecution failed"

Este erro geralmente está relacionado a scripts de build do Flutter ou CocoaPods.

## Soluções Aplicadas

### 1. Limpeza Completa ✅
- Executado `flutter clean`
- Removidos Pods e Podfile.lock
- Reinstalados pods com `pod install --repo-update`

### 2. Próximos Passos

Se o erro persistir, tente:

#### Opção A: Limpar DerivedData do Xcode
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

#### Opção B: Reabrir o Xcode
1. Feche o Xcode completamente
2. Abra o workspace (não o projeto):
```bash
open ios/Runner.xcworkspace
```
⚠️ **IMPORTANTE**: Sempre abra o `.xcworkspace`, nunca o `.xcodeproj`

#### Opção C: Verificar Scripts de Build
No Xcode:
1. Selecione o target "Runner"
2. Vá em "Build Phases"
3. Verifique se há scripts com erros (ícone vermelho)
4. Se houver, tente deletar e recriar

#### Opção D: Limpar Cache do Flutter
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install
```

#### Opção E: Verificar Permissões
```bash
chmod +x ios/Flutter/flutter_export_environment.sh
chmod +x ios/Flutter/Generated.xcconfig
```

## Se Nada Funcionar

1. Verifique os logs completos do Xcode (View > Navigators > Issues)
2. Procure por mensagens de erro específicas
3. Verifique se há problemas com:
   - Certificados de assinatura
   - Provisioning profiles
   - Versão do Xcode (deve ser compatível com o Flutter)

## Comandos Úteis

```bash
# Limpar tudo e reinstalar
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
flutter pub get
cd ios && pod install --repo-update

# Verificar versões
flutter doctor -v
pod --version
xcodebuild -version
```

