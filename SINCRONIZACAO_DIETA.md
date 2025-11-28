# Sincronização de Dieta Selecionada

## O que foi implementado?

Agora as informações de **calorias e macronutrientes** na **tela inicial (Home)** são atualizadas automaticamente conforme a **dieta selecionada na aba de refeições**.

## Como funciona?

### 1. **Salvamento da Dieta Selecionada**
   - Quando o usuário seleciona uma dieta diferente no menu da aba "Refeições", essa escolha é salva no Firestore
   - O ID da dieta selecionada fica armazenado em: `/users/{userId}/settings/user_settings`

### 2. **Sincronização em Tempo Real**
   - Ambas as telas (Home e Refeições) agora usam **streams** para detectar mudanças na dieta selecionada
   - Quando a dieta é alterada na aba de Refeições, a tela Home é atualizada automaticamente
   - Não é necessário reiniciar o app ou voltar e entrar novamente na tela

### 3. **Carregamento Inicial**
   - Ao abrir o app, o sistema verifica qual dieta está atualmente selecionada
   - Se não houver nenhuma selecionada, usa a dieta mais recente automaticamente
   - As metas de calorias e macronutrientes são carregadas dessa dieta selecionada

## Alterações realizadas

### 📄 `firestore_service.dart`
Adicionados 3 novos métodos:

1. **`saveSelectedMealPlanId()`** - Salva a dieta selecionada
2. **`getSelectedMealPlanId()`** - Busca a dieta selecionada
3. **`streamSelectedMealPlanId()`** - Stream para sincronização em tempo real

### 📄 `home_screen.dart`
- Alterado `_loadMealPlan()` para carregar a dieta selecionada (não mais apenas a mais recente)
- Adicionado `_startSelectedPlanStream()` para detectar mudanças na dieta selecionada
- Adicionado `_selectedPlanSubscription` para gerenciar o stream
- Quando a dieta muda, os dados são recarregados automaticamente

### 📄 `meals_list_screen.dart`
- Alterado `_loadMealPlans()` para carregar a dieta previamente selecionada
- Modificado o menu de seleção de dieta para:
  - Salvar a escolha no Firestore quando o usuário seleciona uma dieta
  - Mostrar um ✓ (check) na dieta atualmente selecionada
  - Destacar visualmente a dieta selecionada em negrito e verde
  - Mostrar um snackbar confirmando a mudança

## Fluxo de Uso

1. **Usuário entra no app** → Tela Home carrega a última dieta selecionada
2. **Usuário vai para aba "Refeições"** → Mostra as refeições da mesma dieta
3. **Usuário seleciona outra dieta no menu** → Dieta é salva no Firestore
4. **Stream detecta a mudança** → Tela Home atualiza automaticamente
5. **Usuário volta para Home** → Vê as calorias e macros da nova dieta

## Benefícios

✅ **Sincronização automática** entre as telas
✅ **Persistência** da escolha do usuário
✅ **Atualização em tempo real** sem precisar recarregar
✅ **Interface intuitiva** com indicador visual da dieta selecionada
✅ **Feedback ao usuário** através de snackbar
✅ **Consistência** dos dados em todo o app

## Estrutura no Firestore

```
users/
  └── {userId}/
      └── settings/
          └── user_settings/
              ├── selectedMealPlanId: "abc123"  ← ID da dieta selecionada
              ├── waterGoal: 2.5
              └── updatedAt: Timestamp
```

## Exemplo Visual

**Antes:**
- Home mostra sempre a dieta mais recente (independente da seleção)
- Refeições pode estar em uma dieta diferente
- ❌ Dados inconsistentes

**Depois:**
- Home mostra a dieta selecionada pelo usuário
- Refeições mostra a mesma dieta
- ✅ Dados sempre sincronizados
- ✅ Mudanças refletidas automaticamente

---

**Data de implementação:** 28 de novembro de 2025
**Versão:** 1.0

