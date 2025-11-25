# Guia de Uso do Firestore

Este documento explica como usar o FirestoreService para gerenciar dados no DietaPro.

## Estrutura do Banco de Dados

```
users/
  {userId}/
    - Perfil do usuário
    daily_meals/
      {date}/
        - Refeições do dia
    daily_nutrition/
      {date}/
        - Registro nutricional do dia
    custom_foods/
      {foodId}/
        - Alimentos customizados do usuário

meal_plans/
  {mealPlanId}/
    - Planos alimentares criados
```

## Exemplos de Uso

### 1. Salvar Perfil do Usuário

```dart
import 'package:dietapro/services/firestore_service.dart';
import 'package:dietapro/models/user_profile.dart';

final firestore = FirestoreService();

// Criar perfil
final userProfile = UserProfile(
  email: 'usuario@exemplo.com',
  name: 'João Silva',
  gender: Gender.male,
  dateOfBirth: DateTime(1990, 1, 1),
  height: 175,
  weight: 70,
  activityLevel: ActivityLevel.moderate,
  goal: Goal.loseWeight,
);

// Salvar no Firestore
final userId = await firestore.saveUserProfile(userProfile);
print('Perfil salvo com ID: $userId');
```

### 2. Buscar Perfil do Usuário

```dart
// Por ID
final profile = await firestore.getUserProfile(userId);

// Por email
final profile = await firestore.getUserProfileByEmail('usuario@exemplo.com');
```

### 3. Salvar Plano Alimentar

```dart
final mealPlanId = await firestore.saveMealPlan(
  userId: userId,
  dietName: 'Dieta para Emagrecimento',
  description: 'Plano personalizado',
  nutritionData: {
    'calories': 2000,
    'protein': 150,
    'carbs': 200,
    'fats': 65,
  },
  meals: {
    'breakfast': [mealFood1, mealFood2],
    'lunch': [mealFood3],
    // ...
  },
);
```

### 4. Buscar Planos Alimentares

```dart
final mealPlans = await firestore.getUserMealPlans(userId);
for (var plan in mealPlans) {
  print('Plano: ${plan['dietName']}');
}
```

### 5. Salvar Refeições do Dia

```dart
await firestore.saveDailyMeals(
  userId: userId,
  date: DateTime.now(),
  meals: [
    {
      'id': '1',
      'name': 'Café da Manhã',
      'time': '08:00',
      'calories': 350,
      'isCompleted': true,
      // ...
    },
  ],
);
```

### 6. Buscar Refeições do Dia

```dart
final meals = await firestore.getDailyMeals(
  userId: userId,
  date: DateTime.now(),
);
```

### 7. Salvar Registro Nutricional

```dart
await firestore.saveDailyNutrition(
  userId: userId,
  date: DateTime.now(),
  caloriesConsumed: 1200,
  protein: 80,
  carbs: 150,
  fats: 60,
);
```

### 8. Usar Streams (Atualizações em Tempo Real)

```dart
// Escutar mudanças nas refeições do dia
firestore.streamDailyMeals(
  userId: userId,
  date: DateTime.now(),
).listen((meals) {
  print('Refeições atualizadas: ${meals.length}');
});

// Escutar mudanças no registro nutricional
firestore.streamDailyNutrition(
  userId: userId,
  date: DateTime.now(),
).listen((nutrition) {
  if (nutrition != null) {
    print('Calorias: ${nutrition['caloriesConsumed']}');
  }
});
```

## Regras de Segurança do Firestore

Certifique-se de configurar as regras de segurança no Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem ler/escrever apenas seus próprios dados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /daily_meals/{date} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /daily_nutrition/{date} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /custom_foods/{foodId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Planos alimentares
    match /meal_plans/{mealPlanId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

## Próximos Passos

1. Implementar autenticação do Firebase (Firebase Auth)
2. Integrar FirestoreService nas telas do app
3. Adicionar cache local para melhor performance
4. Implementar sincronização offline

