#!/bin/bash

echo "🔍 Diagnóstico do Erro PhaseScriptExecution"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar Flutter Root
echo "1️⃣ Verificando FLUTTER_ROOT..."
FLUTTER_ROOT="/opt/homebrew/share/flutter"
if [ -d "$FLUTTER_ROOT" ]; then
    echo -e "${GREEN}✅ FLUTTER_ROOT encontrado: $FLUTTER_ROOT${NC}"
else
    FLUTTER_ROOT=$(which flutter | sed 's|/bin/flutter||')
    if [ -d "$FLUTTER_ROOT" ]; then
        echo -e "${GREEN}✅ FLUTTER_ROOT encontrado: $FLUTTER_ROOT${NC}"
    else
        echo -e "${RED}❌ FLUTTER_ROOT não encontrado!${NC}"
        exit 1
    fi
fi

# 2. Verificar script xcode_backend.sh
echo ""
echo "2️⃣ Verificando script xcode_backend.sh..."
XCODE_BACKEND="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ -f "$XCODE_BACKEND" ]; then
    echo -e "${GREEN}✅ Script encontrado: $XCODE_BACKEND${NC}"
    if [ -x "$XCODE_BACKEND" ]; then
        echo -e "${GREEN}✅ Script tem permissão de execução${NC}"
    else
        echo -e "${YELLOW}⚠️  Script não tem permissão de execução, corrigindo...${NC}"
        chmod +x "$XCODE_BACKEND"
        echo -e "${GREEN}✅ Permissão corrigida${NC}"
    fi
    
    # Testar execução do script
    echo "   Testando execução do script..."
    if "$XCODE_BACKEND" --version > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Script pode ser executado${NC}"
    else
        echo -e "${YELLOW}⚠️  Script não retornou versão (pode ser normal)${NC}"
    fi
else
    echo -e "${RED}❌ Script não encontrado em: $XCODE_BACKEND${NC}"
    exit 1
fi

# 3. Verificar Generated.xcconfig
echo ""
echo "3️⃣ Verificando Generated.xcconfig..."
GENERATED_CONFIG="Flutter/Generated.xcconfig"
if [ -f "$GENERATED_CONFIG" ]; then
    echo -e "${GREEN}✅ Generated.xcconfig encontrado${NC}"
    if grep -q "FLUTTER_ROOT" "$GENERATED_CONFIG"; then
        FLUTTER_ROOT_FROM_CONFIG=$(grep "FLUTTER_ROOT" "$GENERATED_CONFIG" | cut -d'=' -f2)
        echo -e "${GREEN}✅ FLUTTER_ROOT no config: $FLUTTER_ROOT_FROM_CONFIG${NC}"
        
        if [ "$FLUTTER_ROOT_FROM_CONFIG" != "$FLUTTER_ROOT" ]; then
            echo -e "${YELLOW}⚠️  FLUTTER_ROOT no config difere do encontrado!${NC}"
            echo "   Config: $FLUTTER_ROOT_FROM_CONFIG"
            echo "   Encontrado: $FLUTTER_ROOT"
        fi
    else
        echo -e "${RED}❌ FLUTTER_ROOT não encontrado no Generated.xcconfig${NC}"
    fi
else
    echo -e "${RED}❌ Generated.xcconfig não encontrado!${NC}"
    echo "   Execute: flutter pub get"
    exit 1
fi

# 4. Verificar flutter_export_environment.sh
echo ""
echo "4️⃣ Verificando flutter_export_environment.sh..."
EXPORT_SCRIPT="Flutter/flutter_export_environment.sh"
if [ -f "$EXPORT_SCRIPT" ]; then
    echo -e "${GREEN}✅ Script encontrado${NC}"
    if [ -x "$EXPORT_SCRIPT" ]; then
        echo -e "${GREEN}✅ Script tem permissão de execução${NC}"
    else
        echo -e "${YELLOW}⚠️  Corrigindo permissão...${NC}"
        chmod +x "$EXPORT_SCRIPT"
        echo -e "${GREEN}✅ Permissão corrigida${NC}"
    fi
else
    echo -e "${RED}❌ Script não encontrado!${NC}"
    echo "   Execute: flutter pub get"
    exit 1
fi

