#!/bin/bash

echo "🧪 Testando Build com Abseil"
echo "=============================="
echo ""

echo "1️⃣ Limpando build folder do Xcode..."
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner -configuration Debug
echo "✅ Clean concluído"
echo ""

echo "2️⃣ Verificando configuração do Abseil..."
pod spec which abseil
echo ""

echo "3️⃣ Iniciando build de teste (apenas para verificação)..."
echo "   Isso pode levar alguns minutos..."
echo ""

xcodebuild build \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -quiet \
  | grep -E 'Undefined symbol|error:|warning:|BUILD' \
  || echo "Build iniciado..."

echo ""
echo "=============================="
echo "✅ Teste concluído"
echo "=============================="
echo ""

