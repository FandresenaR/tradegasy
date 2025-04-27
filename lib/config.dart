class AppConfig {
  // API keys
  // Note: These are still stored as strings as API keys are typically string values
  // even if they contain alphanumeric characters
  static const String binanceApiKey =
      'aGtI2msB2h9ekyvS59e8yLxET2gbEfflLLprxrPWqQ68zRxuMMSRjSWae2jAL1HA';
  static const String binanceApiSecret =
      'k3YP4bLFfS3UuhlrZWS80ZH5rwipY1wa44HAuUmj90HAEsedF4Le4pJ0vd8IAAtI';
  static const String openrouterApiKey =
      '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';

  // If you need to use these keys in places expecting numerical values (although unusual for API keys)
  // you could provide helper methods, but this is generally not recommended
  // as API keys should be treated as opaque strings
}
