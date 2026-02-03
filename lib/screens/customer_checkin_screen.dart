import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../models/customer.dart';
import '../models/service_order.dart';

enum CheckinState { enterPhone, createCustomer, checkedIn }

class OnScreenKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const OnScreenKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Number rows
          _buildKeyboardRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['7', '8', '9']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['*', '0', '#']),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionKey(
                  'Clear',
                  Icons.clear_all,
                  Colors.orange,
                  onClear,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionKey(
                  'Delete',
                  Icons.backspace,
                  Colors.red,
                  onBackspace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onKeyPressed(key);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          key,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionKey(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerCheckinScreen extends StatefulWidget {
  const CustomerCheckinScreen({super.key});

  @override
  State<CustomerCheckinScreen> createState() => _CustomerCheckinScreenState();
}

class _CustomerCheckinScreenState extends State<CustomerCheckinScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  CheckinState _currentState = CheckinState.enterPhone;
  bool _isLoading = false;
  String _statusMessage = '';
  Customer? _currentCustomer;
  String _enteredPhone = '';
  bool _showKeyboard = false;

  // Birthday dropdowns
  int? _selectedMonth;
  int? _selectedDay;

  // Month names for display
  final List<String> _monthNames = [
    '01 - January',
    '02 - February',
    '03 - March',
    '04 - April',
    '05 - May',
    '06 - June',
    '07 - July',
    '08 - August',
    '09 - September',
    '10 - October',
    '11 - November',
    '12 - December',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Customer Check-in Kiosk'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        toolbarHeight: isTablet ? 80 : 56,
        titleTextStyle: TextStyle(
          fontSize: isTablet ? 28 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(isTablet ? 32 : 16),
          child: isLandscape && _currentState == CheckinState.enterPhone
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildCurrentStateContent()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildOnScreenKeyboard()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildCurrentStateContent()),
                    if (_showKeyboard &&
                        _currentState == CheckinState.enterPhone) ...[
                      const SizedBox(height: 16),
                      _buildOnScreenKeyboard(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateContent() {
    switch (_currentState) {
      case CheckinState.enterPhone:
        return _buildPhoneEntryScreen();
      case CheckinState.createCustomer:
        return _buildCreateCustomerScreen();
      case CheckinState.checkedIn:
        return _buildCheckedInScreen();
    }
  }

  Widget _buildPhoneEntryScreen() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store,
              size: isTablet ? 80 : 60,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Bluestar POS',
              style: TextStyle(
                fontSize: isTablet ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Touch to Check In',
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.blue.shade600,
                    size: isTablet ? 32 : 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _phoneController.text.isEmpty
                          ? 'Enter your phone number'
                          : _formatPhoneDisplay(_phoneController.text),
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: _phoneController.text.isEmpty
                            ? Colors.grey.shade500
                            : Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!MediaQuery.of(
              context,
            ).orientation.name.contains('landscape')) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showKeyboard = !_showKeyboard;
                        });
                      },
                      icon: Icon(
                        _showKeyboard ? Icons.keyboard_hide : Icons.keyboard,
                      ),
                      label: Text(
                        _showKeyboard ? 'Hide Keypad' : 'Show Keypad',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.grey.shade700,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 16,
                        ),
                        textStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _phoneController.text.isNotEmpty
                          ? _handlePhoneSubmit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 16,
                        ),
                        textStyle: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Check In'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Landscape mode - show button inline
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _phoneController.text.isNotEmpty
                      ? _handlePhoneSubmit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                    textStyle: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Check In'),
                ),
              ),
            ],
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPhoneDisplay(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.length >= 10) {
      // Format as (XXX) XXX-XXXX
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
    } else if (digits.length >= 6) {
      // Format as (XXX) XXX-
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length >= 3) {
      // Format as (XXX)
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      return digits;
    }
  }

  Widget _buildOnScreenKeyboard() {
    return OnScreenKeyboard(
      onKeyPressed: (key) {
        setState(() {
          _phoneController.text += key;
          _checkAutoSubmit();
        });
      },
      onBackspace: () {
        setState(() {
          if (_phoneController.text.isNotEmpty) {
            _phoneController.text = _phoneController.text.substring(
              0,
              _phoneController.text.length - 1,
            );
          }
        });
      },
      onClear: () {
        setState(() {
          _phoneController.clear();
          _statusMessage = '';
        });
      },
    );
  }

  void _checkAutoSubmit() {
    // Auto-submit when 10 digits are entered
    String digits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10 && !_isLoading) {
      // Small delay to let user see the formatted number
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && digits.length == 10) {
          _handlePhoneSubmit();
        }
      });
    }
  }

  List<int> _getDaysForMonth(int month) {
    // Days in each month (not accounting for leap years since we don't use year)
    const daysInMonth = {
      1: 31,
      2: 29,
      3: 31,
      4: 30,
      5: 31,
      6: 30,
      7: 31,
      8: 31,
      9: 30,
      10: 31,
      11: 30,
      12: 31,
    };

    int maxDays = daysInMonth[month] ?? 31;
    return List.generate(maxDays, (index) => index + 1);
  }

  bool _isCreateCustomerFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _selectedMonth != null &&
        _selectedDay != null;
  }

  Widget _buildCreateCustomerScreen() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add,
              size: isTablet ? 64 : 48,
              color: Colors.orange.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'New Customer Setup',
              style: TextStyle(
                fontSize: isTablet ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll create your account to get you checked in',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.blue.shade600,
                    size: isTablet ? 28 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatPhoneDisplay(_enteredPhone),
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Your Full Name',
                hintText: 'Enter your first and last name',
                prefixIcon: Icon(Icons.person, size: isTablet ? 28 : 24),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isTablet ? 20 : 16,
                  horizontal: 16,
                ),
                labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                hintStyle: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: TextStyle(fontSize: isTablet ? 20 : 18),
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Birthday section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cake,
                        color: Colors.blue.shade600,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Birthday (Month & Day)',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We use this for birthday promotions and special offers',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Month',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                              horizontal: 12,
                            ),
                          ),
                          value: _selectedMonth,
                          items: List.generate(12, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(
                                _monthNames[index],
                                style: TextStyle(fontSize: isTablet ? 16 : 14),
                              ),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Day',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                              horizontal: 12,
                            ),
                          ),
                          value: _selectedDay,
                          items: _getDaysForMonth(_selectedMonth ?? 1).map((
                            day,
                          ) {
                            return DropdownMenuItem<int>(
                              value: day,
                              child: Text(
                                day.toString().padLeft(2, '0'),
                                style: TextStyle(fontSize: isTablet ? 16 : 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDay = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentState = CheckinState.enterPhone;
                        _nameController.clear();
                        _selectedMonth = null;
                        _selectedDay = null;
                        _statusMessage = '';
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 20 : 16,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isCreateCustomerFormValid()
                        ? _handleCreateCustomer
                        : null,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Create & Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 20 : 16,
                      ),
                      textStyle: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedInScreen() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 3),
              ),
              child: Icon(
                Icons.check_circle,
                size: isTablet ? 80 : 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '✓ Check-in Complete!',
              style: TextStyle(
                fontSize: isTablet ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentCustomer != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentCustomer!.displayName,
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    if (_currentCustomer!.loyaltyPoints > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_currentCustomer!.loyaltyPoints} Loyalty Points',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: isTablet ? 40 : 32,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your service order has been created!',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please have a seat and our team will be with you shortly.',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetToStart,
                icon: const Icon(Icons.refresh),
                label: const Text('Check In Another Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                  textStyle: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _enteredPhone = phone;
    });

    try {
      final customers = await FirebaseService.searchCustomersByPhone(phone);

      if (customers.isNotEmpty) {
        final customer = customers.first;
        await _createCheckinOrder(customer);

        setState(() {
          _currentCustomer = customer;
          _currentState = CheckinState.checkedIn;
          _isLoading = false;
        });

        // Auto-reset after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _currentState == CheckinState.checkedIn) {
            _resetToStart();
          }
        });
      } else {
        setState(() {
          _currentState = CheckinState.createCustomer;
          _nameController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during check-in: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateCustomer() async {
    if (!_isCreateCustomerFormValid()) {
      setState(() {
        _statusMessage = 'Please fill in all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Format birthday as MM-dd
      final birthdayString =
          '${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}';

      final newCustomer = Customer(
        id: '',
        firstName: firstName,
        lastName: lastName,
        phone: _enteredPhone,
        email: '',
        address: '',
        birthday: birthdayString,
        loyaltyPoints: 0,
        totalSpent: 0,
        totalVisits: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customerId = await FirebaseService.addCustomer(newCustomer);
      final createdCustomer = newCustomer.copyWith(id: customerId);

      await _createCheckinOrder(createdCustomer);

      setState(() {
        _currentCustomer = createdCustomer;
        _currentState = CheckinState.checkedIn;
        _isLoading = false;
      });

      // Auto-reset after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _currentState == CheckinState.checkedIn) {
          _resetToStart();
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating customer: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createCheckinOrder(Customer customer) async {
    try {
      final orderNumber = await FirebaseService.generateDailyOrderNumber();

      final order = ServiceOrder(
        id: '',
        orderNumber: orderNumber,
        customerId: customer.id,
        customerName: customer.displayName,
        serviceOrderItemIds: [],
        subtotal: 0.0,
        taxAmount: 0.0,
        total: 0.0,
        status: ServiceOrderStatus.inProgress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: 'Customer checked in via kiosk',
      );

      await FirebaseService.createServiceOrder(order);
    } catch (e) {
      print('Error creating check-in order: $e');
      rethrow;
    }
  }

  void _resetToStart() {
    setState(() {
      _currentState = CheckinState.enterPhone;
      _phoneController.clear();
      _nameController.clear();
      _selectedMonth = null;
      _selectedDay = null;
      _showKeyboard = false;
      _isLoading = false;
      _statusMessage = '';
      _currentCustomer = null;
      _enteredPhone = '';
    });
  }
}
