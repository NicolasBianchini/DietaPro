#!/bin/bash

# Script para limpar completamente o build do iOS e otimizar

echo "🧹 Limpando build do iOS..."

# Limpar DerivedData
echo "📦 Limpando DerivedData do Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Limpar build do Flutter
echo "📦 Limpando build do Flutter..."
cd ..
flutter clean

# Reinstalar dependências
echo "📦 Reinstalando dependências Flutter..."
flutter pub get

# Reinstalar pods
echo "📦 Reinstalando CocoaPods..."
cd ios
pod deintegrate
pod install

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "Próximos passos:"
echo "1. Feche o Xcode completamente"
echo "2. Abra: open ios/Runner.xcworkspace"
echo "3. Tente fazer o build novamente"
echo ""
echo "⚠️  O primeiro build após limpeza será mais lento (compila tudo)"
echo "    Builds subsequentes devem ser muito mais rápidos!"

