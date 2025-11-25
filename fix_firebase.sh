#!/bin/bash

# Script para corrigir problemas de inicialização do Firebase
# Execute este script quando o Firebase não conseguir se conectar

echo "🔧 Corrigindo problemas do Firebase..."
echo ""

# 1. Limpar build
echo "📦 Limpando build..."
flutter clean

# 2. Reinstalar dependências
echo "📥 Reinstalando dependências Flutter..."
flutter pub get

# 3. Reinstalar pods do iOS
if [ -d "ios" ]; then
    echo "🍎 Reinstalando CocoaPods para iOS..."
    cd ios
    pod deintegrate 2>/dev/null || true
    pod install
    cd ..
fi

# 4. Reinstalar pods do macOS
if [ -d "macos" ]; then
    echo "🖥️  Reinstalando CocoaPods para macOS..."
    cd macos
    pod deintegrate 2>/dev/null || true
    pod install
    cd ..
fi

echo ""
echo "✅ Concluído! Agora execute: flutter run"
echo ""
echo "⚠️  IMPORTANTE: Pare completamente o app antes de executar flutter run"
echo "   Não use hot reload/restart - o app precisa ser reconstruído do zero"

