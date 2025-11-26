# 🧹 Como Limpar DerivedData de Outros Projetos

## 📊 Situação Atual

O DerivedData tem **2.3GB** no total:
- **Runner-akawtphvhzktmhfrotucdzxtqplt**: 1.4GB (outro projeto Runner)
- **ModuleCache.noindex**: 943MB (cache compartilhado)
- **Outros projetos Runner**: ~100MB
- **Caches diversos**: ~50MB

## 🎯 Opções de Limpeza

### Opção 1: Script Interativo (Recomendado)

Execute o script que criei:

```bash
cd ios
./clean_derived_data.sh
```

O script oferece 5 opções:
1. Limpar apenas Runner (dietapro) - Seguro
2. Limpar outros projetos - Libera ~2.2GB
3. Limpar TUDO - Libera ~2.3GB
4. Ver tamanho atual
5. Cancelar

### Opção 2: Limpar Manualmente (Linha de Comando)

#### A) Limpar apenas outros projetos Runner (mantém dietapro):
```bash
# Remove todos os Runner exceto os do dietapro atual
find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -type d -name "Runner-*" ! -name "Runner-hirqgixdxanmquawryoqurfigaug" -exec rm -rf {} \;
```

#### B) Limpar ModuleCache (943MB):
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
```
⚠️ Isso vai fazer o próximo build de qualquer projeto ser mais lento (recompila módulos)

#### C) Limpar TUDO (mais agressivo):
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
⚠️ Isso limpa TUDO, incluindo caches compartilhados. O próximo build de qualquer projeto será muito mais lento.

#### D) Limpar apenas projetos específicos:
```bash
# Exemplo: remover apenas o Runner-akawtphvhzktmhfrotucdzxtqplt (1.4GB)
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-akawtphvhzktmhfrotucdzxtqplt
```

## ⚠️ Avisos Importantes

1. **ModuleCache**: Se limpar, o próximo build de qualquer projeto será mais lento (recompila módulos)
2. **Projetos ativos**: Se você tem outros projetos Xcode abertos, feche antes de limpar
3. **Primeiro build**: Após limpar, o primeiro build será sempre mais lento

## 🚀 Recomendação

Para liberar espaço sem afetar muito a performance:

```bash
# Limpar apenas o projeto grande (1.4GB)
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-akawtphvhzktmhfrotucdzxtqplt

# Limpar outros projetos Runner antigos
find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -type d -name "Runner-*" ! -name "Runner-hirqgixdxanmquawryoqurfigaug" -exec rm -rf {} \;
```

Isso libera ~1.5GB mantendo o ModuleCache (que acelera builds futuros).

## 📝 Verificar Tamanho Antes/Depois

```bash
# Antes
du -sh ~/Library/Developer/Xcode/DerivedData

# Depois
du -sh ~/Library/Developer/Xcode/DerivedData
```

