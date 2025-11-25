import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class OnboardingStep2PhysicalData extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onNext;
  final VoidCallback onBack;

  const OnboardingStep2PhysicalData({
    super.key,
    required this.userProfile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingStep2PhysicalData> createState() => _OnboardingStep2PhysicalDataState();
}

class _OnboardingStep2PhysicalDataState extends State<OnboardingStep2PhysicalData> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useMetric = true; // true = cm/kg, false = ft/lbs

  @override
  void initState() {
    super.initState();
    if (widget.userProfile.height != null) {
      _heightController.text = widget.userProfile.height!.toStringAsFixed(0);
    }
    if (widget.userProfile.weight != null) {
      _weightController.text = widget.userProfile.weight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);

      if (height == null || weight == null) {
        return;
      }

      // Converter para métrica se necessário
      final heightInCm = _useMetric ? height : height * 30.48;
      final weightInKg = _useMetric ? weight : weight * 0.453592;

      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        name: widget.userProfile.name,
        gender: widget.userProfile.gender,
        dateOfBirth: widget.userProfile.dateOfBirth,
        height: heightInCm,
        weight: weightInKg,
        activityLevel: widget.userProfile.activityLevel,
        goal: widget.userProfile.goal,
        createdAt: widget.userProfile.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no Firestore
      try {
        final firestoreService = FirestoreService();
        final userId = await firestoreService.saveUserProfile(updatedProfile);
        final savedProfile = UserProfile(
          id: userId,
          email: updatedProfile.email,
          name: updatedProfile.name,
          gender: updatedProfile.gender,
          dateOfBirth: updatedProfile.dateOfBirth,
          height: updatedProfile.height,
          weight: updatedProfile.weight,
          activityLevel: updatedProfile.activityLevel,
          goal: updatedProfile.goal,
          createdAt: updatedProfile.createdAt,
          updatedAt: updatedProfile.updatedAt,
        );
        widget.onNext(savedProfile);
      } catch (e) {
        // Se houver erro, continua mesmo assim
        widget.onNext(updatedProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Dados Físicos',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Informe sua altura e peso atual',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            // Toggle de unidade
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggle(
                  label: 'Métrico',
                  isSelected: _useMetric,
                  onTap: () {
                    setState(() {
                      _useMetric = true;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _UnitToggle(
                  label: 'Imperial',
                  isSelected: !_useMetric,
                  onTap: () {
                    setState(() {
                      _useMetric = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Campo de Altura
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Altura',
                hintText: _useMetric ? 'Ex: 175' : 'Ex: 5.7',
                suffixText: _useMetric ? 'cm' : 'ft',
                prefixIcon: const Icon(Icons.height_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira sua altura';
                }
                final height = double.tryParse(value);
                if (height == null) {
                  return 'Por favor, insira um valor válido';
                }
                if (_useMetric && (height < 50 || height > 250)) {
                  return 'Altura deve estar entre 50 e 250 cm';
                }
                if (!_useMetric && (height < 1.5 || height > 8.2)) {
                  return 'Altura deve estar entre 1.5 e 8.2 ft';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Campo de Peso
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Peso',
                hintText: _useMetric ? 'Ex: 70.5' : 'Ex: 155',
                suffixText: _useMetric ? 'kg' : 'lbs',
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira seu peso';
                }
                final weight = double.tryParse(value);
                if (weight == null) {
                  return 'Por favor, insira um valor válido';
                }
                if (_useMetric && (weight < 20 || weight > 300)) {
                  return 'Peso deve estar entre 20 e 300 kg';
                }
                if (!_useMetric && (weight < 44 || weight > 660)) {
                  return 'Peso deve estar entre 44 e 660 lbs';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Cálculo de IMC (se ambos os valores estiverem preenchidos)
            if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty)
              _buildBMICard(),
            const SizedBox(height: 24),
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Voltar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _handleNext(),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || weight == null) {
      return const SizedBox();
    }

    final heightInMeters = (_useMetric ? height : height * 30.48) / 100;
    final weightInKg = _useMetric ? weight : weight * 0.453592;
    final bmi = weightInKg / (heightInMeters * heightInMeters);

    String bmiCategory;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiCategory = 'Abaixo do peso';
      bmiColor = Colors.blue;
    } else if (bmi < 25) {
      bmiCategory = 'Peso normal';
      bmiColor = AppTheme.primaryColor;
    } else if (bmi < 30) {
      bmiCategory = 'Sobrepeso';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = 'Obesidade';
      bmiColor = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bmiColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'IMC',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                bmi.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: bmiColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Column(
            children: [
              Text(
                'Classificação',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                bmiCategory,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: bmiColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

