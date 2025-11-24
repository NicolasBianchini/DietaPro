import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class OnboardingStep3ActivityLevel extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onNext;
  final VoidCallback onBack;

  const OnboardingStep3ActivityLevel({
    super.key,
    required this.userProfile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingStep3ActivityLevel> createState() => _OnboardingStep3ActivityLevelState();
}

class _OnboardingStep3ActivityLevelState extends State<OnboardingStep3ActivityLevel> {
  ActivityLevel? _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    _selectedActivityLevel = widget.userProfile.activityLevel;
  }

  void _handleNext() {
    if (_selectedActivityLevel != null) {
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        name: widget.userProfile.name,
        gender: widget.userProfile.gender,
        dateOfBirth: widget.userProfile.dateOfBirth,
        height: widget.userProfile.height,
        weight: widget.userProfile.weight,
        activityLevel: _selectedActivityLevel,
        goal: widget.userProfile.goal,
        createdAt: widget.userProfile.createdAt,
        updatedAt: DateTime.now(),
      );
      widget.onNext(updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Nível de Atividade',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o nível que melhor descreve sua rotina de exercícios',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          // Opções de nível de atividade
          _ActivityOption(
            level: ActivityLevel.sedentary,
            title: 'Sedentário',
            description: 'Pouco ou nenhum exercício',
            icon: Icons.chair_outlined,
            isSelected: _selectedActivityLevel == ActivityLevel.sedentary,
            onTap: () {
              setState(() {
                _selectedActivityLevel = ActivityLevel.sedentary;
              });
            },
          ),
          const SizedBox(height: 16),
          _ActivityOption(
            level: ActivityLevel.light,
            title: 'Leve',
            description: 'Exercício leve 1-3 vezes por semana',
            icon: Icons.directions_walk_outlined,
            isSelected: _selectedActivityLevel == ActivityLevel.light,
            onTap: () {
              setState(() {
                _selectedActivityLevel = ActivityLevel.light;
              });
            },
          ),
          const SizedBox(height: 16),
          _ActivityOption(
            level: ActivityLevel.moderate,
            title: 'Moderado',
            description: 'Exercício moderado 3-5 vezes por semana',
            icon: Icons.directions_run_outlined,
            isSelected: _selectedActivityLevel == ActivityLevel.moderate,
            onTap: () {
              setState(() {
                _selectedActivityLevel = ActivityLevel.moderate;
              });
            },
          ),
          const SizedBox(height: 16),
          _ActivityOption(
            level: ActivityLevel.active,
            title: 'Ativo',
            description: 'Exercício intenso 6-7 vezes por semana',
            icon: Icons.fitness_center_outlined,
            isSelected: _selectedActivityLevel == ActivityLevel.active,
            onTap: () {
              setState(() {
                _selectedActivityLevel = ActivityLevel.active;
              });
            },
          ),
          const SizedBox(height: 16),
          _ActivityOption(
            level: ActivityLevel.veryActive,
            title: 'Muito Ativo',
            description: 'Exercício muito intenso, 2x por dia ou trabalho físico',
            icon: Icons.sports_gymnastics_outlined,
            isSelected: _selectedActivityLevel == ActivityLevel.veryActive,
            onTap: () {
              setState(() {
                _selectedActivityLevel = ActivityLevel.veryActive;
              });
            },
          ),
          const SizedBox(height: 40),
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
                  onPressed: _selectedActivityLevel != null ? _handleNext : null,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityOption extends StatelessWidget {
  final ActivityLevel level;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityOption({
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

