import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  final UserProfile userProfile;

  const OnboardingCompleteScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  bool _isSaving = false;
  final _firestoreService = FirestoreService();

  Future<void> _handleComplete() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Salvar perfil no Firestore
      final userId = await _firestoreService.saveUserProfile(widget.userProfile);
      
      // Atualizar o perfil com o ID retornado
      final savedProfile = UserProfile(
        id: userId,
        email: widget.userProfile.email,
        name: widget.userProfile.name,
        gender: widget.userProfile.gender,
        dateOfBirth: widget.userProfile.dateOfBirth,
        height: widget.userProfile.height,
        weight: widget.userProfile.weight,
        activityLevel: widget.userProfile.activityLevel,
        goal: widget.userProfile.goal,
        mealsPerDay: widget.userProfile.mealsPerDay,
        createdAt: widget.userProfile.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        // Navegar para a tela inicial do app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(userProfile: savedProfile),
          ),
          (route) => false, // Remove todas as rotas anteriores
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Ícone de sucesso
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Perfil Criado!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Agora podemos criar um plano alimentar personalizado para você',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Resumo do perfil
              _ProfileSummaryCard(userProfile: widget.userProfile),
              const SizedBox(height: 48),
              // Botão para continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Começar a usar o DietaPro'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final UserProfile userProfile;

  const _ProfileSummaryCard({required this.userProfile});

  String _getGenderText() {
    switch (userProfile.gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Feminino';
      case Gender.other:
        return 'Outro';
      default:
        return 'Não informado';
    }
  }

  String _getActivityText() {
    switch (userProfile.activityLevel) {
      case ActivityLevel.sedentary:
        return 'Sedentário';
      case ActivityLevel.light:
        return 'Leve';
      case ActivityLevel.moderate:
        return 'Moderado';
      case ActivityLevel.active:
        return 'Ativo';
      case ActivityLevel.veryActive:
        return 'Muito Ativo';
      default:
        return 'Não informado';
    }
  }

  String _getGoalText() {
    switch (userProfile.goal) {
      case Goal.loseWeight:
        return 'Perder Peso';
      case Goal.gainWeight:
        return 'Ganhar Peso';
      case Goal.gainMuscle:
        return 'Ganhar Massa Muscular';
      case Goal.maintain:
        return 'Manutenção';
      case Goal.eatBetter:
        return 'Comer Melhor';
      default:
        return 'Não informado';
    }
  }

  Map<String, dynamic> _getBMIClassification() {
    if (userProfile.bmi == null) {
      return {
        'category': 'Não calculado',
        'description': '',
        'color': Colors.grey,
        'isHealthy': null,
        'range': '',
      };
    }

    final bmi = userProfile.bmi!;

    if (bmi < 18.5) {
      return {
        'category': 'Abaixo do peso',
        'description': 'Abaixo do padrão recomendado',
        'color': Colors.blue,
        'isHealthy': false,
        'range': 'IMC < 18.5',
      };
    } else if (bmi < 25) {
      return {
        'category': 'Peso normal',
        'description': 'Dentro do padrão recomendado',
        'color': AppTheme.primaryColor,
        'isHealthy': true,
        'range': 'IMC 18.5 - 24.9',
      };
    } else if (bmi < 30) {
      return {
        'category': 'Sobrepeso',
        'description': 'Acima do padrão recomendado',
        'color': Colors.orange,
        'isHealthy': false,
        'range': 'IMC 25.0 - 29.9',
      };
    } else if (bmi < 35) {
      return {
        'category': 'Obesidade Grau I',
        'description': 'Acima do padrão recomendado',
        'color': Colors.red.shade600,
        'isHealthy': false,
        'range': 'IMC 30.0 - 34.9',
      };
    } else if (bmi < 40) {
      return {
        'category': 'Obesidade Grau II',
        'description': 'Acima do padrão recomendado',
        'color': Colors.red.shade700,
        'isHealthy': false,
        'range': 'IMC 35.0 - 39.9',
      };
    } else {
      return {
        'category': 'Obesidade Grau III',
        'description': 'Acima do padrão recomendado',
        'color': Colors.red.shade900,
        'isHealthy': false,
        'range': 'IMC ≥ 40.0',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do seu perfil',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.person_outline,
            label: 'Gênero',
            value: _getGenderText(),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.cake_outlined,
            label: 'Idade',
            value: userProfile.age != null ? '${userProfile.age} anos' : 'Não informado',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.height_outlined,
            label: 'Altura',
            value: userProfile.height != null
                ? '${userProfile.height!.toStringAsFixed(0)} cm'
                : 'Não informado',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.monitor_weight_outlined,
            label: 'Peso',
            value: userProfile.weight != null
                ? '${userProfile.weight!.toStringAsFixed(1)} kg'
                : 'Não informado',
          ),
          if (userProfile.bmi != null) ...[
            const SizedBox(height: 12),
            _BMICard(
              bmi: userProfile.bmi!,
              classification: _getBMIClassification(),
            ),
          ],
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.directions_run_outlined,
            label: 'Atividade',
            value: _getActivityText(),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.flag_outlined,
            label: 'Objetivo',
            value: _getGoalText(),
          ),
        ],
      ),
    );
  }
}

class _BMICard extends StatelessWidget {
  final double bmi;
  final Map<String, dynamic> classification;

  const _BMICard({
    required this.bmi,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    final category = classification['category'] as String;
    final description = classification['description'] as String;
    final color = classification['color'] as Color;
    final isHealthy = classification['isHealthy'] as bool?;
    final range = classification['range'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMC: ${bmi.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              // Indicador de saúde
              if (isHealthy != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHealthy ? 'Saudável' : 'Atenção',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isHealthy == true
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Faixa: $range',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

