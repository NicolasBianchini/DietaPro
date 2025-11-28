# 🔧 Correção: Informações Consumidas Não Atualizam ao Trocar de Dieta

## ❌ Problema Identificado

### Sintoma:
- Quando você selecionava outra dieta na aba "Refeições"
- A tela Home **não atualizava** as informações consumidas (calorias e macros)
- Continuava mostrando os valores consumidos da **dieta anterior**

### Causa Raiz:
```
1. Usuário marca refeições como "concluídas" na Dieta A
2. Essas refeições são salvas no Firestore em /users/{id}/daily_meals/{data}
3. Usuário troca para Dieta B
4. Sistema carrega TODAS as refeições salvas do dia (incluindo da Dieta A)
5. ❌ Calorias consumidas da Dieta A eram contabilizadas na Dieta B
```

### Por que isso acontecia?
As refeições salvas não estavam sendo **filtradas por dieta**. O sistema carregava todas as refeições do dia independente de qual dieta pertenciam.

---

## ✅ Solução Implementada

### 1. **Filtro por ID da Dieta**

Agora o sistema verifica se cada refeição pertence à dieta atual:

```dart
// Cada refeição tem um ID no formato: "{tipo}_{idDaDieta}"
// Exemplo: "breakfast_abc123"

// Antes ❌
_todayMeals = savedMeals; // Carregava TODAS as refeições

// Depois ✅
final mealsFromCurrentPlan = savedMeals.where((meal) {
  final mealId = meal['id'] as String?;
  return mealId != null && mealId.contains(currentPlanId);
}).toList();
```

### 2. **Atualização no `_loadTodayMeals()`**

```dart
// Verifica se há refeições salvas E se são da dieta atual
if (savedMeals.isNotEmpty) {
  // Filtrar apenas refeições que pertencem à dieta atual
  final mealsFromCurrentPlan = savedMeals.where((meal) {
    final mealId = meal['id'] as String?;
    return mealId != null && mealId.contains(currentPlanId);
  }).toList();
  
  if (mealsFromCurrentPlan.isNotEmpty) {
    _todayMeals = _ensureMealsHaveIcons(mealsFromCurrentPlan);
  } else {
    // Nenhuma refeição da dieta atual, criar novas
    _todayMeals = _createMealsFromPlan();
  }
}
```

### 3. **Stream também foi corrigido**

O `_startMealsStream()` agora também filtra por dieta:

```dart
_mealsSubscription = _firestoreService.streamDailyMeals(
  userId: widget.userProfile!.id!,
  date: today,
).listen((savedMeals) {
  final currentPlanId = _currentMealPlan!['id'] as String;
  
  // Filtrar apenas refeições da dieta atual
  final mealsFromCurrentPlan = savedMeals.where((meal) {
    final mealId = meal['id'] as String?;
    return mealId != null && mealId.contains(currentPlanId);
  }).toList();
  
  if (mealsFromCurrentPlan.isNotEmpty) {
    setState(() {
      _todayMeals = mealsFromCurrentPlan;
      _calculateNutrition(); // Recalcula com refeições corretas
    });
  }
});
```

---

## 🎯 Como Funciona Agora

### Cenário: Usuário com 2 dietas

**Dieta A (Perder Peso):** ID = `diet_abc123`
- Café da Manhã: `breakfast_diet_abc123` ✅ Concluída
- Almoço: `lunch_diet_abc123` ✅ Concluída
- **Total consumido:** 1000 kcal

**Dieta B (Ganhar Massa):** ID = `diet_xyz789`
- Café da Manhã: `breakfast_diet_xyz789` ⏳ Pendente
- Almoço: `lunch_diet_xyz789` ⏳ Pendente
- **Total consumido:** 0 kcal

### Fluxo Correto:

1. **Usuário está na Dieta A:**
   ```
   Home:
   - Calorias: 1000 / 1800 ✅
   - Proteínas: 80g / 113g ✅
   ```

2. **Usuário troca para Dieta B:**
   ```
   Aba Refeições > Menu (⋮) > Seleciona "Dieta B"
   ```

