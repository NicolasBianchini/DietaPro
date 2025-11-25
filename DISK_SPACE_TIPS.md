# Dicas para Gerenciar Espaço em Disco

## Problema Recorrente

O disco está enchendo durante builds do iOS porque:
- Firebase e suas dependências (gRPC, Protobuf) geram muitos arquivos temporários
- O Xcode cria muitos arquivos de cache no DerivedData
- Cada build pode usar vários GB de espaço

## Soluções Rápidas

### 1. Limpar Automaticamente
Execute sempre antes de builds grandes:
```bash
./cleanup_disk.sh
```

### 2. Usar macOS ao Invés de iOS
Para desenvolvimento diário, use macOS que é:
- **Muito mais rápido** (2-5 min vs 15-30 min)
- **Usa menos espaço** (menos dependências)
- **Hot reload funciona igual**

```bash
flutter run -d macos
```

### 3. Limpar DerivedData do Xcode Regularmente
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 4. Limpar Builds Antigos
```bash
flutter clean
rm -rf build/
```

## Monitoramento de Espaço

Verifique o espaço antes de builds grandes:
```bash
df -h /
```

Se estiver acima de 85%, limpe antes de continuar.

## Configuração Recomendada

Para desenvolvimento:
1. **Use macOS** para desenvolvimento diário
2. **Use iOS** apenas quando precisar testar funcionalidades específicas do iOS
3. **Limpe regularmente** com `./cleanup_disk.sh`

## Limpeza Automática (Opcional)

Você pode criar um alias no seu `.zshrc`:
```bash
alias flutter-clean='./cleanup_disk.sh && flutter pub get'
```

Então sempre use:
```bash
flutter-clean
flutter run -d macos
```

