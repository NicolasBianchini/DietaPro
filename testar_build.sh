#!/bin/bash

echo "🧪 Testando Build do iOS após correções"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se estamos no diretório correto
if [ ! -d "ios" ]; then
    echo -e "${RED}❌ Erro: Execute este script do diretório raiz do projeto${NC}"
    exit 1
fi

echo "📋 Escolha uma opção de teste:"
echo ""
echo "1) Build rápido via Flutter (recomendado)"
echo "2) Build detalhado via Xcode"
echo "3) Apenas verificar configurações"
echo "4) Limpar tudo e reconstruir"
echo ""
read -p "Opção [1-4]: " opcao

case $opcao in
    1)
        echo ""
        echo "🚀 Iniciando build via Flutter..."
        echo ""
        flutter build ios --simulator --debug --no-codesign
        BUILD_EXIT=$?
        
        if [ $BUILD_EXIT -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ BUILD SUCCEEDED!${NC}"
            echo ""
            echo "Os erros de Abseil foram corrigidos! 🎉"
            echo ""
            echo "Próximos passos:"
            echo "  - Execute: flutter run -d 'iPhone 17'"
            echo "  - Ou abra no Xcode: open ios/Runner.xcworkspace"
        else
            echo ""
            echo -e "${RED}❌ Build falhou${NC}"
            echo ""
            echo "Para ver detalhes completos, execute:"
            echo "  flutter build ios --simulator --debug --no-codesign --verbose"
        fi
        ;;
        
    2)
        echo ""
        echo "🔨 Iniciando build via Xcode..."
        echo ""
        cd ios
        xcodebuild clean -workspace Runner.xcworkspace -scheme Runner -configuration Debug -quiet
        
        echo "Compilando... (isso pode levar alguns minutos)"
        xcodebuild build \
          -workspace Runner.xcworkspace \
          -scheme Runner \
          -configuration Debug \
          -sdk iphonesimulator \
          -destination 'platform=iOS Simulator,name=iPhone 17' \
          > /tmp/xcode_build_full.log 2>&1
        
        BUILD_EXIT=$?
        
        if [ $BUILD_EXIT -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ BUILD SUCCEEDED!${NC}"
            echo ""
            echo "Os erros de Abseil foram corrigidos! 🎉"
        else
            echo ""
            echo -e "${RED}❌ Build falhou${NC}"
            echo ""
            echo "Últimas linhas do log:"
            tail -30 /tmp/xcode_build_full.log
            echo ""
            echo "Log completo salvo em: /tmp/xcode_build_full.log"
            echo ""
            
            # Verificar se ainda há erros de Abseil
            if grep -q "Undefined symbol.*absl::lts_20240722" /tmp/xcode_build_full.log; then
                echo -e "${YELLOW}⚠️  Ainda há erros de símbolos do Abseil${NC}"
                echo ""
                echo "Execute para reconfigurar:"
                echo "  cd ios"
                echo "  bash fix_abseil_linker.sh"
            elif grep -q "leveldb" /tmp/xcode_build_full.log; then
                echo -e "${YELLOW}⚠️  Erros relacionados ao leveldb${NC}"
            fi
        fi
        ;;
        
    3)
        echo ""
        echo "🔍 Verificando configurações..."
        echo ""
        cd ios
        bash verify_abseil_fix.sh
        ;;
        
    4)
        echo ""
        echo "🧹 Limpando tudo..."
        echo ""
        
        # Limpar DerivedData
        echo "1/4 Limpando DerivedData..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        
        # Flutter clean
        echo "2/4 Limpando build do Flutter..."
        flutter clean
        
        # Regenerar
        echo "3/4 Regenerando dependências Flutter..."
        flutter pub get
        
        # Reinstalar pods
        echo "4/4 Reinstalando CocoaPods..."
        cd ios
        pod deintegrate
        pod install --repo-update
        
        echo ""
        echo -e "${GREEN}✅ Limpeza concluída!${NC}"
        echo ""
        echo "Agora execute este script novamente e escolha opção 1 ou 2"
        ;;
        
    *)
        echo ""
        echo -e "${RED}Opção inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Teste concluído"
echo "=========================================="
echo ""

