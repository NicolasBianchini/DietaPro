class FoodItem {
  final String id;
  final String name;
  final String category; // Ex: "Carboidratos", "Proteínas", "Gorduras", etc.
  final double calories; // por 100g
  final double protein; // gramas por 100g
  final double carbs; // gramas por 100g
  final double fats; // gramas por 100g
  final String? unit; // "g", "ml", "unidade", etc.

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.unit,
  });

  // Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'unit': unit,
    };
  }

  // Criar a partir de Map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fats: (map['fats'] ?? 0).toDouble(),
      unit: map['unit'],
    );
  }
}

// Classe para representar um alimento adicionado a uma refeição
class MealFood {
  final FoodItem food;
  final double quantity; // quantidade em gramas ou unidade
  final String mealType; // "breakfast", "lunch", "dinner", "snack"

  MealFood({
    required this.food,
    required this.quantity,
    required this.mealType,
  });

  // Calcular valores nutricionais baseado na quantidade
  double get totalCalories => (food.calories * quantity) / 100;
  double get totalProtein => (food.protein * quantity) / 100;
  double get totalCarbs => (food.carbs * quantity) / 100;
  double get totalFats => (food.fats * quantity) / 100;

  Map<String, dynamic> toMap() {
    return {
      'food': food.toMap(),
      'quantity': quantity,
      'mealType': mealType,
    };
  }

  factory MealFood.fromMap(Map<String, dynamic> map) {
    return MealFood(
      food: FoodItem.fromMap(map['food']),
      quantity: (map['quantity'] ?? 0).toDouble(),
      mealType: map['mealType'] ?? '',
    );
  }
}

