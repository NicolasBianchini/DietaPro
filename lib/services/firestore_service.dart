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
    List<String>? dietaryRestrictions,
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

      // Adicionar restrições alimentares se fornecidas
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        mealPlanData['dietaryRestrictions'] = dietaryRestrictions;
      }

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

  /// Busca um plano alimentar por ID (alias para getMealPlan)
  Future<Map<String, dynamic>?> getMealPlanById(String mealPlanId) async {
    return getMealPlan(mealPlanId);
  }

  /// Atualiza um plano alimentar
  Future<void> updateMealPlan({
    required String mealPlanId,
    String? dietName,
    String? description,
    Map<String, dynamic>? nutritionData,
    Map<String, List<MealFood>>? meals,
    List<String>? dietaryRestrictions,
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
      if (dietaryRestrictions != null) {
        updateData['dietaryRestrictions'] = dietaryRestrictions;
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

  // ==================== EXTRA MEALS ====================

  /// Adiciona uma refeição extra ao dia
  /// 
  /// [userId] - ID do usuário
  /// [date] - Data da refeição
  /// [meal] - Map com dados da refeição (name, calories, protein, carbs, fats, foods, etc.)
  Future<String> addExtraMeal({
    required String userId,
    required DateTime date,
    required Map<String, dynamic> meal,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final extraMealsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('extra_meals')
          .doc();

      final mealData = {
        'id': extraMealsRef.id,
        'userId': userId,
        'date': Timestamp.fromDate(date),
        ...meal,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await extraMealsRef.set(mealData);
      return extraMealsRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar refeição extra: $e');
    }
  }

  /// Busca todas as refeições extras de um dia específico
  /// 
  /// Retorna uma lista de refeições extras ordenadas por data (mais recente primeiro)
  Future<List<Map<String, dynamic>>> getExtraMeals({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Buscar todas as refeições extras do usuário e filtrar por data em memória
      // para evitar necessidade de índice composto
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('extra_meals')
          .orderBy('date', descending: true)
          .get();

      final startTimestamp = Timestamp.fromDate(startOfDay);
      final endTimestamp = Timestamp.fromDate(endOfDay);

      final meals = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            final mealDate = data['date'] as Timestamp?;
            if (mealDate == null) return false;
            return mealDate.compareTo(startTimestamp) >= 0 && 
                   mealDate.compareTo(endTimestamp) <= 0;
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .toList();

      return meals;
    } catch (e) {
      throw Exception('Erro ao buscar refeições extras: $e');
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

  // ==================== WATER TRACKING ====================

  /// Salva o consumo de água do dia
  Future<void> saveDailyWater({
    required String userId,
    required DateTime date,
    required double waterAmount,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final waterRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_water')
          .doc(dateStr);

      await waterRef.set({
        'date': Timestamp.fromDate(date),
        'waterAmount': waterAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar consumo de água: $e');
    }
  }

  /// Busca o consumo de água de um dia específico
  Future<double> getDailyWater({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_water')
          .doc(dateStr)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return (data['waterAmount'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Erro ao buscar consumo de água: $e');
    }
  }

  // ==================== WEIGHT TRACKING ====================

  /// Salva um registro de peso
  Future<String> saveWeightRecord({
    required String userId,
    required double weight,
    DateTime? date,
  }) async {
    try {
      final recordDate = date ?? DateTime.now();
      final weightRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_records')
          .doc();

      await weightRef.set({
        'id': weightRef.id,
        'weight': weight,
        'date': Timestamp.fromDate(recordDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return weightRef.id;
    } catch (e) {
      throw Exception('Erro ao salvar registro de peso: $e');
    }
  }

  /// Busca todos os registros de peso do usuário (ordenados por data, mais recente primeiro)
  Future<List<Map<String, dynamic>>> getWeightRecords(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_records')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar registros de peso: $e');
    }
  }

  /// Busca o último registro de peso do usuário
  Future<Map<String, dynamic>?> getLastWeightRecord(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_records')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar último registro de peso: $e');
    }
  }

  /// Deleta um registro de peso
  Future<void> deleteWeightRecord({
    required String userId,
    required String recordId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar registro de peso: $e');
    }
  }

  // ==================== USER SETTINGS ====================

  /// Salva as configurações do usuário
  Future<void> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final settingsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings');

      await settingsRef.set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar configurações: $e');
    }
  }

  /// Busca as configurações do usuário
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      return {};
    } catch (e) {
      throw Exception('Erro ao buscar configurações: $e');
    }
  }

  // ==================== WATER GOAL ====================

  /// Salva a meta diária de água do usuário
  Future<void> saveWaterGoal({
    required String userId,
    required double goalLiters,
  }) async {
    try {
      final settingsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings');

      await settingsRef.set({
        'waterGoal': goalLiters,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar meta de água: $e');
    }
  }

  /// Busca a meta diária de água do usuário
  Future<double?> getWaterGoal(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return (data['waterGoal'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar meta de água: $e');
    }
  }

  // ==================== DIETARY RESTRICTIONS ====================

  /// Salva as restrições alimentares do usuário
  /// 
  /// [dietaryRestrictions] - Lista de restrições comuns selecionadas (ex: ['Lactose', 'Glúten'])
  /// [customRestrictions] - Texto com restrições customizadas do usuário
  Future<void> saveUserDietaryRestrictions({
    required String userId,
    List<String>? dietaryRestrictions,
    String? customRestrictions,
  }) async {
    try {
      final restrictionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('dietary_restrictions');

      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (dietaryRestrictions != null) {
        data['dietaryRestrictions'] = dietaryRestrictions;
      }

      if (customRestrictions != null) {
        data['customRestrictions'] = customRestrictions;
      }

      await restrictionsRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar restrições alimentares: $e');
    }
  }

  /// Busca as restrições alimentares do usuário
  /// 
  /// Retorna um Map com:
  /// - 'dietaryRestrictions': List<String>? - Lista de restrições comuns
  /// - 'customRestrictions': String? - Texto com restrições customizadas
  Future<Map<String, dynamic>> getUserDietaryRestrictions(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('dietary_restrictions')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'dietaryRestrictions': data['dietaryRestrictions'] != null
              ? List<String>.from(data['dietaryRestrictions'])
              : null,
          'customRestrictions': data['customRestrictions'] as String?,
        };
      }
      return {
        'dietaryRestrictions': null,
        'customRestrictions': null,
      };
    } catch (e) {
      throw Exception('Erro ao buscar restrições alimentares: $e');
    }
  }

  // ==================== TERMS ACCEPTANCE ====================

  /// Salva o aceite dos termos e condições pelo usuário
  /// 
  /// [userId] - ID do usuário
  /// [accepted] - Se o usuário aceitou os termos
  /// [acceptedAt] - Data/hora do aceite (opcional, usa DateTime.now() se não fornecido)
  /// [termsVersion] - Versão dos termos aceitos (opcional)
  Future<void> saveUserTermsAcceptance({
    required String userId,
    required bool accepted,
    DateTime? acceptedAt,
    String? termsVersion,
  }) async {
    try {
      final termsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('terms_acceptance');

      final data = <String, dynamic>{
        'accepted': accepted,
        'acceptedAt': acceptedAt != null 
            ? Timestamp.fromDate(acceptedAt) 
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (termsVersion != null) {
        data['termsVersion'] = termsVersion;
      }

      await termsRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao salvar aceite dos termos: $e');
    }
  }

  /// Verifica se o usuário aceitou os termos e condições
  /// 
  /// Retorna um Map com:
  /// - 'accepted': bool - Se o usuário aceitou
  /// - 'acceptedAt': DateTime? - Data/hora do aceite
  /// - 'termsVersion': String? - Versão dos termos aceitos
  Future<Map<String, dynamic>> hasUserAcceptedTerms(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('terms_acceptance')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final acceptedAt = data['acceptedAt'];
        
        return {
          'accepted': data['accepted'] as bool? ?? false,
          'acceptedAt': acceptedAt != null && acceptedAt is Timestamp
              ? acceptedAt.toDate()
              : null,
          'termsVersion': data['termsVersion'] as String?,
        };
      }
      return {
        'accepted': false,
        'acceptedAt': null,
        'termsVersion': null,
      };
    } catch (e) {
      throw Exception('Erro ao verificar aceite dos termos: $e');
    }
  }
}
