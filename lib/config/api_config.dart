/// Configuração da API do Gemini
/// 
/// Este arquivo centraliza as configurações relacionadas à API do Gemini.
/// A chave API deve ser configurada no arquivo .env na raiz do projeto.
class ApiConfig {
  /// Nome da variável de ambiente para a chave API do Gemini
  static const String geminiApiKeyEnv = 'GEMINI_API_KEY';
  
  /// Modelo do Gemini a ser utilizado
  static const String geminiModel = 'gemini-pro';
  
  /// Timeout padrão para requisições (em segundos)
  static const int defaultTimeout = 30;
  
  /// Verifica se a chave API está configurada
  static bool isApiKeyConfigured(String? apiKey) {
    return apiKey != null && apiKey.isNotEmpty;
  }
}

