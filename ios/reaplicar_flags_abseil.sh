#!/bin/bash

# Script para reaplicar as flags ABSL_USES_STD_STRING_VIEW após pod install
# Use este script sempre que rodar 'pod install' ou 'pod update'

echo "🔧 Reaplicando Flags do Abseil"
echo "==============================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador
count=0
total=9

# Diretório
cd "$(dirname "$0")" || exit 1

# Lista de arquivos para adicionar a flag
FILES=(
  "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
  "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
  "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
  "Pods/Target Support Files/abseil/abseil.debug.xcconfig"
  "Pods/Target Support Files/abseil/abseil.release.xcconfig"
  "Pods/Target Support Files/gRPC-C++/gRPC-C++.debug.xcconfig"
  "Pods/Target Support Files/gRPC-C++/gRPC-C++.release.xcconfig"
  "Pods/Target Support Files/gRPC-Core/gRPC-Core.debug.xcconfig"
  "Pods/Target Support Files/gRPC-Core/gRPC-Core.release.xcconfig"
)

echo "Processando arquivos..."
echo ""

for file in "${FILES[@]}"; do
  ((count++))
  
  if [ -f "$file" ]; then
    # Verificar se já tem a flag
    if grep -q "ABSL_USES_STD_STRING_VIEW=1" "$file"; then
      echo -e "${YELLOW}[$count/$total]${NC} ⚠️  $(basename "$file") - Flag já existe"
    else
      # Adicionar a flag na linha GCC_PREPROCESSOR_DEFINITIONS
      if grep -q "GCC_PREPROCESSOR_DEFINITIONS" "$file"; then
        # Usar sed para adicionar no final da linha
        sed -i '' 's/\(GCC_PREPROCESSOR_DEFINITIONS = .*\)/\1 ABSL_USES_STD_STRING_VIEW=1/' "$file"
        echo -e "${GREEN}[$count/$total]${NC} ✅ $(basename "$file") - Flag adicionada"
      else
        # Se não tem GCC_PREPROCESSOR_DEFINITIONS, adicionar a linha completa
        echo "GCC_PREPROCESSOR_DEFINITIONS = \$(inherited) ABSL_USES_STD_STRING_VIEW=1" >> "$file"
        echo -e "${GREEN}[$count/$total]${NC} ✅ $(basename "$file") - Linha e flag adicionadas"
      fi
    fi
  else
    echo -e "${RED}[$count/$total]${NC} ❌ $(basename "$file") - Arquivo não encontrado"
  fi
done

echo ""
echo "==============================="
echo -e "${GREEN}🎉 Processo concluído!${NC}"
echo ""
echo "Verificando as flags aplicadas..."
echo ""

# Verificar se as flags foram aplicadas
verification_failed=0

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    if grep -q "ABSL_USES_STD_STRING_VIEW=1" "$file"; then
      echo -e "${GREEN}✅${NC} $(basename "$file")"
    else
      echo -e "${RED}❌${NC} $(basename "$file") - FALHOU"
      verification_failed=1
    fi
  fi
done

echo ""

if [ $verification_failed -eq 0 ]; then
  echo -e "${GREEN}════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Todas as flags foram aplicadas com sucesso!${NC}"
  echo -e "${GREEN}════════════════════════════════${NC}"
  echo ""
  echo "Próximo passo:"
  echo "  1. Feche o Xcode se estiver aberto"
  echo "  2. Abra: open Runner.xcworkspace"
  echo "  3. Product → Clean Build Folder"
  echo "  4. Product → Build"
else
  echo -e "${RED}════════════════════════════════${NC}"
  echo -e "${RED}⚠️  Algumas flags não foram aplicadas${NC}"
  echo -e "${RED}════════════════════════════════${NC}"
  echo ""
  echo "Verifique os erros acima e tente novamente."
fi

echo ""





