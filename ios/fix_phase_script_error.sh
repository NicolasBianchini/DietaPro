#!/bin/bash

echo "🔧 Correção Completa do Erro PhaseScriptExecution"
echo "=================================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Limpar Flutter
echo "1️⃣ Limpando projeto Flutter..."
cd "$(dirname "$0")/.."
flutter clean
echo -e "${GREEN}✅ Flutter limpo${NC}"
echo ""

# 2. Limpar iOS build
echo "2️⃣ Limpando build do iOS..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf Podfile.lock
rm -rf .symlinks/
rm -rf Flutter/Generated.xcconfig
rm -rf Flutter/flutter_export_environment.sh
echo -e "${GREEN}✅ Build iOS limpo${NC}"
echo ""

# 3. Limpar DerivedData
echo "3️⃣ Limpando DerivedData do Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo -e "${GREEN}✅ DerivedData limpo${NC}"
echo ""

# 4. Regenerar arquivos Flutter
echo "4️⃣ Regenerando arquivos Flutter..."
cd ..
flutter pub get
echo -e "${GREEN}✅ Arquivos Flutter regenerados${NC}"
echo ""

# 5. Reinstalar Pods
echo "5️⃣ Reinstalando CocoaPods..."
cd ios
pod install --repo-update
echo -e "${GREEN}✅ Pods reinstalados${NC}"
echo ""

# 6. Corrigir permissões
echo "6️⃣ Corrigindo permissões dos scripts..."
find . -name "*.sh" -exec chmod +x {} \;

FLUTTER_ROOT="/opt/homebrew/share/flutter"
if [ ! -d "$FLUTTER_ROOT" ]; then
    FLUTTER_ROOT=$(which flutter | sed 's|/bin/flutter||')
fi

XCODE_BACKEND="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ -f "$XCODE_BACKEND" ]; then
    chmod +x "$XCODE_BACKEND"
fi

if [ -f "Flutter/flutter_export_environment.sh" ]; then
    chmod +x "Flutter/flutter_export_environment.sh"
fi

if [ -f "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources.sh" ]; then
    chmod +x "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources.sh"
fi

echo -e "${GREEN}✅ Permissões corrigidas${NC}"
echo ""

# 7. Verificar configurações
echo "7️⃣ Verificando configurações..."
if [ -f "Flutter/Generated.xcconfig" ]; then
    echo -e "${GREEN}✅ Generated.xcconfig existe${NC}"
    if grep -q "FLUTTER_ROOT" "Flutter/Generated.xcconfig"; then
        echo -e "${GREEN}✅ FLUTTER_ROOT configurado corretamente${NC}"
    else
        echo -e "${YELLOW}⚠️  FLUTTER_ROOT não encontrado no Generated.xcconfig${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Generated.xcconfig não encontrado${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Correção completa!${NC}"
echo "=================================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Feche o Xcode completamente (se estiver aberto)"
echo "2. Abra o workspace (NUNCA o projeto diretamente):"
echo "   ${YELLOW}open ios/Runner.xcworkspace${NC}"
echo ""
echo "3. No Xcode:"
echo "   - Product → Clean Build Folder (Shift + Cmd + K)"
echo "   - Aguarde alguns segundos"
echo "   - Product → Build (Cmd + B)"
echo ""
echo "4. Se o erro persistir:"
echo "   - View → Navigators → Show Report Navigator (Cmd + 9)"
echo "   - Clique no build que falhou"
echo "   - Veja os logs detalhados do erro"
echo ""
echo "💡 Dica: Sempre abra o .xcworkspace, nunca o .xcodeproj!"
echo ""

