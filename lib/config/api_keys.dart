class ApiKeys {
  static const String exerciseDbRapidApiKey =
      String.fromEnvironment('EXERCISE_DB_API_KEY', defaultValue: '');
  static const String exerciseDbRapidApiHost = 'exercisedb.p.rapidapi.com';
  static const String brevoApiKey =
      String.fromEnvironment('BREVO_API_KEY', defaultValue: '');
  static const String brevoSenderEmail =
      String.fromEnvironment('BREVO_SENDER_EMAIL', defaultValue: '');
  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
}

const String groqApiKey =
    String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
