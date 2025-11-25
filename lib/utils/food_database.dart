import '../models/food_item.dart';

class FoodDatabase {
  // Base de dados mockada de alimentos
  // Em produção, isso viria de um banco de dados ou API
  static final List<FoodItem> _foods = [
    // Carboidratos
    FoodItem(
      id: '1',
      name: 'Arroz Branco (cozido)',
      category: 'Carboidratos',
      calories: 130,
      protein: 2.7,
      carbs: 28,
      fats: 0.3,
    ),
    FoodItem(
      id: '2',
      name: 'Arroz Integral (cozido)',
      category: 'Carboidratos',
      calories: 111,
      protein: 2.6,
      carbs: 23,
      fats: 0.9,
    ),
    FoodItem(
      id: '3',
      name: 'Batata Doce (cozida)',
      category: 'Carboidratos',
      calories: 86,
      protein: 1.6,
      carbs: 20,
      fats: 0.1,
    ),
    FoodItem(
      id: '4',
      name: 'Macarrão (cozido)',
      category: 'Carboidratos',
      calories: 131,
      protein: 5,
      carbs: 25,
      fats: 1.1,
    ),
    FoodItem(
      id: '5',
      name: 'Pão Integral',
      category: 'Carboidratos',
      calories: 247,
      protein: 13,
      carbs: 41,
      fats: 4.2,
    ),
    // Proteínas
    FoodItem(
      id: '6',
      name: 'Peito de Frango (grelhado)',
      category: 'Proteínas',
      calories: 165,
      protein: 31,
      carbs: 0,
      fats: 3.6,
    ),
    FoodItem(
      id: '7',
      name: 'Ovo (cozido)',
      category: 'Proteínas',
      calories: 155,
      protein: 13,
      carbs: 1.1,
      fats: 11,
    ),
    FoodItem(
      id: '8',
      name: 'Salmão (grelhado)',
      category: 'Proteínas',
      calories: 206,
      protein: 22,
      carbs: 0,
      fats: 12,
    ),
    FoodItem(
      id: '9',
      name: 'Carne Bovina (magra)',
      category: 'Proteínas',
      calories: 250,
      protein: 26,
      carbs: 0,
      fats: 17,
    ),
    FoodItem(
      id: '10',
      name: 'Atum (enlatado em água)',
      category: 'Proteínas',
      calories: 116,
      protein: 26,
      carbs: 0,
      fats: 0.8,
    ),
    // Frutas
    FoodItem(
      id: '11',
      name: 'Banana',
      category: 'Frutas',
      calories: 89,
      protein: 1.1,
      carbs: 23,
      fats: 0.3,
    ),
    FoodItem(
      id: '12',
      name: 'Maçã',
      category: 'Frutas',
      calories: 52,
      protein: 0.3,
      carbs: 14,
      fats: 0.2,
    ),
    FoodItem(
      id: '13',
      name: 'Abacate',
      category: 'Frutas',
      calories: 160,
      protein: 2,
      carbs: 9,
      fats: 15,
    ),
    // Vegetais
    FoodItem(
      id: '14',
      name: 'Brócolis (cozido)',
      category: 'Vegetais',
      calories: 35,
      protein: 2.8,
      carbs: 7,
      fats: 0.4,
    ),
    FoodItem(
      id: '15',
      name: 'Espinafre (cozido)',
      category: 'Vegetais',
      calories: 23,
      protein: 3,
      carbs: 3.8,
      fats: 0.3,
    ),
    // Laticínios
    FoodItem(
      id: '16',
      name: 'Leite Desnatado',
      category: 'Laticínios',
      calories: 34,
      protein: 3.4,
      carbs: 5,
      fats: 0.1,
    ),
    FoodItem(
      id: '17',
      name: 'Iogurte Natural',
      category: 'Laticínios',
      calories: 59,
      protein: 10,
      carbs: 3.6,
      fats: 0.4,
    ),
    FoodItem(
      id: '18',
      name: 'Queijo Cottage',
      category: 'Laticínios',
      calories: 98,
      protein: 11,
      carbs: 3.4,
      fats: 4.3,
    ),
    // Gorduras
    FoodItem(
      id: '19',
      name: 'Azeite de Oliva',
      category: 'Gorduras',
      calories: 884,
      protein: 0,
      carbs: 0,
      fats: 100,
    ),
    FoodItem(
      id: '20',
      name: 'Abacate',
      category: 'Gorduras',
      calories: 160,
      protein: 2,
      carbs: 9,
      fats: 15,
    ),
  ];

  // Buscar alimentos por nome
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      return food.name.toLowerCase().contains(lowerQuery) ||
          food.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Obter todos os alimentos
  static List<FoodItem> getAllFoods() {
    return List.from(_foods);
  }

  // Obter alimento por ID
  static FoodItem? getFoodById(String id) {
    try {
      return _foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }
}

