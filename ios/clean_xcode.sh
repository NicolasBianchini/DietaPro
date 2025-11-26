#!/bin/bash

# Script para limpar o DerivedData do Xcode e resolver problemas de build

echo "🧹 Limpando DerivedData do Xcode..."

# Limpar DerivedData específico do projeto
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Limpar build do Flutter
cd ..
flutter clean

# Reinstalar dependências
echo "📦 Reinstalando dependências..."
flutter pub get

# Reinstalar pods
cd ios
pod deintegrate
pod install

echo "✅ Limpeza concluída!"
echo ""
echo "Próximos passos:"
echo "1. Feche o Xcode completamente"
echo "2. Abra o projeto novamente: open ios/Runner.xcworkspace"
echo "3. Tente fazer o build novamente"