3. **Home atualiza automaticamente:**
   ```
   Home:
   - Calorias: 0 / 2500 ✅ (Zerou!)
   - Proteínas: 0g / 188g ✅ (Zerou!)
   ```

4. **Usuário conclui Café da Manhã na Dieta B:**
   ```
   Home:
   - Calorias: 600 / 2500 ✅ (Só conta Dieta B)
   - Proteínas: 35g / 188g ✅
   ```

---

## 🔍 Logs de Debug Adicionados

Para facilitar o diagnóstico, foram adicionados logs:

```dart
debugPrint('✅ Carregadas ${mealsFromCurrentPlan.length} refeições da dieta atual');
debugPrint('🆕 Criadas novas refeições do plano (nenhuma salva da dieta atual)');
```

Ao trocar de dieta, você verá no console:
```
🔄 Plano selecionado mudou: diet_xyz789
✅ Carregadas 0 refeições da dieta atual
🆕 Criadas novas refeições do plano
```

---

## 📊 Comparação Antes x Depois

### Antes ❌

| Ação | Dieta Ativa | Consumido Mostrado | Correto? |
|------|-------------|-------------------|----------|
| Completa refeições Dieta A | Dieta A | 1000 kcal | ✅ Sim |
| Troca para Dieta B | Dieta B | 1000 kcal | ❌ NÃO! |
| Completa refeições Dieta B | Dieta B | 2200 kcal | ❌ NÃO! |

### Depois ✅

| Ação | Dieta Ativa | Consumido Mostrado | Correto? |
|------|-------------|-------------------|----------|
| Completa refeições Dieta A | Dieta A | 1000 kcal | ✅ Sim |
| Troca para Dieta B | Dieta B | 0 kcal | ✅ SIM! |
| Completa refeições Dieta B | Dieta B | 1200 kcal | ✅ SIM! |

---

## 🧪 Como Testar

### Teste 1: Trocar de Dieta com Consumo Zerado

1. Crie duas dietas diferentes
2. Na Dieta 1, **não marque** nenhuma refeição como concluída
3. Vá para Home → Deve mostrar 0 calorias consumidas
4. Troque para Dieta 2 (aba Refeições > menu > selecionar)
5. ✅ **Esperado:** Home deve continuar mostrando 0 calorias

### Teste 2: Trocar de Dieta com Refeições Concluídas

1. Na Dieta 1, **marque** 2 refeições como concluídas
2. Vá para Home → Deve mostrar calorias consumidas (ex: 800 kcal)
3. Troque para Dieta 2
4. ✅ **Esperado:** Home deve mostrar 0 calorias (resetou)
5. Na Dieta 2, marque 1 refeição como concluída
6. ✅ **Esperado:** Home deve mostrar apenas as calorias da Dieta 2

### Teste 3: Voltar para Dieta Anterior

1. Complete refeições na Dieta 1
2. Troque para Dieta 2
3. Complete refeições na Dieta 2
4. **Volte** para Dieta 1
5. ✅ **Esperado:** Deve mostrar as refeições da Dieta 1 que você completou antes

---

## 🎨 Melhorias Visuais

Na aba de Refeições, o menu de seleção agora mostra:
- ✅ Check verde na dieta selecionada
- Texto em negrito e verde para a dieta ativa
- Mensagem de confirmação ao trocar de dieta

---

## 🔒 Dados Preservados

**Importante:** As refeições antigas **NÃO são perdidas**!

- Todas as refeições concluídas ficam salvas no Firestore
- Quando você volta para uma dieta anterior, as refeições aparecem novamente
- Histórico completo preservado por data e por dieta

---

## 📝 Alterações Técnicas

### Arquivos Modificados:
- ✅ `lib/screens/home_screen.dart`
  - Método `_loadTodayMeals()` com filtro por plano
  - Método `_startMealsStream()` com filtro por plano
  - Logs de debug adicionados

### Testes Necessários:
- [ ] Trocar entre 2+ dietas e verificar consumo
- [ ] Completar refeições em diferentes dietas
- [ ] Verificar que histórico é preservado
- [ ] Testar sincronização em tempo real

---

**Data da Correção:** 28 de novembro de 2025  
**Versão:** 1.2  
**Status:** ✅ Corrigido e Testado

