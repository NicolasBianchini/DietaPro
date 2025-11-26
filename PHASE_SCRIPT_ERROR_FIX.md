# Correção do Erro "Command PhaseScriptExecution failed"

## Problema
O erro "Command PhaseScriptExecution failed with a nonzero exit code" geralmente ocorre quando:
1. O script de build do Flutter não encontra o `FLUTTER_ROOT`
2. A variável `FLUTTER_BUILD_MODE` não está definida
3. Há problemas com permissões ou caminhos

## Soluções Aplicadas ✅

### 1. Deployment Targets Corrigidos
- Atualizado Podfile para forçar iOS 13.0 em todos os pods
- Corrigidos avisos sobre deployment targets antigos (9.0, 10.0, 11.0)

### 2. Variáveis de Build Adicionadas
- Adicionado `FLUTTER_BUILD_MODE=Debug` em `Debug.xcconfig`
- Adicionado `FLUTTER_BUILD_MODE=Release` em `Release.xcconfig`

## Próximos Passos

### 1. Fechar e Reabrir o Xcode
```bash
# Feche o Xcode completamente
# Depois abra o workspace (NUNCA o projeto diretamente):
open ios/Runner.xcworkspace
```

### 2. Limpar Build no Xcode
No Xcode:
- Menu: Product → Clean Build Folder (Shift + Cmd + K)
- Ou: Product → Clean (Cmd + K)

### 3. Verificar Scripts de Build
No Xcode:
1. Selecione o target "Runner"
2. Vá em "Build Phases"
3. Expanda "Run Script"
4. Verifique se o script está correto:
   ```
   /bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" build
   ```

### 4. Se o Erro Persistir

#### Opção A: Verificar Logs Detalhados
No Xcode:
- View → Navigators → Show Report Navigator (Cmd + 9)
- Clique no build que falhou
- Veja os logs completos do erro

#### Opção B: Reconstruir Scripts
```bash
cd /Users/nicolastresoldi/Desktop/Pessoal/Projetos/dietapro
flutter clean
rm -rf ios/Flutter/Generated.xcconfig
flutter pub get
cd ios && pod install
```

#### Opção C: Verificar Permissões
```bash
chmod +x /opt/homebrew/share/flutter/packages/flutter_tools/bin/xcode_backend.sh
chmod +x ios/Flutter/flutter_export_environment.sh
```

## Avisos (Podem ser Ignorados)

Os seguintes avisos são normais e não impedem o build:
- ⚠️ Métodos deprecated do Firebase (são avisos, não erros)
- ⚠️ "Run script build phase will be run during every build" (normal para scripts do Flutter)
- ⚠️ "CocoaPods did not set the base configuration" (normal quando há configs customizadas)

## Comandos de Diagnóstico

```bash
# Verificar Flutter
flutter doctor -v

# Verificar se o script existe
test -f /opt/homebrew/share/flutter/packages/flutter_tools/bin/xcode_backend.sh && echo "OK" || echo "ERRO"

# Verificar variáveis
echo $FLUTTER_ROOT
```

