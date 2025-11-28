#!/bin/bash

echo "🔍 Verificando Correções do Abseil"
echo "===================================="
echo ""

echo "1️⃣ Verificando padrão C++ no projeto Runner..."
CPP_STANDARD=$(grep "CLANG_CXX_LANGUAGE_STANDARD" Runner.xcodeproj/project.pbxproj | head -1 | grep -o '"[^"]*"' | tr -d '"')
if [ "$CPP_STANDARD" = "gnu++14" ] || [ "$CPP_STANDARD" = "gnu++17" ]; then
    echo "   ✅ C++ Standard: $CPP_STANDARD (OK)"
else
    echo "   ⚠️  C++ Standard: $CPP_STANDARD (Deveria ser gnu++14 ou gnu++17)"
fi
echo ""

echo "2️⃣ Verificando configuração do Abseil no Podfile..."
if grep -q "target.name == 'abseil'" Podfile; then
    echo "   ✅ Configuração específica do Abseil encontrada no Podfile"
    grep -A 5 "target.name == 'abseil'" Podfile | sed 's/^/   /'
else
    echo "   ⚠️  Configuração do Abseil NÃO encontrada no Podfile"
fi
echo ""

echo "3️⃣ Verificando versão do Abseil instalado..."
if [ -f "Podfile.lock" ]; then
    ABSEIL_VERSION=$(grep "abseil/algorithm" Podfile.lock | head -1 | grep -o '([0-9.]*' | tr -d '(')
    if [ -n "$ABSEIL_VERSION" ]; then
        echo "   ✅ Abseil versão: $ABSEIL_VERSION"
    else
        echo "   ⚠️  Versão do Abseil não encontrada no Podfile.lock"
    fi
else
    echo "   ⚠️  Podfile.lock não encontrado"
fi
echo ""

echo "4️⃣ Verificando frameworks linkados..."
if grep -q "framework \"absl\"" Runner.xcodeproj/project.pbxproj; then
    echo "   ✅ Framework absl está linkado"
else
    echo "   ⚠️  Framework absl pode não estar linkado corretamente"
fi
echo ""

echo "5️⃣ Verificando DerivedData..."
DD_SIZE=$(du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk '{print $1}')
if [ -n "$DD_SIZE" ]; then
    echo "   📊 Tamanho do DerivedData: $DD_SIZE"
    echo "   💡 Se o build falhar, execute: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
else
    echo "   ✅ DerivedData vazio ou não existe"
fi
echo ""

echo "===================================="
echo "✅ Verificação concluída"
echo "===================================="
echo ""
echo "📋 Próximos passos para testar:"
echo ""
echo "1. Feche completamente o Xcode (se estiver aberto)"
echo "2. Abra o workspace: open Runner.xcworkspace"
echo "3. No Xcode:"
echo "   - Product → Clean Build Folder (Shift + Cmd + K)"
echo "   - Product → Build (Cmd + B)"
echo ""
echo "4. Se ainda houver erros, execute:"
echo "   flutter clean"
echo "   cd ios"
echo "   pod install"
echo ""

