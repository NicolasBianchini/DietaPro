#!/bin/bash

# Script para limpar DerivedData do Xcode
# Opções: apenas Runner, apenas outros projetos, ou tudo

echo "🧹 Limpeza de DerivedData do Xcode"
echo ""
echo "Escolha uma opção:"
echo "1) Limpar apenas DerivedData do Runner (dietapro) - SEGURO"
echo "2) Limpar DerivedData de outros projetos - Libera ~2.2GB"
echo "3) Limpar TUDO (incluindo ModuleCache, SymbolCache, etc) - Libera ~2.3GB"
echo "4) Ver tamanho atual antes de limpar"
echo "5) Cancelar"
echo ""
read -p "Digite o número da opção (1-5): " option

case $option in
  1)
    echo ""
    echo "🧹 Limpando DerivedData do Runner..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
    echo "✅ Limpeza concluída!"
    ;;
  2)
    echo ""
    echo "⚠️  ATENÇÃO: Isso vai limpar DerivedData de TODOS os outros projetos Xcode!"
    echo "    O próximo build de qualquer projeto será mais lento."
    read -p "Continuar? (s/N): " confirm
    if [[ $confirm == [sS] ]]; then
      echo ""
      echo "🧹 Limpando DerivedData de outros projetos..."
      # Mantém apenas Runner e caches compartilhados
      find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -type d ! -name "Runner-*" ! -name ".*" ! -name "DerivedData" -exec rm -rf {} \;
      echo "✅ Limpeza concluída!"
    else
      echo "❌ Operação cancelada."
    fi
    ;;
  3)
    echo ""
    echo "⚠️  ATENÇÃO: Isso vai limpar TUDO do DerivedData!"
    echo "    Incluindo ModuleCache, SymbolCache, e todos os projetos."
    echo "    O próximo build de QUALQUER projeto será muito mais lento."
    read -p "Tem certeza? (s/N): " confirm
    if [[ $confirm == [sS] ]]; then
      echo ""
      echo "🧹 Limpando TUDO do DerivedData..."
      rm -rf ~/Library/Developer/Xcode/DerivedData/*
      echo "✅ Limpeza completa concluída!"
    else
      echo "❌ Operação cancelada."
    fi
    ;;
  4)
    echo ""
    echo "📊 Tamanho atual do DerivedData:"
    echo ""
    du -sh ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null | sort -hr | head -10
    echo ""
    echo "Total:"
    du -sh ~/Library/Developer/Xcode/DerivedData
    ;;
  5)
    echo "❌ Operação cancelada."
    ;;
  *)
    echo "❌ Opção inválida."
    ;;
esac