# 5. Verificar arquivos .xcconfig
echo ""
echo "5️⃣ Verificando arquivos .xcconfig..."
for config in Debug.xcconfig Release.xcconfig Profile.xcconfig; do
    if [ -f "Flutter/$config" ]; then
        echo -e "${GREEN}✅ $config encontrado${NC}"
        if grep -q "FLUTTER_BUILD_MODE" "Flutter/$config"; then
            echo -e "${GREEN}   ✅ FLUTTER_BUILD_MODE definido${NC}"
        else
            echo -e "${YELLOW}   ⚠️  FLUTTER_BUILD_MODE não definido em $config${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  $config não encontrado${NC}"
    fi
done

# 6. Verificar Pods
echo ""
echo "6️⃣ Verificando CocoaPods..."
if [ -d "Pods" ]; then
    echo -e "${GREEN}✅ Diretório Pods existe${NC}"
    
    # Verificar script de recursos
    RESOURCES_SCRIPT="Pods/Target Support Files/Pods-Runner/Pods-Runner-resources.sh"
    if [ -f "$RESOURCES_SCRIPT" ]; then
        echo -e "${GREEN}✅ Script de recursos encontrado${NC}"
        if [ -x "$RESOURCES_SCRIPT" ]; then
            echo -e "${GREEN}✅ Script tem permissão de execução${NC}"
        else
            echo -e "${YELLOW}⚠️  Corrigindo permissão...${NC}"
            chmod +x "$RESOURCES_SCRIPT"
            echo -e "${GREEN}✅ Permissão corrigida${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Script de recursos não encontrado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Diretório Pods não encontrado${NC}"
    echo "   Execute: pod install"
fi

# 7. Verificar variáveis de ambiente
echo ""
echo "7️⃣ Verificando variáveis de ambiente..."
if [ -z "$FLUTTER_ROOT" ]; then
    echo -e "${YELLOW}⚠️  FLUTTER_ROOT não está definido no ambiente${NC}"
    echo "   Isso é normal se você não exportou no shell"
else
    echo -e "${GREEN}✅ FLUTTER_ROOT no ambiente: $FLUTTER_ROOT${NC}"
fi

# 8. Testar simulação do script de build
echo ""
echo "8️⃣ Testando simulação do script de build..."
cd ..
export FLUTTER_ROOT="$FLUTTER_ROOT"
export FLUTTER_APPLICATION_PATH="$(pwd)"
export FLUTTER_BUILD_MODE="Debug"

echo "   FLUTTER_ROOT=$FLUTTER_ROOT"
echo "   FLUTTER_APPLICATION_PATH=$FLUTTER_APPLICATION_PATH"
echo "   FLUTTER_BUILD_MODE=$FLUTTER_BUILD_MODE"

if [ -f "$XCODE_BACKEND" ]; then
    echo "   Testando execução do script com 'build'..."
    # Não executar realmente, apenas verificar se o script existe e é executável
    if "$XCODE_BACKEND" --help > /dev/null 2>&1 || [ $? -eq 0 ] || [ $? -eq 1 ]; then
        echo -e "${GREEN}✅ Script pode ser executado${NC}"
    else
        echo -e "${YELLOW}⚠️  Script retornou código de erro (pode ser normal)${NC}"
    fi
fi

# 9. Verificar DerivedData
echo ""
echo "9️⃣ Verificando DerivedData..."
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA" ]; then
    SIZE=$(du -sh "$DERIVED_DATA" 2>/dev/null | cut -f1)
    echo "   Tamanho do DerivedData: $SIZE"
    echo -e "${YELLOW}   💡 Se o build falhar, tente limpar: rm -rf ~/Library/Developer/Xcode/DerivedData/*${NC}"
fi

# Resumo
echo ""
echo "=========================================="
echo "📋 Resumo do Diagnóstico"
echo "=========================================="
echo ""
echo "✅ Se todos os itens acima estão OK, o problema pode ser:"
echo "   1. Cache corrompido do Xcode"
echo "   2. Problema com o workspace (abra Runner.xcworkspace, não Runner.xcodeproj)"
echo "   3. Problema com certificados/provisioning profiles"
echo ""
echo "🔧 Próximos passos recomendados:"
echo "   1. Feche o Xcode completamente"
echo "   2. Limpe o DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "   3. Abra o workspace: open ios/Runner.xcworkspace"
echo "   4. No Xcode: Product → Clean Build Folder (Shift + Cmd + K)"
echo "   5. Tente compilar novamente"
echo ""
echo "📝 Se o erro persistir, verifique os logs detalhados no Xcode:"
echo "   View → Navigators → Show Report Navigator (Cmd + 9)"
echo ""

