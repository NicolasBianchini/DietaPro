#!/bin/bash

echo "🔧 Corrigindo Erros de Linkagem do Abseil"
echo "=========================================="
echo ""

# Limpar DerivedData
echo "1️⃣ Limpando DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ DerivedData limpo"
echo ""

# Limpar build do Flutter
echo "2️⃣ Limpando build do Flutter..."
cd ..
flutter clean
echo "✅ Build limpo"
echo ""

# Regenerar arquivos
echo "3️⃣ Regenerando arquivos Flutter..."
flutter pub get
echo "✅ Arquivos regenerados"
echo ""

# Reinstalar pods
echo "4️⃣ Reinstalando CocoaPods..."
cd ios
pod deintegrate
pod install --repo-update
echo "✅ Pods reinstalados"
echo ""

echo "=========================================="
echo "✅ Correção concluída!"
echo "=========================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Feche o Xcode completamente"
echo "2. Abra o workspace: open ios/Runner.xcworkspace"
echo "3. No Xcode: Product → Clean Build Folder (Shift + Cmd + K)"
echo "4. Tente compilar novamente"
echo ""
echo "💡 Se o erro persistir, verifique:"
echo "   - View → Navigators → Show Report Navigator (Cmd + 9)"
echo "   - Veja os logs detalhados do erro de linkagem"
echo ""

