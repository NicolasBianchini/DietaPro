import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _customRestrictionsController = TextEditingController();
  
  Gender? _selectedGender;
  DateTime? _selectedDateOfBirth;
  ActivityLevel? _selectedActivityLevel;
  Goal? _selectedGoal;
  int _mealsPerDay = 5;
  Set<String> _selectedRestrictions = {};
  
  bool _isLoading = false;
  final _firestoreService = FirestoreService();
  
  // Lista de restrições alimentares comuns
  final List<String> _commonRestrictions = [
    'Lactose',
    'Glúten',
    'Frutos do mar',
    'Amendoim',
    'Soja',
    'Ovos',
    'Nozes',
    'Vegetariano',
    'Vegano',
    'Diabético',
    'Hipertensão',
    'Colesterol alto',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userProfile.name;
    _heightController.text = widget.userProfile.height?.toStringAsFixed(0) ?? '';
    _weightController.text = widget.userProfile.weight?.toStringAsFixed(1) ?? '';
    _selectedGender = widget.userProfile.gender;
    _selectedDateOfBirth = widget.userProfile.dateOfBirth;
    _selectedActivityLevel = widget.userProfile.activityLevel;
    _selectedGoal = widget.userProfile.goal;
    _mealsPerDay = widget.userProfile.mealsPerDay ?? 5;
    _selectedRestrictions = Set<String>.from(widget.userProfile.dietaryRestrictions ?? []);
    _customRestrictionsController.text = widget.userProfile.customDietaryRestrictions ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _customRestrictionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 120, 1, 1);
    final DateTime lastDate = DateTime(now.year - 1, 12, 31);
    final DateTime initialDate = _selectedDateOfBirth ?? DateTime(now.year - 25, 1, 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null ||
        _selectedDateOfBirth == null ||
        _selectedActivityLevel == null ||
        _selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);

      if (height == null || weight == null) {
        throw Exception('Altura e peso devem ser números válidos');
      }

      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        name: _nameController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDateOfBirth,
        height: height,
        weight: weight,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
        mealsPerDay: _mealsPerDay,
        dietaryRestrictions: _selectedRestrictions.isNotEmpty ? _selectedRestrictions.toList() : null,
        customDietaryRestrictions: _customRestrictionsController.text.trim().isNotEmpty 
            ? _customRestrictionsController.text.trim() 
            : null,
        createdAt: widget.userProfile.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );

        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Gênero
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Gênero *',
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: Gender.values.map((gender) {
                  String label;
                  switch (gender) {
                    case Gender.male:
                      label = 'Masculino';
                      break;
                    case Gender.female:
                      label = 'Feminino';
                      break;
                    case Gender.other:
                      label = 'Outro';
                      break;
                  }
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Data de nascimento
              InkWell(
                onTap: () => _selectDateOfBirth(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento *',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedDateOfBirth != null
                        ? _formatDate(_selectedDateOfBirth!)
                        : 'Selecione a data',
                    style: TextStyle(
                      color: _selectedDateOfBirth != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Altura e Peso
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Altura (cm) *',
                        prefixIcon: const Icon(Icons.height, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Peso (kg) *',
                        prefixIcon: const Icon(Icons.monitor_weight, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 30 || weight > 300) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nível de atividade
              DropdownButtonFormField<ActivityLevel>(
                value: _selectedActivityLevel,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Nível de Atividade *',
                  prefixIcon: const Icon(Icons.fitness_center, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ActivityLevel.values.map((level) {
                  String label;
                  switch (level) {
                    case ActivityLevel.sedentary:
                      label = 'Sedentário';
                      break;
                    case ActivityLevel.light:
                      label = 'Leve (exercício 1-3x/semana)';
                      break;
                    case ActivityLevel.moderate:
                      label = 'Moderado (exercício 3-5x/semana)';
                      break;
                    case ActivityLevel.active:
                      label = 'Ativo (exercício 6-7x/semana)';
                      break;
                    case ActivityLevel.veryActive:
                      label = 'Muito ativo (exercício 2x/dia)';
                      break;
                  }
                  return DropdownMenuItem(
                    value: level,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Objetivo
              DropdownButtonFormField<Goal>(
                value: _selectedGoal,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Objetivo *',
                  prefixIcon: const Icon(Icons.flag, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: Goal.values.map((goal) {
                  String label;
                  switch (goal) {
                    case Goal.loseWeight:
                      label = 'Perder Peso';
                      break;
                    case Goal.gainWeight:
                      label = 'Ganhar Peso';
                      break;
                    case Goal.gainMuscle:
                      label = 'Ganhar Massa Muscular';
                      break;
                    case Goal.maintain:
                      label = 'Manutenção';
                      break;
                    case Goal.eatBetter:
                      label = 'Comer Melhor';
                      break;
                  }
                  return DropdownMenuItem(
                    value: goal,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGoal = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Número de refeições
              Text(
                'Quantas refeições você faz por dia? *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_mealsPerDay refeições por dia',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _mealsPerDay > 3
                              ? () {
                                  setState(() {
                                    _mealsPerDay--;
                                  });
                                }
                              : null,
                          color: AppTheme.primaryColor,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_mealsPerDay',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _mealsPerDay < 7
                              ? () {
                                  setState(() {
                                    _mealsPerDay++;
                                  });
                                }
                              : null,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Seção de Restrições Alimentares
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Restrições Alimentares',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecione suas alergias, intolerâncias ou restrições alimentares',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Checkboxes de restrições comuns
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _commonRestrictions.map((restriction) {
                        final isSelected = _selectedRestrictions.contains(restriction);
                        return FilterChip(
                          label: Text(
                            restriction,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRestrictions.add(restriction);
                              } else {
                                _selectedRestrictions.remove(restriction);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo de texto para restrições customizadas
                    TextFormField(
                      controller: _customRestrictionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Outras restrições alimentares',
                        hintText: 'Descreva outras alergias, intolerâncias ou restrições alimentares que você possui...',
                        prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Ex: Alergia a corantes, restrição de sódio, etc.',
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Salvar Alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

