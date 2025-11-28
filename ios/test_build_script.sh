#!/bin/bash

echo "🧪 Testando Script de Build do Flutter"
echo "======================================"
echo ""

# Simular o ambiente do Xcode
export FLUTTER_ROOT="/opt/homebrew/share/flutter"
export FLUTTER_APPLICATION_PATH="/Users/nicolastresoldi/Desktop/Pessoal/Projetos/dietapro"
export FLUTTER_BUILD_MODE="Debug"
export FLUTTER_TARGET="lib/main.dart"
export FLUTTER_BUILD_DIR="build"

# Verificar se FLUTTER_ROOT está definido
if [ -z "$FLUTTER_ROOT" ]; then
    echo "❌ ERRO: FLUTTER_ROOT não está definido!"
    exit 1
fi

echo "✅ FLUTTER_ROOT: $FLUTTER_ROOT"
echo "✅ FLUTTER_APPLICATION_PATH: $FLUTTER_APPLICATION_PATH"
echo "✅ FLUTTER_BUILD_MODE: $FLUTTER_BUILD_MODE"
echo ""

# Verificar se o script existe
XCODE_BACKEND="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"

if [ ! -f "$XCODE_BACKEND" ]; then
    echo "❌ ERRO: Script não encontrado em: $XCODE_BACKEND"
    exit 1
fi

echo "✅ Script encontrado: $XCODE_BACKEND"
echo ""

# Tentar executar o script com 'build'
echo "🔨 Testando execução do script com 'build'..."
echo ""

cd "$FLUTTER_APPLICATION_PATH"

# Executar o script e capturar saída e erro
if "$XCODE_BACKEND" build 2>&1; then
    echo ""
    echo "✅ Script executado com sucesso!"
else
    EXIT_CODE=$?
    echo ""
    echo "❌ Script falhou com código de saída: $EXIT_CODE"
    echo ""
    echo "📋 Possíveis causas:"
    echo "   1. Variáveis de ambiente não definidas corretamente"
    echo "   2. Arquivos do Flutter corrompidos ou ausentes"
    echo "   3. Problema com permissões"
    echo "   4. Dependências do Flutter não instaladas"
    exit $EXIT_CODE
fi

echo ""
echo "✅ Teste concluído com sucesso!"

