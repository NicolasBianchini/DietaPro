# Debug do Gemini Service

## Problema: NotInitializedError

Se você ainda está vendo este erro, siga estes passos:

### 1. Verificar Logs

Quando você tentar usar o Gemini, verifique os logs no console. Você deve ver:
- `✅ Arquivo .env carregado com sucesso` (no main.dart)
- `🔑 Tentativa 1: .env carregado...` (no gemini_service.dart)
- `✅ Gemini Service inicializado com sucesso`

### 2. Verificar se o .env está sendo carregado

Execute no terminal:
```bash
cat .env
```

Deve mostrar:
```
GEMINI_API_KEY=AIzaSyBtGOuNqMmk_kTY5ybIUYxnpzQobv0wxUM
```

### 3. Solução Temporária: Usar Chave Diretamente

Se o .env não estiver funcionando, você pode temporariamente usar a chave diretamente no código:

**⚠️ ATENÇÃO: Isso é apenas para teste! Nunca commite chaves API no código!**

No arquivo `lib/services/gemini_service.dart`, substitua:

```dart
final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyBtGOuNqMmk_kTY5ybIUYxnpzQobv0wxUM';
```

### 4. Reiniciar o App Completamente

**IMPORTANTE**: Pare o app completamente e reinicie:
```bash
# Pare o app (Ctrl+C ou feche)
flutter clean
flutter pub get
flutter run -d macos
```

### 5. Verificar se o .env está no lugar certo

O arquivo `.env` deve estar na **raiz do projeto**, no mesmo nível que `pubspec.yaml`:

```
dietapro/
├── .env          ← AQUI
├── pubspec.yaml
├── lib/
└── ...
```

### 6. Verificar se o .env não tem espaços extras

O arquivo deve ter exatamente:
```
GEMINI_API_KEY=AIzaSyBtGOuNqMmk_kTY5ybIUYxnpzQobv0wxUM
```

Sem espaços antes ou depois do `=`, sem aspas, sem quebras de linha extras.

## Se Nada Funcionar

1. Verifique os logs completos no console
2. Tente a solução temporária (chave direta) para confirmar que a chave funciona
3. Se funcionar com a chave direta, o problema é o carregamento do .env
4. Nesse caso, considere usar variáveis de ambiente do sistema ou outro método

