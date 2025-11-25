#!/bin/bash

# Script para limpar espaço em disco para builds do Flutter/Firebase

echo "🧹 Limpando espaço em disco..."
echo ""

# 1. Limpar build do Flutter
echo "📦 Limpando build do Flutter..."
cd "$(dirname "$0")"
flutter clean
rm -rf build/
echo "✅ Build do Flutter limpo"

# 2. Limpar cache do Xcode DerivedData
echo "🍎 Limpando cache do Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Cache do Xcode limpo"

# 3. Limpar cache do CocoaPods
echo "📱 Limpando cache do CocoaPods..."
if [ -d "ios" ]; then
    cd ios
    pod cache clean --all 2>/dev/null || true
    rm -rf Pods/
    rm -rf Podfile.lock
    cd ..
fi

if [ -d "macos" ]; then
    cd macos
    pod cache clean --all 2>/dev/null || true
    rm -rf Pods/
    rm -rf Podfile.lock
    cd ..
fi
echo "✅ Cache do CocoaPods limpo"

# 4. Limpar cache do Flutter
echo "🔄 Limpando cache do Flutter..."
flutter pub cache clean 2>/dev/null || true
echo "✅ Cache do Flutter limpo"

# 5. Verificar espaço liberado
echo ""
echo "📊 Espaço em disco:"
df -h / | tail -1

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "💡 Próximos passos:"
echo "   1. flutter pub get"
echo "   2. cd ios && pod install && cd .."
echo "   3. cd macos && pod install && cd .."
echo "   4. flutter run -d macos"

