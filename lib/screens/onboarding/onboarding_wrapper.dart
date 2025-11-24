import 'package:flutter/material.dart';
import 'onboarding_step1_basic_info.dart';
import 'onboarding_step2_physical_data.dart';
import 'onboarding_step3_activity_level.dart';
import 'onboarding_step4_goals.dart';
import 'onboarding_complete_screen.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class OnboardingWrapper extends StatefulWidget {
  final String email;
  final String name;

  const OnboardingWrapper({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  int _currentStep = 0;
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = UserProfile(
      email: widget.email,
      name: widget.name,
    );
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() {
      _userProfile = updatedProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progresso (não mostrar na tela de conclusão)
            if (_currentStep < 4) _buildProgressIndicator(),
            // Conteúdo da tela atual
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 3 ? 8 : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < _currentStep
                        ? AppTheme.primaryColor
                        : index == _currentStep
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Passo ${_currentStep + 1} de 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return OnboardingStep1BasicInfo(
          userProfile: _userProfile,
          onNext: (profile) {
            _updateProfile(profile);
            _nextStep();
          },
        );
      case 1:
        return OnboardingStep2PhysicalData(
          userProfile: _userProfile,
          onNext: (profile) {
            _updateProfile(profile);
            _nextStep();
          },
          onBack: _previousStep,
        );
      case 2:
        return OnboardingStep3ActivityLevel(
          userProfile: _userProfile,
          onNext: (profile) {
            _updateProfile(profile);
            _nextStep();
          },
          onBack: _previousStep,
        );
      case 3:
        return OnboardingStep4Goals(
          userProfile: _userProfile,
          onComplete: (profile) {
            _updateProfile(profile);
            _nextStep();
          },
          onBack: _previousStep,
        );
      case 4:
        return OnboardingCompleteScreen(
          userProfile: _userProfile,
        );
      default:
        return const SizedBox();
    }
  }
}

