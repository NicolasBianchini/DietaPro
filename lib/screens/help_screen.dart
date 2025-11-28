import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'terms_and_disclaimer_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ajuda'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Boas-vindas
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao DietaPro!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu assistente pessoal para uma alimentação saudável',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Perguntas Frequentes
            _buildSectionTitle('Perguntas Frequentes'),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'Como criar um plano alimentar?',
              answer: 'Vá em "Calculadora de Dieta" no menu do perfil, preencha seus dados e clique em "Calcular Necessidades Nutricionais". A IA irá gerar um plano personalizado para você.',
            ),
            _buildFAQItem(
              question: 'Como registrar minhas refeições?',
              answer: 'Na tela "Refeições", você pode marcar as refeições como concluídas usando o checkbox ao lado de cada refeição. Isso atualiza automaticamente seus macronutrientes.',
            ),
            _buildFAQItem(
              question: 'Como acompanhar meu peso?',
              answer: 'Use a ação rápida "Peso" na tela inicial ou vá em "Peso" no menu. Você pode registrar seu peso periodicamente e acompanhar sua evolução.',
            ),
            _buildFAQItem(
              question: 'Como definir minha meta de água?',
              answer: 'Use a ação rápida "Água" na tela inicial. Você pode definir sua meta diária e registrar seu consumo ao longo do dia.',
            ),
            _buildFAQItem(
              question: 'Posso adicionar refeições não planejadas?',
              answer: 'Sim! Use a ação rápida "Adicionar Refeição" na tela inicial para adicionar refeições que não estavam no seu plano alimentar.',
            ),
            const SizedBox(height: 32),
            
            // Dicas
            _buildSectionTitle('Dicas'),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.lightbulb_outline,
              title: 'Beba água regularmente',
              description: 'Mantenha-se hidratado ao longo do dia. Configure lembretes na seção de Configurações.',
            ),
            _buildTipCard(
              icon: Icons.restaurant,
              title: 'Siga seu plano alimentar',
              description: 'Tente seguir o plano gerado pela IA. Ele foi personalizado para suas necessidades.',
            ),
            _buildTipCard(
              icon: Icons.trending_up,
              title: 'Acompanhe seu progresso',
              description: 'Use a seção de Estatísticas para ver seu progresso e manter a motivação.',
            ),
            const SizedBox(height: 32),
            
            // Termos e Disclaimer
            _buildSectionTitle('Legal'),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.description_outlined,
              title: 'Termos de Uso e Aviso Legal',
              subtitle: 'Leia os termos e disclaimer médico',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsAndDisclaimerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Contato
            _buildSectionTitle('Contato'),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'suporte@dietapro.com',
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'suporte@dietapro.com',
                );
                try {
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Não foi possível abrir o email: $e'),
                      ),
                    );
                  }
                }
              },
            ),
            _buildContactCard(
              icon: Icons.help_outline,
              title: 'Suporte',
              subtitle: 'Central de ajuda',
              onTap: () {
                // Pode abrir uma tela de suporte ou link
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Em breve disponível'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Versão
            Center(
              child: Text(
                'Versão 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

