import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsAndDisclaimerScreen extends StatelessWidget {
  const TermsAndDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Termos de Uso e Aviso Legal'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso Médico Importante
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AVISO MÉDICO IMPORTANTE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'O DietaPro é uma ferramenta de apoio e não substitui o acompanhamento de um nutricionista clínico ou profissional de saúde qualificado.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade800,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Seção de Disclaimer
            _buildSectionTitle('Disclaimer Médico'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'O DietaPro é uma aplicação móvel desenvolvida para fornecer informações e ferramentas relacionadas à nutrição e alimentação. No entanto, é importante entender que:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              'Este aplicativo não é um serviço médico e não fornece diagnósticos, tratamentos ou prescrições médicas.',
            ),
            _buildBulletPoint(
              'As informações fornecidas pelo aplicativo são de caráter geral e educacional.',
            ),
            _buildBulletPoint(
              'Os planos alimentares gerados são sugestões baseadas em algoritmos e não consideram todas as particularidades individuais de saúde.',
            ),
            _buildBulletPoint(
              'Sempre consulte um nutricionista clínico ou médico antes de iniciar qualquer dieta ou mudança significativa em seus hábitos alimentares.',
            ),
            _buildBulletPoint(
              'Se você tem condições médicas, alergias, intolerâncias ou está grávida/amamentando, é essencial buscar orientação profissional.',
            ),
            const SizedBox(height: 32),
            
            // Seção de Limitações
            _buildSectionTitle('Limitações do Aplicativo'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'O DietaPro possui as seguintes limitações:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              'Não realiza avaliação física ou análise clínica completa.',
            ),
            _buildBulletPoint(
              'Não considera histórico médico completo, medicações em uso ou interações medicamentosas.',
            ),
            _buildBulletPoint(
              'As recomendações podem não ser adequadas para todas as pessoas.',
            ),
            _buildBulletPoint(
              'Não substitui consultas regulares com profissionais de saúde.',
            ),
            const SizedBox(height: 32),
            
            // Seção de Responsabilidade
            _buildSectionTitle('Responsabilidade do Usuário'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'Ao usar o DietaPro, você reconhece e concorda que:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              'Você é responsável por suas próprias decisões de saúde e alimentação.',
            ),
            _buildBulletPoint(
              'Você não deve usar este aplicativo como única fonte de informação para decisões médicas ou nutricionais importantes.',
            ),
            _buildBulletPoint(
              'Você deve buscar orientação profissional para questões específicas de saúde.',
            ),
            _buildBulletPoint(
              'O uso das informações fornecidas pelo aplicativo é por sua conta e risco.',
            ),
            const SizedBox(height: 32),
            
            // Seção de Termos de Uso
            _buildSectionTitle('Termos de Uso'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'Ao utilizar o DietaPro, você concorda com os seguintes termos:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              'Você utilizará o aplicativo apenas para fins pessoais e educacionais.',
            ),
            _buildBulletPoint(
              'Você não utilizará o aplicativo para fins comerciais sem autorização.',
            ),
            _buildBulletPoint(
              'Você é responsável por manter a confidencialidade de suas credenciais de acesso.',
            ),
            _buildBulletPoint(
              'Reservamo-nos o direito de modificar ou descontinuar o serviço a qualquer momento.',
            ),
            const SizedBox(height: 32),
            
            // Seção de Privacidade
            _buildSectionTitle('Privacidade e Dados'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'O DietaPro coleta e armazena seus dados de forma segura:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              'Seus dados pessoais e de saúde são armazenados de forma segura.',
            ),
            _buildBulletPoint(
              'Não compartilhamos seus dados com terceiros sem seu consentimento.',
            ),
            _buildBulletPoint(
              'Você pode solicitar a exclusão de seus dados a qualquer momento.',
            ),
            const SizedBox(height: 32),
            
            // Contato
            _buildSectionTitle('Contato'),
            const SizedBox(height: 16),
            _buildTextBlock(
              'Para questões sobre estes termos ou sobre o aplicativo, entre em contato através da seção de Ajuda no aplicativo.',
            ),
            const SizedBox(height: 32),
            
            // Data de atualização
            Center(
              child: Text(
                'Última atualização: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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

  Widget _buildTextBlock(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade800,
        height: 1.6,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

