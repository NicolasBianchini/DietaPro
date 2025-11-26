/// Configuração da API do Gemini
/// 
/// Este arquivo centraliza as configurações relacionadas à API do Gemini.
/// A chave API deve ser configurada no arquivo .env na raiz do projeto.
class ApiConfig {
  /// Nome da variável de ambiente para a chave API do Gemini
  static const String geminiApiKeyEnv = 'GEMINI_API_KEY';
  
  /// Modelo do Gemini a ser utilizado (o serviço tentará múltiplos modelos automaticamente)
  /// Lista de modelos tentados em ordem: gemini-1.5-flash-latest, gemini-1.5-flash, gemini-1.5-pro-latest, gemini-1.5-pro, gemini-pro, gemini-2.0-flash-exp
  static const String geminiModel = 'gemini-1.5-flash-latest';
  
  /// Timeout padrão para requisições (em segundos)
  static const int defaultTimeout = 30;
  
  /// Verifica se a chave API está configurada
  static bool isApiKeyConfigured(String? apiKey) {
    return apiKey != null && apiKey.isNotEmpty;
  }
}

