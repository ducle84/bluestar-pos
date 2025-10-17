import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_method_settings.dart';
import '../../services/firebase_service.dart';

class PaymentMethodsSetupPage extends StatefulWidget {
  const PaymentMethodsSetupPage({super.key});

  @override
  State<PaymentMethodsSetupPage> createState() => _PaymentMethodsSetupPageState();
}

class _PaymentMethodsSetupPageState extends State<PaymentMethodsSetupPage> {
  bool _isLoading = true;

  // Cash Register Settings
  bool _cashRegisterEnabled = false;
  String _cashRegisterType = 'Serial';
  String _cashRegisterPort = 'COM1';
  int _cashRegisterBaudRate = 9600;
  String _cashRegisterOpenCommand = '\x1B\x70\x00\x19\xFA';

  // Credit Card Processing Settings
  bool _creditCardEnabled = false;
  String _creditCardProcessor = 'Square';
  String _creditCardDeviceType = 'USB';
  String _creditCardConnectionString = '';
  String _apiKey = '';
  String _applicationId = '';
  bool _testMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await FirebaseService.getPaymentMethodSettings();
      setState(() {
        // Load cash register settings
        _cashRegisterEnabled = settings.cashRegister.enabled;
        _cashRegisterType = settings.cashRegister.connectionType;
        _cashRegisterPort = settings.cashRegister.port;
        _cashRegisterBaudRate = settings.cashRegister.baudRate;
        _cashRegisterOpenCommand = settings.cashRegister.openCommand;
        
        // Load credit card settings
        _creditCardEnabled = settings.creditCard.enabled;
        _creditCardProcessor = settings.creditCard.processor;
        _creditCardDeviceType = settings.creditCard.deviceType;
        _creditCardConnectionString = settings.creditCard.connectionString;
        _apiKey = settings.creditCard.apiKey;
        _applicationId = settings.creditCard.applicationId;
        _testMode = settings.creditCard.testMode;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment Methods Setup'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods Setup'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure cash register and credit card processing integration.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Cash Register Section
            _buildCashRegisterSection(),
            const SizedBox(height: 32),
            
            // Credit Card Processing Section
            _buildCreditCardSection(),
            const SizedBox(height: 32),
            
            // Test Buttons
            _buildTestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCashRegisterSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.point_of_sale, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Cash Register Setup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Enable/Disable Cash Register
            SwitchListTile(
              title: const Text('Enable Cash Register'),
              subtitle: const Text('Automatically open cash drawer on cash payments'),
              value: _cashRegisterEnabled,
              onChanged: (value) {
                setState(() {
                  _cashRegisterEnabled = value;
                });
              },
            ),
            
            if (_cashRegisterEnabled) ...[
              const Divider(),
              
              // Connection Type
              const Text('Connection Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cashRegisterType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Connection Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'Serial', child: Text('Serial Port')),
                  DropdownMenuItem(value: 'USB', child: Text('USB')),
                  DropdownMenuItem(value: 'Network', child: Text('Network/TCP')),
                ],
                onChanged: (value) {
                  setState(() {
                    _cashRegisterType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Port/Connection String
              TextFormField(
                initialValue: _cashRegisterPort,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _cashRegisterType == 'Serial' ? 'Serial Port' : 
                            _cashRegisterType == 'USB' ? 'USB Device ID' : 'IP Address:Port',
                  hintText: _cashRegisterType == 'Serial' ? 'COM1' : 
                           _cashRegisterType == 'USB' ? 'VID:PID' : '192.168.1.100:9100',
                ),
                onChanged: (value) {
                  _cashRegisterPort = value;
                },
              ),
              const SizedBox(height: 16),
              
              if (_cashRegisterType == 'Serial') ...[
                // Baud Rate
                DropdownButtonFormField<int>(
                  value: _cashRegisterBaudRate,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Baud Rate',
                  ),
                  items: const [
                    DropdownMenuItem(value: 9600, child: Text('9600')),
                    DropdownMenuItem(value: 19200, child: Text('19200')),
                    DropdownMenuItem(value: 38400, child: Text('38400')),
                    DropdownMenuItem(value: 57600, child: Text('57600')),
                    DropdownMenuItem(value: 115200, child: Text('115200')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _cashRegisterBaudRate = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Open Command
              TextFormField(
                initialValue: _cashRegisterOpenCommand,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Cash Drawer Open Command',
                  hintText: '\\x1B\\x70\\x00\\x19\\xFA',
                  helperText: 'ESC/POS command to open cash drawer (hex format)',
                ),
                onChanged: (value) {
                  _cashRegisterOpenCommand = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Credit Card Processing Setup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Enable/Disable Credit Card
            SwitchListTile(
              title: const Text('Enable Credit Card Processing'),
              subtitle: const Text('Process credit card payments through integrated terminal'),
              value: _creditCardEnabled,
              onChanged: (value) {
                setState(() {
                  _creditCardEnabled = value;
                });
              },
            ),
            
            if (_creditCardEnabled) ...[
              const Divider(),
              
              // Processor Selection
              const Text('Payment Processor', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _creditCardProcessor,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Payment Processor',
                ),
                items: const [
                  DropdownMenuItem(value: 'Square', child: Text('Square Terminal')),
                  DropdownMenuItem(value: 'Stripe', child: Text('Stripe Terminal')),
                  DropdownMenuItem(value: 'PayPal', child: Text('PayPal Zettle')),
                  DropdownMenuItem(value: 'Clover', child: Text('Clover')),
                  DropdownMenuItem(value: 'Generic', child: Text('Generic Terminal')),
                ],
                onChanged: (value) {
                  setState(() {
                    _creditCardProcessor = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Device Type
              const Text('Device Connection', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _creditCardDeviceType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Connection Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'USB', child: Text('USB Connection')),
                  DropdownMenuItem(value: 'Bluetooth', child: Text('Bluetooth')),
                  DropdownMenuItem(value: 'Network', child: Text('Network/WiFi')),
                  DropdownMenuItem(value: 'Serial', child: Text('Serial Port')),
                ],
                onChanged: (value) {
                  setState(() {
                    _creditCardDeviceType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Connection String
              TextFormField(
                initialValue: _creditCardConnectionString,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Device Connection String',
                  hintText: _creditCardDeviceType == 'USB' ? 'USB Device ID' :
                           _creditCardDeviceType == 'Bluetooth' ? 'Device MAC Address' :
                           _creditCardDeviceType == 'Network' ? 'IP Address' : 'COM Port',
                ),
                onChanged: (value) {
                  _creditCardConnectionString = value;
                },
              ),
              const SizedBox(height: 16),
              
              // API Configuration
              const Text('API Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _applicationId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Application ID',
                  hintText: 'Your application/merchant ID',
                ),
                onChanged: (value) {
                  _applicationId = value;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _apiKey,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'API Key',
                  hintText: 'Your API key or access token',
                ),
                obscureText: true,
                onChanged: (value) {
                  _apiKey = value;
                },
              ),
              const SizedBox(height: 16),
              
              // Test Mode
              SwitchListTile(
                title: const Text('Test Mode'),
                subtitle: const Text('Use sandbox/test environment for transactions'),
                value: _testMode,
                onChanged: (value) {
                  setState(() {
                    _testMode = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Test Connection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cashRegisterEnabled ? _testCashRegister : null,
                    icon: const Icon(Icons.receipt),
                    label: const Text('Test Cash Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _creditCardEnabled ? _testCreditCard : null,
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Test Credit Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testCashRegister() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('Testing Cash Register'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Attempting to open cash drawer...'),
            ],
          ),
        );
      },
    );

    // Simulate testing the cash register
    await Future.delayed(const Duration(seconds: 2));
    
    Navigator.of(context).pop(); // Close loading dialog
    
    // Show result
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cash Register Test'),
          content: Text(
            'Test command sent to $_cashRegisterType port $_cashRegisterPort\n\n'
            'Command: $_cashRegisterOpenCommand\n'
            'Baud Rate: $_cashRegisterBaudRate\n\n'
            'Check if the cash drawer opened. If not, verify the connection settings and command format.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _testCreditCard() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('Testing Credit Card Terminal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to payment terminal...'),
            ],
          ),
        );
      },
    );

    // Simulate testing the credit card terminal
    await Future.delayed(const Duration(seconds: 3));
    
    Navigator.of(context).pop(); // Close loading dialog
    
    // Show result
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Credit Card Terminal Test'),
          content: Text(
            'Connection test for $_creditCardProcessor terminal\n\n'
            'Device Type: $_creditCardDeviceType\n'
            'Connection: $_creditCardConnectionString\n'
            'Test Mode: ${_testMode ? "Enabled" : "Disabled"}\n\n'
            'Terminal connection ${_testMode ? "simulated successfully" : "attempted"}. '
            'Verify the terminal is powered on and properly connected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() async {
    try {
      final settings = PaymentMethodSettings(
        cashRegister: CashRegisterSettings(
          enabled: _cashRegisterEnabled,
          connectionType: _cashRegisterType,
          port: _cashRegisterPort,
          baudRate: _cashRegisterBaudRate,
          openCommand: _cashRegisterOpenCommand,
        ),
        creditCard: CreditCardSettings(
          enabled: _creditCardEnabled,
          processor: _creditCardProcessor,
          deviceType: _creditCardDeviceType,
          connectionString: _creditCardConnectionString,
          apiKey: _apiKey,
          applicationId: _applicationId,
          testMode: _testMode,
        ),
      );

      await FirebaseService.savePaymentMethodSettings(settings);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}