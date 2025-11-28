enum Gender {
  male,
  female,
  other,
}

enum ActivityLevel {
  sedentary, // Sedentário
  light, // Leve (exercício 1-3x/semana)
  moderate, // Moderado (exercício 3-5x/semana)
  active, // Ativo (exercício 6-7x/semana)
  veryActive, // Muito ativo (exercício 2x/dia)
}

enum Goal {
  loseWeight, // Perder peso
  gainWeight, // Ganhar peso
  gainMuscle, // Ganhar massa muscular
  maintain, // Manutenção
  eatBetter, // Comer melhor
}

class UserProfile {
  String? id;
  String email;
  String name;
  Gender? gender;
  DateTime? dateOfBirth; // Data de nascimento
  double? height; // em cm
  double? weight; // em kg
  ActivityLevel? activityLevel;
  Goal? goal;
  int? mealsPerDay; // Número de refeições por dia (padrão: 5)
  List<String>? dietaryRestrictions; // Restrições alimentares comuns (checkboxes)
  String? customDietaryRestrictions; // Restrições alimentares customizadas (texto livre)
  bool? termsAccepted; // Confirmação de aceite de termos
  DateTime? termsAcceptedAt; // Data de aceite de termos
  String? passwordHash; // Hash da senha (SHA-256) - armazenado no Firestore
  String? photoURL; // URL da foto de perfil no Firebase Storage
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.email,
    required this.name,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.activityLevel,
    this.goal,
    this.mealsPerDay,
    this.dietaryRestrictions,
    this.customDietaryRestrictions,
    this.termsAccepted,
    this.termsAcceptedAt,
    this.passwordHash,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
  });

  // Calcular idade a partir da data de nascimento
  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    final monthDifference = today.month - dateOfBirth!.month;
    if (monthDifference < 0 || (monthDifference == 0 && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Calcular IMC
  double? get bmi {
    if (height == null || weight == null || height! <= 0) {
      return null;
    }
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Converter para Map (útil para salvar no Firebase/Firestore)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      if (gender != null) 'gender': gender!.name,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activityLevel': activityLevel!.name,
      if (goal != null) 'goal': goal!.name,
      if (mealsPerDay != null) 'mealsPerDay': mealsPerDay,
      if (dietaryRestrictions != null && dietaryRestrictions!.isNotEmpty) 'dietaryRestrictions': dietaryRestrictions,
      if (customDietaryRestrictions != null && customDietaryRestrictions!.isNotEmpty) 'customDietaryRestrictions': customDietaryRestrictions,
      if (termsAccepted != null) 'termsAccepted': termsAccepted,
      if (termsAcceptedAt != null) 'termsAcceptedAt': termsAcceptedAt!.toIso8601String(),
      if (passwordHash != null && passwordHash!.isNotEmpty) 'passwordHash': passwordHash,
      if (photoURL != null && photoURL!.isNotEmpty) 'photoURL': photoURL,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Criar a partir de Map (compatível com Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Converter Timestamp do Firestore para DateTime se necessário
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Se for Timestamp do Firestore, converter
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return null;
      }
    }

    return UserProfile(
      id: map['id'] ?? map['id'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] != null ? Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.other,
      ) : null,
      dateOfBirth: parseTimestamp(map['dateOfBirth']),
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      activityLevel: map['activityLevel'] != null ? ActivityLevel.values.firstWhere(
        (e) => e.name == map['activityLevel'],
      ) : null,
      goal: map['goal'] != null ? Goal.values.firstWhere(
        (e) => e.name == map['goal'],
      ) : null,
      mealsPerDay: map['mealsPerDay']?.toInt(),
      dietaryRestrictions: _parseDietaryRestrictions(map['dietaryRestrictions']),
      customDietaryRestrictions: map['customDietaryRestrictions'] as String?,
      termsAccepted: map['termsAccepted'] as bool?,
      termsAcceptedAt: parseTimestamp(map['termsAcceptedAt']),
      passwordHash: map['passwordHash'] as String?,
      photoURL: map['photoURL'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  // Método auxiliar para parsear restrições alimentares
  static List<String>? _parseDietaryRestrictions(dynamic value) {
    if (value == null) return null;
    
    // Se já é uma List, converter diretamente
    if (value is List) {
      try {
        return value.map((e) => e.toString()).toList();
      } catch (e) {
        return null;
      }
    }
    
    // Se é uma String, retornar null (dados antigos/inválidos)
    // Não tentamos converter String para List para evitar erros
    if (value is String) {
      return null;
    }
    
    // Para qualquer outro tipo, retornar null
    return null;
  }

  // Verificar se o perfil está completo
  bool get isComplete {
    return gender != null &&
        dateOfBirth != null &&
        height != null &&
        weight != null &&
        activityLevel != null &&
        goal != null &&
        mealsPerDay != null;
  }
  
  // Obter número de refeições (padrão: 5 se não definido)
  int get mealsPerDayOrDefault => mealsPerDay ?? 5;
}

