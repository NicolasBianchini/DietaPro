# Correção de Assinatura iOS

## Problema Resolvido
Adicionei `CODE_SIGN_STYLE = Automatic` nas configurações do projeto para que o Xcode gerencie automaticamente os perfis de provisionamento.

## Próximos Passos

### 1. Adicionar Conta da Apple Developer no Xcode

1. Abra o Xcode:
```bash
open ios/Runner.xcworkspace
```

2. No Xcode, vá em:
   - **Xcode** → **Settings** (ou **Preferences**)
   - Aba **Accounts**
   - Clique no botão **+** (adicionar conta)
   - Faça login com sua Apple ID

### 2. Verificar/Atualizar o Bundle Identifier

O bundle identifier atual é `com.example.dietapro`, que é genérico. Para desenvolvimento, você tem duas opções:

#### Opção A: Usar Automatic Signing (Recomendado)
- O Xcode criará automaticamente um perfil de provisionamento
- Pode ser necessário mudar o bundle identifier para algo único (ex: `com.seunome.dietapro`)

#### Opção B: Manter o Bundle Identifier Atual
- Se você já tem um perfil de provisionamento para `com.example.dietapro`, pode manter
- Caso contrário, o Xcode pode sugerir mudar automaticamente

### 3. Configurar o Signing no Xcode

1. No Xcode, selecione o projeto **Runner** no navegador
2. Selecione o target **Runner**
3. Vá na aba **Signing & Capabilities**
4. Marque **Automatically manage signing**
5. Selecione seu **Team** (a conta que você adicionou)
6. Se necessário, o Xcode criará automaticamente um novo bundle identifier único

### 4. Tentar Executar Novamente

Depois de configurar a conta e o signing:

```bash
flutter clean
flutter pub get
flutter run -d 00008110-000211120286201E
```

## Solução Alternativa: Mudar Bundle Identifier

Se você preferir mudar o bundle identifier manualmente para algo único, edite o arquivo `ios/Runner.xcodeproj/project.pbxproj` e substitua todas as ocorrências de:

```
PRODUCT_BUNDLE_IDENTIFIER = com.example.dietapro;
```

Por algo único, como:

```
PRODUCT_BUNDLE_IDENTIFIER = com.seunome.dietapro;
```

**Nota:** Se você usar Firebase ou outros serviços, também precisará atualizar o bundle identifier nesses serviços.

## Verificação

Após seguir os passos acima, o erro deve ser resolvido. O Xcode criará automaticamente os perfis de provisionamento necessários quando você tentar fazer o build.

## Problema: Módulos CocoaPods Não Encontrados

Se você encontrar erros como:
- `Module 'cloud_firestore' not found`
- `Search path '.../BoringSSL-GRPC' not found`
- Outros erros relacionados a módulos do CocoaPods

### Solução:

1. **Limpar DerivedData do Xcode:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

2. **Limpar e reinstalar tudo:**
```bash
cd ios
./clean_xcode.sh
```

Ou manualmente:
```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
```

3. **IMPORTANTE: Use o workspace, não o projeto:**
   - ✅ **Correto:** `open ios/Runner.xcworkspace`
   - ❌ **Errado:** `open ios/Runner.xcodeproj`

4. **Feche e reabra o Xcode completamente** após limpar o DerivedData

5. **Tente fazer o build novamente**

### O que foi corrigido:

- ✅ Adicionado `CODE_SIGN_STYLE = Automatic` nas configurações
- ✅ Especificada a plataforma iOS no Podfile (`platform :ios, '13.0'`)
- ✅ Reinstalados os pods do CocoaPods
- ✅ Criado script de limpeza (`ios/clean_xcode.sh`)

