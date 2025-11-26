#!/bin/bash

# Script para corrigir problemas com scripts de build do Flutter

echo "🔧 Corrigindo scripts de build do Flutter..."

# 1. Verificar se o Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado no PATH"
    exit 1
fi

# Ler FLUTTER_ROOT do Generated.xcconfig (mais confiável)
cd "$(dirname "$0")/.."
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    FLUTTER_ROOT=$(grep "FLUTTER_ROOT=" ios/Flutter/Generated.xcconfig | cut -d'=' -f2 | tr -d ' ')
else
    FLUTTER_ROOT=$(which flutter | sed 's|/bin/flutter||')
fi

echo "✅ Flutter encontrado em: $FLUTTER_ROOT"

# 2. Verificar se o script xcode_backend.sh existe
XCODE_BACKEND="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ ! -f "$XCODE_BACKEND" ]; then
    echo "❌ Script xcode_backend.sh não encontrado em: $XCODE_BACKEND"
    exit 1
fi

echo "✅ Script xcode_backend.sh encontrado"

# 3. Dar permissão de execução
chmod +x "$XCODE_BACKEND"
echo "✅ Permissões de execução configuradas"

# 4. Verificar arquivos de configuração
cd "$(dirname "$0")/.."

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "⚠️  Generated.xcconfig não encontrado, regenerando..."
    flutter pub get
fi

# 5. Verificar se FLUTTER_ROOT está correto no Generated.xcconfig
if grep -q "FLUTTER_ROOT" ios/Flutter/Generated.xcconfig; then
    echo "✅ FLUTTER_ROOT configurado em Generated.xcconfig"
else
    echo "❌ FLUTTER_ROOT não encontrado em Generated.xcconfig"
    exit 1
fi

# 6. Verificar arquivos xcconfig
if [ -f "ios/Flutter/Debug.xcconfig" ] && [ -f "ios/Flutter/Release.xcconfig" ]; then
    echo "✅ Arquivos xcconfig encontrados"
else
    echo "❌ Arquivos xcconfig não encontrados"
    exit 1
fi

# 7. Limpar DerivedData
echo "🧹 Limpando DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null
echo "✅ DerivedData limpo"

echo ""
echo "✅ Correções aplicadas!"
echo ""
echo "Próximos passos:"
echo "1. Feche o Xcode completamente"
echo "2. Abra: open ios/Runner.xcworkspace"
echo "3. No Xcode: Product → Clean Build Folder (Shift+Cmd+K)"
echo "4. Tente fazer o build novamente"
echo ""

