#!/bin/bash

echo "🔧 Script de Correção Definitiva do Abseil"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="/Users/nicolastresoldi/Desktop/Pessoal/Projetos/dietapro"
IOS_DIR="$PROJECT_DIR/ios"

cd "$IOS_DIR" || exit 1

echo "📍 Diretório atual: $(pwd)"
echo ""

# Passo 1: Fechar Xcode se estiver aberto
echo "1️⃣  Fechando Xcode..."
killall Xcode 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Xcode fechado${NC}"
echo ""

# Passo 2: Limpar DerivedData
echo "2️⃣  Limpando DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo -e "${GREEN}✅ DerivedData limpo${NC}"
echo ""

# Passo 3: Limpar Pods
echo "3️⃣  Removendo Pods e Podfile.lock..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
echo -e "${GREEN}✅ Pods removidos${NC}"
echo ""

# Passo 4: Limpar cache do Flutter
echo "4️⃣  Limpando cache do Flutter..."
cd "$PROJECT_DIR"
flutter clean
echo -e "${GREEN}✅ Flutter limpo${NC}"
echo ""

# Passo 5: Atualizar pubspec
echo "5️⃣  Atualizando dependências do Flutter..."
flutter pub get
echo -e "${GREEN}✅ Dependências atualizadas${NC}"
echo ""

# Passo 6: Voltar para iOS e reinstalar Pods
echo "6️⃣  Reinstalando Pods..."
cd "$IOS_DIR"
pod deintegrate 2>/dev/null || true
pod install --repo-update
echo -e "${GREEN}✅ Pods instalados${NC}"
echo ""

# Passo 7: Verificar se as configurações foram aplicadas
echo "7️⃣  Verificando configurações..."
echo ""

# Verificar ABSL_USES_STD_STRING_VIEW
if grep -q "ABSL_USES_STD_STRING_VIEW=1" "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig" 2>/dev/null; then
    echo -e "${GREEN}✅ ABSL_USES_STD_STRING_VIEW está configurado${NC}"
else
    echo -e "${YELLOW}⚠️  ABSL_USES_STD_STRING_VIEW pode não estar configurado${NC}"
fi

# Verificar padrão C++
if grep -q "gnu++14" "Pods/Pods.xcodeproj/project.pbxproj" 2>/dev/null; then
    echo -e "${GREEN}✅ Padrão C++14 está configurado${NC}"
else
    echo -e "${YELLOW}⚠️  Padrão C++14 pode não estar configurado${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Limpeza e reinstalação concluídas!${NC}"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "Opção A - Build via Xcode (RECOMENDADO):"
echo "  1. Abra o Xcode: open ios/Runner.xcworkspace"
echo "  2. Product → Clean Build Folder (Shift + Cmd + K)"
echo "  3. Aguarde 10 segundos"
echo "  4. Product → Build (Cmd + B)"
echo ""
echo "Opção B - Build via terminal:"
echo "  cd ios"
echo "  xcodebuild clean -workspace Runner.xcworkspace -scheme Runner"
echo "  xcodebuild build -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator"
echo ""
echo "Opção C - Executar via Flutter:"
echo "  flutter run"
echo ""

