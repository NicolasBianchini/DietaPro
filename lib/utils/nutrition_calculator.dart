import '../models/user_profile.dart';

class NutritionCalculator {
  // Calcular TMB (Taxa Metabólica Basal) usando a fórmula de Mifflin-St Jeor
  static double calculateBMR({
    required double weight, // em kg
    required double height, // em cm
    required int age,
    required Gender gender,
  }) {
    // Fórmula de Mifflin-St Jeor
    // Homens: TMB = 10 × peso(kg) + 6,25 × altura(cm) - 5 × idade(anos) + 5
    // Mulheres: TMB = 10 × peso(kg) + 6,25 × altura(cm) - 5 × idade(anos) - 161
    
    final baseBMR = (10 * weight) + (6.25 * height) - (5 * age);
    
    switch (gender) {
      case Gender.male:
        return baseBMR + 5;
      case Gender.female:
        return baseBMR - 161;
      case Gender.other:
        // Média entre homem e mulher
        return baseBMR - 78;
    }
  }

  // Calcular TEE (Total Energy Expenditure) - gasto energético total
  static double calculateTEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    // Fatores de atividade:
    // Sedentário: 1.2
    // Leve: 1.375
    // Moderado: 1.55
    // Ativo: 1.725
    // Muito ativo: 1.9
    
    double activityFactor;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        activityFactor = 1.2;
        break;
      case ActivityLevel.light:
        activityFactor = 1.375;
        break;
      case ActivityLevel.moderate:
        activityFactor = 1.55;
        break;
      case ActivityLevel.active:
        activityFactor = 1.725;
        break;
      case ActivityLevel.veryActive:
        activityFactor = 1.9;
        break;
    }
    
    return bmr * activityFactor;
  }

  // Calcular calorias diárias baseado no objetivo
  static double calculateDailyCalories({
    required double tee,
    required Goal goal,
  }) {
    // Ajustes baseados no objetivo:
    // Perder peso: -500 a -750 kcal (déficit de 15-20%)
    // Ganhar massa: +300 a +500 kcal (superávit de 10-15%)
    // Manutenção: TEE (sem ajuste)
    // Comer melhor: TEE (sem ajuste, mas pode ter pequeno déficit)
    
    switch (goal) {
      case Goal.loseWeight:
        // Déficit de 20% para perda de peso
        return tee * 0.8;
      case Goal.gainWeight:
        // Superávit de 20% para ganho de peso
        return tee * 1.2;
      case Goal.gainMuscle:
        // Superávit de 15% para ganho de massa
        return tee * 1.15;
      case Goal.maintain:
        // Manutenção: TEE
        return tee;
      case Goal.eatBetter:
        // Pequeno déficit de 5% para melhorar hábitos
        return tee * 0.95;
    }
  }

  // Calcular distribuição de macronutrientes
  static Map<String, double> calculateMacros({
    required double calories,
    required Goal goal,
  }) {
    double proteinPercent;
    double carbsPercent;
    double fatsPercent;
    
    switch (goal) {
      case Goal.loseWeight:
        // Dieta com mais proteína para preservar massa muscular
        proteinPercent = 0.30; // 30%
        carbsPercent = 0.40;   // 40%
        fatsPercent = 0.30;     // 30%
        break;
      case Goal.gainWeight:
        // Dieta com mais carboidratos e gorduras para ganho de peso
        proteinPercent = 0.20; // 20%
        carbsPercent = 0.50;   // 50%
        fatsPercent = 0.30;     // 30%
        break;
      case Goal.gainMuscle:
        // Dieta com mais carboidratos para energia e proteína para síntese
        proteinPercent = 0.25; // 25%
        carbsPercent = 0.45;   // 45%
        fatsPercent = 0.30;     // 30%
        break;
      case Goal.maintain:
        // Distribuição balanceada
        proteinPercent = 0.25; // 25%
        carbsPercent = 0.45;   // 45%
        fatsPercent = 0.30;     // 30%
        break;
      case Goal.eatBetter:
        // Distribuição balanceada similar à manutenção
        proteinPercent = 0.25; // 25%
        carbsPercent = 0.45;   // 45%
        fatsPercent = 0.30;     // 30%
        break;
    }
    
    // Calcular gramas:
    // Proteína: 4 kcal/g
    // Carboidratos: 4 kcal/g
    // Gorduras: 9 kcal/g
    
    final proteinCalories = calories * proteinPercent;
    final carbsCalories = calories * carbsPercent;
    final fatsCalories = calories * fatsPercent;
    
    return {
      'protein': proteinCalories / 4,  // gramas
      'carbs': carbsCalories / 4,       // gramas
      'fats': fatsCalories / 9,          // gramas
    };
  }

  // Calcular tudo de uma vez
  static Map<String, dynamic> calculateNutrition({
    required double weight,
    required double height,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required Goal goal,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    
    final tee = calculateTEE(
      bmr: bmr,
      activityLevel: activityLevel,
    );
    
    final calories = calculateDailyCalories(
      tee: tee,
      goal: goal,
    );
    
    final macros = calculateMacros(
      calories: calories,
      goal: goal,
    );
    
    return {
      'bmr': bmr,
      'tee': tee,
      'calories': calories,
      'protein': macros['protein']!,
      'carbs': macros['carbs']!,
      'fats': macros['fats']!,
    };
  }
}

