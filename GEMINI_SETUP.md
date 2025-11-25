# Configuração da API do Gemini

Este documento explica como configurar a chave API do Google Gemini para usar a IA no DietaPro.

## Passo 1: Obter a Chave API

1. Acesse o [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Faça login com sua conta Google
3. Clique em "Create API Key" ou "Get API Key"
4. Copie a chave API gerada

## Passo 2: Configurar no Projeto

1. Na raiz do projeto, crie um arquivo chamado `.env`
2. Adicione a seguinte linha no arquivo:

```
GEMINI_API_KEY=sua_chave_api_aqui
```

Substitua `sua_chave_api_aqui` pela chave API que você copiou.

## Passo 3: Adicionar ao .gitignore

Certifique-se de que o arquivo `.env` está no `.gitignore` para não commitar sua chave API:

```
.env
```

## Exemplo de Uso

```dart
import 'package:dietapro/services/gemini_service.dart';

// Inicializar o serviço
await GeminiService.instance.initialize();

// Gerar um plano alimentar
final mealPlan = await GeminiService.instance.generateMealPlan(
  userProfile: 'Usuário de 30 anos, objetivo: perder peso',
  dailyCalories: 2000,
  protein: 150,
  carbs: 200,
  fats: 65,
  mealsPerDay: 5,
);

// Gerar sugestões de alimentos
final suggestions = await GeminiService.instance.suggestFoods(
  mealType: 'Café da Manhã',
  targetCalories: 400,
  targetProtein: 20,
);

// Gerar dicas nutricionais
final tips = await GeminiService.instance.generateNutritionTips(
  userGoal: 'Perder peso',
);
```

## Métodos Disponíveis

### `generateMealPlan()`
Gera um plano alimentar completo baseado no perfil do usuário e necessidades nutricionais.

### `suggestFoods()`
Sugere alimentos específicos para uma refeição com base em critérios nutricionais.

### `generateNutritionTips()`
Gera dicas nutricionais personalizadas baseadas no objetivo do usuário.

### `generateResponse()`
Método genérico para gerar respostas do Gemini com qualquer prompt customizado.

## Segurança

⚠️ **IMPORTANTE**: Nunca commite o arquivo `.env` com sua chave API real no controle de versão!

A chave API deve ser mantida em segredo e não deve ser compartilhada publicamente.

