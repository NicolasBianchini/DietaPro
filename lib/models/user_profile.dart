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
      'id': id,
      'email': email,
      'name': name,
      'gender': gender?.name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel?.name,
      'goal': goal?.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Criar a partir de Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] != null ? Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.other,
      ) : null,
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      activityLevel: map['activityLevel'] != null ? ActivityLevel.values.firstWhere(
        (e) => e.name == map['activityLevel'],
      ) : null,
      goal: map['goal'] != null ? Goal.values.firstWhere(
        (e) => e.name == map['goal'],
      ) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Verificar se o perfil está completo
  bool get isComplete {
    return gender != null &&
        dateOfBirth != null &&
        height != null &&
        weight != null &&
        activityLevel != null &&
        goal != null;
  }
}

