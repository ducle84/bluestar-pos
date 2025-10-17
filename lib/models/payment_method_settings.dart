class PaymentMethodSettings {
  final CashRegisterSettings cashRegister;
  final CreditCardSettings creditCard;

  PaymentMethodSettings({
    required this.cashRegister,
    required this.creditCard,
  });

  factory PaymentMethodSettings.fromMap(Map<String, dynamic> data) {
    return PaymentMethodSettings(
      cashRegister: CashRegisterSettings.fromMap(data['cashRegister'] ?? {}),
      creditCard: CreditCardSettings.fromMap(data['creditCard'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cashRegister': cashRegister.toMap(),
      'creditCard': creditCard.toMap(),
    };
  }

  PaymentMethodSettings copyWith({
    CashRegisterSettings? cashRegister,
    CreditCardSettings? creditCard,
  }) {
    return PaymentMethodSettings(
      cashRegister: cashRegister ?? this.cashRegister,
      creditCard: creditCard ?? this.creditCard,
    );
  }
}

class CashRegisterSettings {
  final bool enabled;
  final String connectionType; // 'Serial', 'USB', 'Network'
  final String port; // COM1, USB device ID, or IP address
  final int baudRate; // For serial connections
  final String openCommand; // ESC/POS command to open drawer

  CashRegisterSettings({
    this.enabled = false,
    this.connectionType = 'Serial',
    this.port = 'COM1',
    this.baudRate = 9600,
    this.openCommand = '\x1B\x70\x00\x19\xFA',
  });

  factory CashRegisterSettings.fromMap(Map<String, dynamic> data) {
    return CashRegisterSettings(
      enabled: data['enabled'] ?? false,
      connectionType: data['connectionType'] ?? 'Serial',
      port: data['port'] ?? 'COM1',
      baudRate: data['baudRate'] ?? 9600,
      openCommand: data['openCommand'] ?? '\x1B\x70\x00\x19\xFA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'connectionType': connectionType,
      'port': port,
      'baudRate': baudRate,
      'openCommand': openCommand,
    };
  }

  CashRegisterSettings copyWith({
    bool? enabled,
    String? connectionType,
    String? port,
    int? baudRate,
    String? openCommand,
  }) {
    return CashRegisterSettings(
      enabled: enabled ?? this.enabled,
      connectionType: connectionType ?? this.connectionType,
      port: port ?? this.port,
      baudRate: baudRate ?? this.baudRate,
      openCommand: openCommand ?? this.openCommand,
    );
  }
}

class CreditCardSettings {
  final bool enabled;
  final String processor; // 'Square', 'Stripe', 'PayPal', 'Clover', 'Generic'
  final String deviceType; // 'USB', 'Bluetooth', 'Network', 'Serial'
  final String connectionString; // Device-specific connection info
  final String apiKey;
  final String applicationId;
  final bool testMode;

  CreditCardSettings({
    this.enabled = false,
    this.processor = 'Square',
    this.deviceType = 'USB',
    this.connectionString = '',
    this.apiKey = '',
    this.applicationId = '',
    this.testMode = true,
  });

  factory CreditCardSettings.fromMap(Map<String, dynamic> data) {
    return CreditCardSettings(
      enabled: data['enabled'] ?? false,
      processor: data['processor'] ?? 'Square',
      deviceType: data['deviceType'] ?? 'USB',
      connectionString: data['connectionString'] ?? '',
      apiKey: data['apiKey'] ?? '',
      applicationId: data['applicationId'] ?? '',
      testMode: data['testMode'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'processor': processor,
      'deviceType': deviceType,
      'connectionString': connectionString,
      'apiKey': apiKey,
      'applicationId': applicationId,
      'testMode': testMode,
    };
  }

  CreditCardSettings copyWith({
    bool? enabled,
    String? processor,
    String? deviceType,
    String? connectionString,
    String? apiKey,
    String? applicationId,
    bool? testMode,
  }) {
    return CreditCardSettings(
      enabled: enabled ?? this.enabled,
      processor: processor ?? this.processor,
      deviceType: deviceType ?? this.deviceType,
      connectionString: connectionString ?? this.connectionString,
      apiKey: apiKey ?? this.apiKey,
      applicationId: applicationId ?? this.applicationId,
      testMode: testMode ?? this.testMode,
    );
  }
}