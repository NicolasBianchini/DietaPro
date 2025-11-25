import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

class GenerateMealsSheet extends StatefulWidget {
  final UserProfile? userProfile;
  final Function(int) onGenerate;

  const GenerateMealsSheet({
    super.key,
    this.userProfile,
    required this.onGenerate,
  });

  @override
  State<GenerateMealsSheet> createState() => _GenerateMealsSheetState();
}

class _GenerateMealsSheetState extends State<GenerateMealsSheet> {
  int _selectedMealsCount = 3;
  int? _recommendedMealsCount;

  @override
  void initState() {
    super.initState();
    _recommendedMealsCount = _calculateRecommendedMeals();
    _selectedMealsCount = _recommendedMealsCount ?? 3;
  }

  int? _calculateRecommendedMeals() {
    if (widget.userProfile == null) return 3;

    final goal = widget.userProfile!.goal;
    final activityLevel = widget.userProfile!.activityLevel;

    // Recomendações baseadas no objetivo e nível de atividade
    if (goal == Goal.loseWeight) {
      // Para perder peso: 3-4 refeições (menor frequência ajuda no déficit)
      if (activityLevel == ActivityLevel.sedentary || 
          activityLevel == ActivityLevel.light) {
        return 3;
      } else {
        return 4;
      }
    } else if (goal == Goal.gainWeight) {
      // Para ganhar peso: 4-6 refeições (mais frequência para aumentar ingestão)
      if (activityLevel == ActivityLevel.sedentary || 
          activityLevel == ActivityLevel.light) {
        return 4;
      } else {
        return 5;
      }
    } else if (goal == Goal.gainMuscle) {
      // Para ganhar massa: 4-6 refeições (mais frequência para síntese proteica)
      if (activityLevel == ActivityLevel.veryActive || 
          activityLevel == ActivityLevel.active) {
        return 6;
      } else {
        return 4;
      }
    } else if (goal == Goal.maintain) {
      // Para manutenção: 3-5 refeições
      if (activityLevel == ActivityLevel.sedentary || 
          activityLevel == ActivityLevel.light) {
        return 3;
      } else if (activityLevel == ActivityLevel.veryActive) {
        return 5;
      } else {
        return 4;
      }
    } else {
      // Comer melhor: 3-4 refeições
      return 3;
    }
  }

  String _getRecommendationReason() {
    if (widget.userProfile == null) {
      return 'Recomendamos 3 refeições por dia para começar.';
    }

    final goal = widget.userProfile!.goal;
    final count = _recommendedMealsCount ?? 3;

    if (goal == Goal.loseWeight) {
      return 'Para perder peso, recomendamos $count refeições por dia. Isso ajuda a manter um déficit calórico controlado e evita excessos.';
    } else if (goal == Goal.gainWeight) {
      return 'Para ganhar peso, recomendamos $count refeições por dia. A maior frequência ajuda a aumentar a ingestão calórica de forma distribuída ao longo do dia.';
    } else if (goal == Goal.gainMuscle) {
      return 'Para ganhar massa muscular, recomendamos $count refeições por dia. A maior frequência ajuda na síntese proteica e no fornecimento constante de nutrientes.';
    } else if (goal == Goal.maintain) {
      return 'Para manutenção, recomendamos $count refeições por dia. Isso mantém seu metabolismo ativo e ajuda a distribuir as calorias ao longo do dia.';
    } else {
      return 'Recomendamos $count refeições por dia para estabelecer uma rotina alimentar saudável.';
    }
  }

  String _getGoalText() {
    final goal = widget.userProfile?.goal;
    
    switch (goal) {
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
      case null:
        return 'Seu objetivo';
    }
  }

  String _getActivityText() {
    final activityLevel = widget.userProfile?.activityLevel;
    
    switch (activityLevel) {
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
      case null:
        return 'sua rotina';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle para arrastar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerar Plano Alimentar',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personalize seu plano diário',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Card de recomendação
                if (_recommendedMealsCount != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recomendação Personalizada',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getRecommendationReason(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Baseado em: ${_getGoalText()} e nível de atividade ${_getActivityText()}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                // Seleção de número de refeições
                Text(
                  'Quantas refeições você quer fazer por dia?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você pode escolher entre 3 e 6 refeições diárias',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // Opções de refeições
                ...List.generate(4, (index) {
                  final count = index + 3; // 3, 4, 5, 6
                  final isSelected = _selectedMealsCount == count;
                  final isRecommended = _recommendedMealsCount == count;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMealsCount = count;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Radio button customizado
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$count refeições',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : null,
                                            ),
                                      ),
                                      if (isRecommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Recomendado',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMealDescription(count),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                // Botão de gerar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onGenerate(_selectedMealsCount);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Gerar Plano com $_selectedMealsCount Refeições',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMealDescription(int count) {
    switch (count) {
      case 3:
        return 'Café da manhã, almoço e jantar';
      case 4:
        return 'Café da manhã, lanche, almoço e jantar';
      case 5:
        return 'Café da manhã, lanche da manhã, almoço, lanche da tarde e jantar';
      case 6:
        return 'Café da manhã, lanche da manhã, almoço, lanche da tarde, jantar e ceia';
      default:
        return '';
    }
  }
}

