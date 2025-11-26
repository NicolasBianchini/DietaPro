import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER PROFILE ====================

  /// Salva ou atualiza o perfil do usuário
  /// Retorna o ID do documento salvo
  Future<String> saveUserProfile(UserProfile userProfile) async {
    try {
      final userData = userProfile.toMap();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      if (userData['createdAt'] == null) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      final userId = userProfile.id ?? _firestore.collection('users').doc().id;
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set(userData, SetOptions(merge: true));
      
      return userId;
    } catch (e) {
      throw Exception('Erro ao salvar perfil do usuário: $e');
    }
  }

  /// Busca o perfil do usuário por ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id; // Garantir que o ID está presente
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar perfil do usuário: $e');
    }
  }

  /// Busca o perfil do usuário por email
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id; // Garantir que o ID está presente
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar perfil por email: $e');
    }
  }

  // ==================== MEAL PLANS ====================

  /// Salva um plano alimentar
  Future<String> saveMealPlan({
    required String userId,
    required String dietName,
    String? description,
    required Map<String, dynamic> nutritionData,
    required Map<String, List<MealFood>> meals,
    DateTime? createdAt,
  }) async {
    try {
      final mealPlanRef = _firestore.collection('meal_plans').doc();
      
      // Converter MealFood para Map
      final mealsMap = <String, List<Map<String, dynamic>>>{};
      meals.forEach((mealType, mealFoods) {
        mealsMap[mealType] = mealFoods.map((mf) => mf.toMap()).toList();
      });

      final mealPlanData = {
        'id': mealPlanRef.id,
        'userId': userId,
        'dietName': dietName,
        'description': description ?? '',
        'nutritionData': nutritionData,
        'meals': mealsMap,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await mealPlanRef.set(mealPlanData);
      return mealPlanRef.id;
    } catch (e) {
      throw Exception('Erro ao salvar plano alimentar: $e');
    }
  }

  /// Busca todos os planos alimentares de um usuário
  Future<List<Map<String, dynamic>>> getUserMealPlans(String userId) async {
    try {
      // Remover orderBy para evitar necessidade de índice composto
      // Ordenaremos em memória depois
      final querySnapshot = await _firestore
          .collection('meal_plans')
          .where('userId', isEqualTo: userId)
          .get();

      final plans = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
        'id': doc.id,
          ...data,
        };
      }).toList();

      // Ordenar por createdAt em memória (mais recente primeiro)
      plans.sort((a, b) {
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];
        
        // Se ambos são Timestamps, comparar diretamente
        if (aCreated != null && bCreated != null) {
          if (aCreated is Timestamp && bCreated is Timestamp) {
            return bCreated.compareTo(aCreated);
          }
          // Se são DateTime, converter
          if (aCreated is DateTime && bCreated is DateTime) {
            return bCreated.compareTo(aCreated);
          }
        }
        
        // Se um é null, colocar no final
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        
        return 0;
      });

      return plans;
    } catch (e) {
      throw Exception('Erro ao buscar planos alimentares: $e');
    }
  }

  /// Busca um plano alimentar por ID
  Future<Map<String, dynamic>?> getMealPlan(String mealPlanId) async {
    try {
      final doc = await _firestore.collection('meal_plans').doc(mealPlanId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar plano alimentar: $e');
    }
  }

  /// Atualiza um plano alimentar
  Future<void> updateMealPlan({
    required String mealPlanId,
    String? dietName,
    String? description,
    Map<String, dynamic>? nutritionData,
    Map<String, List<MealFood>>? meals,
  }) async {
    try {
      final mealPlanRef = _firestore.collection('meal_plans').doc(mealPlanId);
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (dietName != null) updateData['dietName'] = dietName;
      if (description != null) updateData['description'] = description;
      if (nutritionData != null) updateData['nutritionData'] = nutritionData;
      if (meals != null) {
        final mealsMap = <String, List<Map<String, dynamic>>>{};
        meals.forEach((mealType, mealFoods) {
          mealsMap[mealType] = mealFoods.map((mf) => mf.toMap()).toList();
        });
        updateData['meals'] = mealsMap;
      }

      await mealPlanRef.update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar plano alimentar: $e');
    }
  }

  /// Deleta um plano alimentar
  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _firestore.collection('meal_plans').doc(mealPlanId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar plano alimentar: $e');
    }
  }

  // ==================== DAILY MEALS ====================

  /// Salva as refeições do dia
  Future<void> saveDailyMeals({
    required String userId,
    required DateTime date,
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dailyMealsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_meals')
          .doc(dateStr);

      await dailyMealsRef.set({
        'date': Timestamp.fromDate(date),
        'meals': meals,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar refeições do dia: $e');
    }
  }

  /// Busca as refeições de um dia específico
  Future<List<Map<String, dynamic>>> getDailyMeals({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_meals')
          .doc(dateStr)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return List<Map<String, dynamic>>.from(data['meals'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar refeições do dia: $e');
    }
  }

  // ==================== FOOD ITEMS ====================

  /// Salva um alimento customizado do usuário
  Future<String> saveCustomFoodItem({
    required String userId,
    required FoodItem foodItem,
  }) async {
    try {
      final foodRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_foods')
          .doc();
      
      await foodRef.set({
        'id': foodRef.id,
        ...foodItem.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return foodRef.id;
    } catch (e) {
      throw Exception('Erro ao salvar alimento customizado: $e');
    }
  }

  /// Busca alimentos customizados do usuário
  Future<List<FoodItem>> getCustomFoodItems(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_foods')
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar alimentos customizados: $e');
    }
  }

  // ==================== NUTRITION TRACKING ====================

  /// Salva o registro nutricional do dia
  Future<void> saveDailyNutrition({
    required String userId,
    required DateTime date,
    required int caloriesConsumed,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final nutritionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_nutrition')
          .doc(dateStr);

      await nutritionRef.set({
        'date': Timestamp.fromDate(date),
        'caloriesConsumed': caloriesConsumed,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar registro nutricional: $e');
    }
  }

  /// Busca o registro nutricional de um dia
  Future<Map<String, dynamic>?> getDailyNutrition({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_nutrition')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar registro nutricional: $e');
    }
  }

  // ==================== STREAM LISTENERS ====================

  /// Stream de refeições do dia (para atualizações em tempo real)
  Stream<List<Map<String, dynamic>>> streamDailyMeals({
    required String userId,
    required DateTime date,
  }) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_meals')
        .doc(dateStr)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return List<Map<String, dynamic>>.from(data['meals'] ?? []);
      }
      return <Map<String, dynamic>>[];
    });
  }

  /// Stream de registro nutricional do dia
  Stream<Map<String, dynamic>?> streamDailyNutrition({
    required String userId,
    required DateTime date,
  }) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_nutrition')
        .doc(dateStr)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}

