import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../models/service_catalog.dart';

enum BookingStep { customerInfo, selectServices, selectDateTime, confirmation }

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  BookingStep _currentStep = BookingStep.customerInfo;
  bool _isLoading = false;
  String _statusMessage = '';

  // Customer info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected data
  Customer? _selectedCustomer;
  List<ServiceCatalog> _selectedServices = [];
  Employee? _selectedTechnician;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Available data
  List<Employee> _technicians = [];
  List<ServiceCatalog> _services = [];
  List<String> _availableTimeSlots = [];

  // Booking result
  Appointment? _createdAppointment;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final technicians = await FirebaseService.getEmployees();
      final services = await FirebaseService.getServices();

      setState(() {
        _technicians = technicians.where((t) => t.isActive).toList();
        _services = services.where((s) => s.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Book an Appointment'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 32 : 16),
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),
                    _buildCurrentStepContent(),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildStatusMessage(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepIndicator(0, BookingStep.customerInfo, 'Customer'),
        _buildStepConnector(0),
        _buildStepIndicator(1, BookingStep.selectServices, 'Services'),
        _buildStepConnector(1),
        _buildStepIndicator(2, BookingStep.selectDateTime, 'Date & Time'),
        _buildStepConnector(2),
        _buildStepIndicator(3, BookingStep.confirmation, 'Confirm'),
      ],
    );
  }

  Widget _buildStepIndicator(int index, BookingStep step, String title) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep.index > step.index;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Colors.blue.shade600
                  : Colors.grey.shade300,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: isCompleted || isActive
                  ? Colors.white
                  : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isCompleted || isActive
                  ? Colors.blue.shade700
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int index) {
    final isCompleted = _currentStep.index > index;

    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 32),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case BookingStep.customerInfo:
        return _buildCustomerInfoStep();
      case BookingStep.selectServices:
        return _buildSelectServicesStep();
      case BookingStep.selectDateTime:
        return _buildSelectDateTimeStep();
      case BookingStep.confirmation:
        return _buildConfirmationStep();
    }
  }

  Widget _buildCustomerInfoStep() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Information',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your contact information',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                  horizontal: 16,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
                hintText: '(555) 123-4567',
                contentPadding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                  horizontal: 16,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {});
                _checkExistingCustomer(value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address (optional)',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                hintText: 'your.email@example.com',
                contentPadding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                  horizontal: 16,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canProceedFromCustomerInfo()
                    ? _proceedToServices
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Services'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  textStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedFromCustomerInfo() {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  Future<void> _checkExistingCustomer(String phone) async {
    if (phone.replaceAll(RegExp(r'[^\d]'), '').length >= 10) {
      try {
        final customers = await FirebaseService.searchCustomersByPhone(phone);
        if (customers.isNotEmpty) {
          final customer = customers.first;
          setState(() {
            _selectedCustomer = customer;
            _nameController.text = customer.displayName;
            _emailController.text = customer.email ?? '';
          });
        }
      } catch (e) {
        // Ignore errors for customer lookup
      }
    }
  }

  void _proceedToServices() {
    setState(() {
      _currentStep = BookingStep.selectServices;
      _statusMessage = '';
    });
  }

  Widget _buildSelectServicesStep() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Services',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the services you would like to book',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ..._services.map((service) => _buildServiceTile(service, isTablet)),
            if (_selectedServices.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Services',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${service.name} - \$${service.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: isTablet ? 16 : 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${_getTotalPrice().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Estimated Duration: ${_getTotalDuration()} minutes',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goBackToCustomerInfo,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedServices.isNotEmpty
                        ? _proceedToDateTime
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Date & Time'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
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

  Widget _buildServiceTile(ServiceCatalog service, bool isTablet) {
    final isSelected = _selectedServices.any((s) => s.id == service.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedServices.add(service);
            } else {
              _selectedServices.removeWhere((s) => s.id == service.id);
            }
          });
        },
        title: Text(
          service.name,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.description.isNotEmpty)
              Text(
                service.description,
                style: TextStyle(fontSize: isTablet ? 14 : 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\$${service.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${service.durationMinutes} minutes',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  double _getTotalPrice() {
    return _selectedServices.fold(0.0, (sum, service) => sum + service.price);
  }

  int _getTotalDuration() {
    return _selectedServices.fold(
      0,
      (sum, service) => sum + service.durationMinutes,
    );
  }

  void _goBackToCustomerInfo() {
    setState(() {
      _currentStep = BookingStep.customerInfo;
      _statusMessage = '';
    });
  }

  void _proceedToDateTime() {
    setState(() {
      _currentStep = BookingStep.selectDateTime;
      _statusMessage = '';
    });
  }

  Widget _buildSelectDateTimeStep() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date & Time',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred technician, date, and time',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Technician selection
            Text(
              'Select Technician (Optional)',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // "Any Technician" option
            _buildAnyTechnicianTile(isTablet),

            ..._technicians.map((tech) => _buildTechnicianTile(tech, isTablet)),

            const SizedBox(height: 24),
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _buildDatePicker(isTablet),

            if (_selectedDate != null) ...[
              const SizedBox(height: 24),
              Text(
                'Available Time Slots',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeSlotGrid(isTablet),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goBackToServices,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _canProceedToConfirmation()
                        ? _proceedToConfirmation
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Confirmation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
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

  Widget _buildTechnicianTile(Employee technician, bool isTablet) {
    final isSelected = _selectedTechnician?.id == technician.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedTechnician = technician;
            _selectedDate = null;
            _selectedTimeSlot = null;
            _availableTimeSlots = [];
          });
        },
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.blue.shade600
              : Colors.grey.shade400,
          child: Text(
            technician.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          technician.name,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          technician.position,
          style: TextStyle(fontSize: isTablet ? 14 : 12),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue.shade600)
            : const Icon(Icons.circle_outlined),
      ),
    );
  }

  Widget _buildAnyTechnicianTile(bool isTablet) {
    final isSelected = _selectedTechnician == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.green.shade50 : null,
      child: ListTile(
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedTechnician = null;
            _selectedDate = null;
            _selectedTimeSlot = null;
            _availableTimeSlots = [];
          });
        },
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.green.shade600
              : Colors.grey.shade400,
          child: const Icon(Icons.people, color: Colors.white),
        ),
        title: Text(
          'Any Available Technician',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'We\'ll assign the best available technician for your appointment',
          style: TextStyle(fontSize: isTablet ? 14 : 12),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.green.shade600)
            : const Icon(Icons.circle_outlined),
      ),
    );
  }

  Widget _buildDatePicker(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CalendarDatePicker(
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)),
        onDateChanged: (date) async {
          setState(() {
            _selectedDate = date;
            _selectedTimeSlot = null;
            _isLoading = true;
          });

          try {
            final slots = await FirebaseService.getAvailableTimeSlots(
              _selectedTechnician?.id ?? 'any',
              date,
            );
            setState(() {
              _availableTimeSlots = slots;
              _isLoading = false;
            });
          } catch (e) {
            setState(() {
              _statusMessage = 'Error loading available time slots';
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeSlotGrid(bool isTablet) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableTimeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text(
          'No available time slots for this date. Please select another date.',
          style: TextStyle(color: Colors.orange),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _availableTimeSlots[index];
        final isSelected = _selectedTimeSlot == timeSlot;

        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTimeSlot = timeSlot;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade600 : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.blue.shade600,
            side: BorderSide(color: Colors.blue.shade600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            timeSlot,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  bool _canProceedToConfirmation() {
    return _selectedDate != null && _selectedTimeSlot != null;
  }

  void _goBackToServices() {
    setState(() {
      _currentStep = BookingStep.selectServices;
      _statusMessage = '';
    });
  }

  void _proceedToConfirmation() {
    setState(() {
      _currentStep = BookingStep.confirmation;
      _statusMessage = '';
    });
  }

  Widget _buildConfirmationStep() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (_createdAppointment != null) {
      return _buildBookingSuccess(isTablet);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Your Appointment',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),

            // Customer info summary
            _buildSummarySection('Customer Information', [
              'Name: ${_nameController.text}',
              'Phone: ${_phoneController.text}',
              if (_emailController.text.isNotEmpty)
                'Email: ${_emailController.text}',
            ], isTablet),

            const SizedBox(height: 16),

            // Services summary
            _buildSummarySection('Selected Services', [
              ..._selectedServices.map(
                (s) => '${s.name} - \$${s.price.toStringAsFixed(2)}',
              ),
              'Total: \$${_getTotalPrice().toStringAsFixed(2)}',
              'Duration: ${_getTotalDuration()} minutes',
            ], isTablet),

            const SizedBox(height: 16),

            // Appointment details summary
            _buildSummarySection('Appointment Details', [
              'Technician: ${_selectedTechnician?.name ?? 'Any Available Technician'}',
              'Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
              'Time: $_selectedTimeSlot',
            ], isTablet),

            const SizedBox(height: 24),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Special Notes (optional)',
                hintText: 'Any special requests or notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goBackToDateTime,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _bookAppointment,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Book Appointment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 12,
                      ),
                      textStyle: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSummarySection(String title, List<String> items, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(item, style: TextStyle(fontSize: isTablet ? 16 : 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _goBackToDateTime() {
    setState(() {
      _currentStep = BookingStep.selectDateTime;
      _statusMessage = '';
    });
  }

  Future<void> _bookAppointment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      // Create or get customer
      String customerId;
      if (_selectedCustomer != null) {
        customerId = _selectedCustomer!.id ?? '';
      } else {
        final newCustomer = Customer(
          id: '',
          firstName: _nameController.text.split(' ').first,
          lastName: _nameController.text.split(' ').skip(1).join(' '),
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          address: '',
          birthday: '01-01', // Default birthday
          loyaltyPoints: 0,
          totalSpent: 0,
          totalVisits: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        customerId = await FirebaseService.addCustomer(newCustomer);
      }

      // Create appointment
      final confirmationCode = FirebaseService.generateConfirmationCode();
      final appointment = Appointment(
        id: '',
        customerId: customerId,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerEmail: _emailController.text,
        technicianId: _selectedTechnician?.id ?? '',
        technicianName: _selectedTechnician?.name ?? 'Any Available Technician',
        serviceIds: _selectedServices.map((s) => s.id).toList(),
        serviceNames: _selectedServices.map((s) => s.name).toList(),
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        estimatedDuration: _getTotalDuration().toDouble(),
        estimatedPrice: _getTotalPrice(),
        status: AppointmentStatus.scheduled,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        confirmationCode: confirmationCode,
      );

      print(
        'Booking: Creating appointment with date: ${_selectedDate!.toIso8601String()}',
      );
      print('Booking: Appointment data: ${appointment.toJson()}');

      final appointmentId = await FirebaseService.createAppointment(
        appointment,
      );
      final createdAppointment = appointment.copyWith(id: appointmentId);

      setState(() {
        _createdAppointment = createdAppointment;
        _isLoading = false;
      });

      // Haptic feedback for success
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error booking appointment: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildBookingSuccess(bool isTablet) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 3),
              ),
              child: Icon(
                Icons.check_circle,
                size: isTablet ? 64 : 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Appointment Booked!',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
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
                    'Confirmation Code',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _createdAppointment!.confirmationCode!,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your appointment is scheduled for:',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _createdAppointment!.formattedDateTime,
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'with ${_createdAppointment!.technicianName}',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.yellow.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Please save your confirmation code and arrive 5 minutes early for your appointment.',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.yellow.shade700,
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
                onPressed: _bookAnotherAppointment,
                icon: const Icon(Icons.add),
                label: const Text('Book Another Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAnotherAppointment() {
    setState(() {
      _currentStep = BookingStep.customerInfo;
      _createdAppointment = null;
      _selectedCustomer = null;
      _selectedServices.clear();
      _selectedTechnician = null;
      _selectedDate = null;
      _selectedTimeSlot = null;
      _availableTimeSlots.clear();
      _statusMessage = '';

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _notesController.clear();
    });
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
