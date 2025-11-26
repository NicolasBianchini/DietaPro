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

# 2. Limpar cache do Xcode DerivedData (pode liberar vários GB)
echo "🍎 Limpando cache do Xcode DerivedData..."
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    BEFORE=$(du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | cut -f1 || echo "0")
rm -rf ~/Library/Developer/Xcode/DerivedData/*
    echo "✅ Cache do Xcode limpo (liberado: $BEFORE)"
else
    echo "⚠️  DerivedData não encontrado"
fi

# 2.1 Limpar cache do Xcode (outros caches)
echo "🍎 Limpando outros caches do Xcode..."
rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo "✅ Outros caches do Xcode limpos"

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

