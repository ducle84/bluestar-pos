import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/service_catalog.dart';
import '../models/employee.dart';
import '../models/customer.dart';
import '../models/service_order.dart';
import '../models/service_order_item.dart';
import '../models/appointment.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _categoriesCollection = 'categories';
  static const String _servicesCollection = 'services';
  static const String _employeesCollection = 'employees';
  static const String _customersCollection = 'customers';
  static const String _serviceOrdersCollection = 'service_orders';
  static const String _serviceOrderItemsCollection = 'service_order_items';
  static const String _appointmentsCollection = 'appointments';

  // Categories CRUD operations
  static Future<List<Category>> getCategories() async {
    try {
      print('Fetching categories from Firebase...');
      final snapshot = await _firestore
          .collection(_categoriesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${snapshot.docs.length} categories in Firebase');
      final categories = snapshot.docs
          .map((doc) => Category.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by name in code to avoid index requirements
      categories.sort((a, b) => a.name.compareTo(b.name));

      for (final category in categories) {
        print('Category: ${category.name} (ID: ${category.id})');
      }

      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  static Future<void> saveCategory(Category category) async {
    try {
      print('Saving category: ${category.name} with ID: ${category.id}');
      await _firestore
          .collection(_categoriesCollection)
          .doc(category.id)
          .set(category.toMap(), SetOptions(merge: true));
      print('Category saved successfully: ${category.name}');
    } catch (e) {
      print('Error saving category: $e');
      throw Exception('Failed to save category: $e');
    }
  }

  static Future<void> deleteCategory(String categoryId) async {
    try {
      // Check if category is being used by any services
      final servicesUsingCategory = await _firestore
          .collection(_servicesCollection)
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      if (servicesUsingCategory.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete category: It is being used by ${servicesUsingCategory.docs.length} service(s)',
        );
      }

      // Soft delete by setting isActive to false
      await _firestore.collection(_categoriesCollection).doc(categoryId).update(
        {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('Failed to delete category: $e');
    }
  }

  // Services CRUD operations
  static Future<List<ServiceCatalog>> getServices() async {
    try {
      print('Fetching services from Firebase...');
      final snapshot = await _firestore
          .collection(_servicesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${snapshot.docs.length} services in Firebase');
      final services = snapshot.docs
          .map((doc) => ServiceCatalog.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by name in code to avoid index requirements
      services.sort((a, b) => a.name.compareTo(b.name));

      for (final service in services) {
        print('Service: ${service.name} (ID: ${service.id})');
      }

      return services;
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  static Future<void> saveService(ServiceCatalog service) async {
    try {
      await _firestore
          .collection(_servicesCollection)
          .doc(service.id)
          .set(service.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving service: $e');
      throw Exception('Failed to save service: $e');
    }
  }

  static Future<void> deleteService(String serviceId) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection(_servicesCollection).doc(serviceId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting service: $e');
      throw Exception('Failed to delete service: $e');
    }
  }

  // Stream methods for real-time updates
  static Stream<List<Category>> getCategoriesStream() {
    return _firestore
        .collection(_categoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  static Stream<List<ServiceCatalog>> getServicesStream() {
    return _firestore
        .collection(_servicesCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs
              .map(
                (doc) => ServiceCatalog.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList();

          // Sort by name in code to avoid index requirements
          services.sort((a, b) => a.name.compareTo(b.name));

          return services;
        });
  }

  // Employees CRUD operations
  static Future<List<Employee>> getEmployees() async {
    try {
      print('Fetching employees from Firebase...');
      final snapshot = await _firestore
          .collection(_employeesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${snapshot.docs.length} employees in Firebase');
      final employees = snapshot.docs
          .map((doc) => Employee.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by name in code to avoid index requirements
      employees.sort((a, b) => a.name.compareTo(b.name));

      for (final employee in employees) {
        print('Employee: ${employee.name} (ID: ${employee.id})');
      }

      return employees;
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  static Future<void> saveEmployee(Employee employee) async {
    try {
      print('Saving employee: ${employee.name} with ID: ${employee.id}');
      await _firestore
          .collection(_employeesCollection)
          .doc(employee.id)
          .set(employee.toMap(), SetOptions(merge: true));
      print('Employee saved successfully: ${employee.name}');
    } catch (e) {
      print('Error saving employee: $e');
      throw Exception('Failed to save employee: $e');
    }
  }

  static Future<void> deleteEmployee(String employeeId) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection(_employeesCollection).doc(employeeId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Employee soft deleted: $employeeId');
    } catch (e) {
      print('Error deleting employee: $e');
      throw Exception('Failed to delete employee: $e');
    }
  }

  // Customer CRUD operations
  static Future<List<Customer>> getCustomers() async {
    try {
      print('Fetching customers from Firebase...');
      final snapshot = await _firestore
          .collection(_customersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${snapshot.docs.length} customers in Firebase');
      final customers = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();

      // Sort by last name, then first name in code
      customers.sort((a, b) {
        final lastNameComparison = a.lastName.compareTo(b.lastName);
        if (lastNameComparison != 0) return lastNameComparison;
        return a.firstName.compareTo(b.firstName);
      });

      return customers;
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  static Future<Customer?> getCustomer(String customerId) async {
    try {
      final doc = await _firestore
          .collection(_customersCollection)
          .doc(customerId)
          .get();

      if (doc.exists) {
        return Customer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching customer: $e');
      return null;
    }
  }

  static Future<String> addCustomer(Customer customer) async {
    try {
      print('Adding customer: ${customer.displayName}');
      final docRef = await _firestore
          .collection(_customersCollection)
          .add(customer.toMap());
      print('Customer added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding customer: $e');
      throw Exception('Failed to add customer: $e');
    }
  }

  static Future<void> saveCustomer(Customer customer) async {
    try {
      print('Saving customer: ${customer.displayName} with ID: ${customer.id}');
      await _firestore
          .collection(_customersCollection)
          .doc(customer.id)
          .set(customer.toMap(), SetOptions(merge: true));
      print('Customer saved successfully: ${customer.displayName}');
    } catch (e) {
      print('Error saving customer: $e');
      throw Exception('Failed to save customer: $e');
    }
  }

  static Future<void> deleteCustomer(String customerId) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection(_customersCollection).doc(customerId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Customer soft deleted: $customerId');
    } catch (e) {
      print('Error deleting customer: $e');
      throw Exception('Failed to delete customer: $e');
    }
  }

  static Future<void> updateCustomerLoyaltyPoints(
    String customerId,
    int pointsToAdd,
    double totalSpent,
  ) async {
    try {
      await _firestore.collection(_customersCollection).doc(customerId).update({
        'loyaltyPoints': FieldValue.increment(pointsToAdd),
        'totalSpent': FieldValue.increment(totalSpent),
        'totalVisits': FieldValue.increment(1),
        'lastVisit': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        'Customer loyalty points updated: $customerId (+$pointsToAdd points, +\$${totalSpent.toStringAsFixed(2)})',
      );
    } catch (e) {
      print('Error updating customer loyalty points: $e');
      throw Exception('Failed to update customer loyalty points: $e');
    }
  }

  // Additional customer methods for check-in system
  static Future<List<Customer>> searchCustomersByPhone(String phone) async {
    try {
      print('Searching for customers with phone: $phone');

      // Search for exact match first
      QuerySnapshot snapshot = await _firestore
          .collection(_customersCollection)
          .where('phone', isEqualTo: phone)
          .where('isActive', isEqualTo: true)
          .get();

      List<Customer> customers = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();

      // If no exact match, try searching by phone without formatting
      if (customers.isEmpty) {
        final phoneDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
        if (phoneDigits.length == 10) {
          // Try different phone formats
          final formats = [
            phoneDigits,
            '${phoneDigits.substring(0, 3)}-${phoneDigits.substring(3, 6)}-${phoneDigits.substring(6)}',
            '${phoneDigits.substring(0, 3)}.${phoneDigits.substring(3, 6)}.${phoneDigits.substring(6)}',
            '${phoneDigits.substring(0, 3)} ${phoneDigits.substring(3, 6)} ${phoneDigits.substring(6)}',
            '(${phoneDigits.substring(0, 3)}) ${phoneDigits.substring(3, 6)}-${phoneDigits.substring(6)}',
            '+1${phoneDigits}',
          ];

          for (String format in formats) {
            snapshot = await _firestore
                .collection(_customersCollection)
                .where('phone', isEqualTo: format)
                .where('isActive', isEqualTo: true)
                .get();

            if (snapshot.docs.isNotEmpty) {
              customers = snapshot.docs
                  .map((doc) => Customer.fromFirestore(doc))
                  .toList();
              break;
            }
          }
        }
      }

      print('Found ${customers.length} customers with phone: $phone');
      return customers;
    } catch (e) {
      print('Error searching customers by phone: $e');
      return [];
    }
  }

  static Future<void> updateCustomer(
    String customerId,
    Customer customer,
  ) async {
    try {
      await _firestore.collection(_customersCollection).doc(customerId).update({
        ...customer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Customer updated: $customerId');
    } catch (e) {
      print('Error updating customer: $e');
      throw Exception('Failed to update customer: $e');
    }
  }

  static Future<String> createServiceOrder(ServiceOrder order) async {
    try {
      final docRef = await _firestore.collection(_serviceOrdersCollection).add({
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Service order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating service order: $e');
      throw Exception('Failed to create service order: $e');
    }
  }

  // Service Order CRUD operations
  static Future<List<ServiceOrder>> getServiceOrders({
    ServiceOrderStatus? status,
  }) async {
    try {
      print('Fetching service orders from Firebase...');
      Query query = _firestore.collection(_serviceOrdersCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.displayName);
      }

      final snapshot = await query.get();

      print('Found ${snapshot.docs.length} service orders in Firebase');
      final orders = snapshot.docs
          .map((doc) => ServiceOrder.fromFirestore(doc))
          .toList();

      // Sort by creation date (newest first) in code
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      print('Error fetching service orders: $e');
      return [];
    }
  }

  static Future<ServiceOrder?> getServiceOrder(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_serviceOrdersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return ServiceOrder.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching service order: $e');
      return null;
    }
  }

  // Generate next sequential order number for today
  static Future<String> generateDailyOrderNumber() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all orders created today
      final querySnapshot = await _firestore
          .collection(_serviceOrdersCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
          .orderBy('createdAt', descending: true)
          .get();

      // Find the highest order number for today
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final orderNumber = data['orderNumber'] as String?;
        if (orderNumber != null && orderNumber.length == 4) {
          final num = int.tryParse(orderNumber);
          if (num != null && num > highestNumber) {
            highestNumber = num;
          }
        }
      }

      // Return next number in sequence, formatted as 4-digit string
      final nextNumber = highestNumber + 1;
      return nextNumber.toString().padLeft(4, '0');
    } catch (e) {
      print('Error generating daily order number: $e');
      // Fallback to time-based number if query fails
      final now = DateTime.now();
      final timeBasedNumber = (now.millisecondsSinceEpoch % 9999) + 1;
      return timeBasedNumber.toString().padLeft(4, '0');
    }
  }

  static Future<String> addServiceOrder(ServiceOrder order) async {
    try {
      print('Adding service order: ${order.orderNumber}');
      final docRef = await _firestore
          .collection(_serviceOrdersCollection)
          .add(order.toMap());
      print('Service order added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding service order: $e');
      throw Exception('Failed to add service order: $e');
    }
  }

  static Future<void> saveServiceOrder(ServiceOrder order) async {
    try {
      print('Saving service order: ${order.orderNumber} with ID: ${order.id}');
      await _firestore
          .collection(_serviceOrdersCollection)
          .doc(order.id)
          .set(order.toMap(), SetOptions(merge: true));
      print('Service order saved successfully: ${order.orderNumber}');
    } catch (e) {
      print('Error saving service order: $e');
      throw Exception('Failed to save service order: $e');
    }
  }

  static Future<void> updateServiceOrderStatus(
    String orderId,
    ServiceOrderStatus status,
  ) async {
    try {
      final updates = {
        'status': status.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ServiceOrderStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_serviceOrdersCollection)
          .doc(orderId)
          .update(updates);

      print('Service order status updated: $orderId -> ${status.displayName}');
    } catch (e) {
      print('Error updating service order status: $e');
      throw Exception('Failed to update service order status: $e');
    }
  }

  // Service Order Item CRUD operations
  static Future<List<ServiceOrderItem>> getServiceOrderItems(
    String serviceOrderId,
  ) async {
    try {
      print('Fetching service order items for order: $serviceOrderId');
      final snapshot = await _firestore
          .collection(_serviceOrderItemsCollection)
          .where('serviceOrderId', isEqualTo: serviceOrderId)
          .get();

      print('Found ${snapshot.docs.length} service order items');
      final items = snapshot.docs
          .map((doc) => ServiceOrderItem.fromFirestore(doc))
          .toList();

      // Sort by creation date
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return items;
    } catch (e) {
      print('Error fetching service order items: $e');
      return [];
    }
  }

  static Future<ServiceOrderItem?> getServiceOrderItem(String itemId) async {
    try {
      final doc = await _firestore
          .collection(_serviceOrderItemsCollection)
          .doc(itemId)
          .get();

      if (doc.exists) {
        return ServiceOrderItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching service order item: $e');
      return null;
    }
  }

  static Future<String> addServiceOrderItem(ServiceOrderItem item) async {
    try {
      print('Adding service order item: ${item.serviceName}');
      final docRef = await _firestore
          .collection(_serviceOrderItemsCollection)
          .add(item.toMap());
      print('Service order item added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding service order item: $e');
      throw Exception('Failed to add service order item: $e');
    }
  }

  static Future<void> saveServiceOrderItem(ServiceOrderItem item) async {
    try {
      print(
        'Saving service order item: ${item.serviceName} with ID: ${item.id}',
      );
      await _firestore
          .collection(_serviceOrderItemsCollection)
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true));
      print('Service order item saved successfully: ${item.serviceName}');
    } catch (e) {
      print('Error saving service order item: $e');
      throw Exception('Failed to save service order item: $e');
    }
  }

  static Future<void> updateServiceOrderItemStatus(
    String itemId,
    ServiceOrderItemStatus status,
  ) async {
    try {
      final updates = {
        'status': status.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == ServiceOrderItemStatus.inProgress) {
        updates['startedAt'] = FieldValue.serverTimestamp();
      } else if (status == ServiceOrderItemStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_serviceOrderItemsCollection)
          .doc(itemId)
          .update(updates);

      print(
        'Service order item status updated: $itemId -> ${status.displayName}',
      );
    } catch (e) {
      print('Error updating service order item status: $e');
      throw Exception('Failed to update service order item status: $e');
    }
  }

  static Future<void> deleteServiceOrderItem(String itemId) async {
    try {
      await _firestore
          .collection(_serviceOrderItemsCollection)
          .doc(itemId)
          .delete();
      print('Service order item deleted: $itemId');
    } catch (e) {
      print('Error deleting service order item: $e');
      throw Exception('Failed to delete service order item: $e');
    }
  }

  // Delete a service order and all its related items
  static Future<void> deleteServiceOrder(String orderId) async {
    try {
      // First, delete all service order items for this order
      final itemsSnapshot = await _firestore
          .collection(_serviceOrderItemsCollection)
          .where('serviceOrderId', isEqualTo: orderId)
          .get();

      // Delete all service order items in a batch
      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the service order itself
      batch.delete(
        _firestore.collection(_serviceOrdersCollection).doc(orderId),
      );

      // Commit the batch operation
      await batch.commit();

      print('Service order and related items deleted: $orderId');
    } catch (e) {
      print('Error deleting service order: $e');
      throw Exception('Failed to delete service order: $e');
    }
  }

  // Loyalty Points Configuration
  static Future<Map<String, dynamic>> getLoyaltyPointsConfig() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('loyalty_points')
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        // Return default configuration
        return {'pointsPerDollar': 1.0, 'minimumSpend': 0.0, 'isEnabled': true};
      }
    } catch (e) {
      print('Error fetching loyalty points config: $e');
      return {'pointsPerDollar': 1.0, 'minimumSpend': 0.0, 'isEnabled': true};
    }
  }

  static Future<void> saveLoyaltyPointsConfig(
    Map<String, dynamic> config,
  ) async {
    try {
      await _firestore
          .collection('settings')
          .doc('loyalty_points')
          .set(config, SetOptions(merge: true));
      print('Loyalty points config saved successfully');
    } catch (e) {
      print('Error saving loyalty points config: $e');
      throw Exception('Failed to save loyalty points config: $e');
    }
  }

  // Get service orders by date range for reporting
  static Future<List<ServiceOrder>> getServiceOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print(
        'Fetching service orders from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // Set start of day for startDate and end of day for endDate
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final snapshot = await _firestore
          .collection(_serviceOrdersCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      print('Found ${snapshot.docs.length} service orders in date range');
      final orders = snapshot.docs
          .map((doc) => ServiceOrder.fromFirestore(doc))
          .toList();

      // Sort by creation date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      print('Error fetching service orders by date range: $e');
      return [];
    }
  }

  // Update service order (alias for saveServiceOrder)
  static Future<void> updateServiceOrder(ServiceOrder order) async {
    return saveServiceOrder(order);
  }

  // Helper method to calculate loyalty points
  static int calculateLoyaltyPoints(
    double totalAmount,
    double pointsPerDollar,
  ) {
    return (totalAmount * pointsPerDollar).round();
  }

  // ===== APPOINTMENT METHODS =====

  // Get appointments for a specific date
  static Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    try {
      print('Fetching appointments for date: ${date.toIso8601String()}');

      // Start of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      // End of day
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print(
        'Query range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}',
      );

      // First, try to get all appointments and filter them client-side for debugging
      final allSnapshot = await _firestore
          .collection(_appointmentsCollection)
          .get();

      print('Total appointments in database: ${allSnapshot.docs.length}');

      for (var doc in allSnapshot.docs) {
        final data = doc.data();
        print(
          'Appointment ${doc.id}: appointmentDate = ${data['appointmentDate']}',
        );
      }

      final snapshot = await _firestore
          .collection(_appointmentsCollection)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: endOfDay.toIso8601String(),
          )
          .get();

      print('Found ${snapshot.docs.length} appointments for date range query');
      final appointments = snapshot.docs
          .map((doc) => Appointment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by time slot
      appointments.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

      return appointments;
    } catch (e) {
      print('Error fetching appointments by date: $e');
      return [];
    }
  }

  // Get appointments for a technician on a specific date
  static Future<List<Appointment>> getTechnicianAppointments(
    String technicianId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('technicianId', isEqualTo: technicianId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: endOfDay.toIso8601String(),
          )
          .get();

      final appointments = snapshot.docs
          .map((doc) => Appointment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      appointments.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
      return appointments;
    } catch (e) {
      print('Error fetching technician appointments: $e');
      return [];
    }
  }

  // Create a new appointment
  static Future<String> createAppointment(Appointment appointment) async {
    try {
      print('Creating appointment for ${appointment.customerName}');

      final docRef = await _firestore
          .collection(_appointmentsCollection)
          .add(appointment.toJson());

      print('Appointment created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Update appointment
  static Future<void> updateAppointment(Appointment appointment) async {
    try {
      print('Updating appointment: ${appointment.id}');

      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointment.id)
          .update(appointment.toJson());

      print('Appointment updated successfully');
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  // Cancel appointment
  static Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update({
            'status': AppointmentStatus.cancelled.toString().split('.').last,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Get available time slots for a technician on a specific date
  static Future<List<String>> getAvailableTimeSlots(
    String technicianId,
    DateTime date,
  ) async {
    try {
      Set<String> bookedSlots = {};

      if (technicianId == 'any' || technicianId.isEmpty) {
        // For "any technician", check all appointments for the date
        final allAppointments = await getAppointmentsByDate(date);
        bookedSlots = allAppointments
            .where((apt) => apt.status != AppointmentStatus.cancelled)
            .map((apt) => apt.timeSlot)
            .toSet();
      } else {
        // For specific technician, check only their appointments
        final existingAppointments = await getTechnicianAppointments(
          technicianId,
          date,
        );
        bookedSlots = existingAppointments
            .where((apt) => apt.status != AppointmentStatus.cancelled)
            .map((apt) => apt.timeSlot)
            .toSet();
      }

      // Generate all possible time slots (9 AM to 6 PM, 30-minute intervals)
      final allSlots = <String>[];
      for (int hour = 9; hour < 18; hour++) {
        allSlots.add(
          '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
        );
        allSlots.add(
          '${hour > 12 ? hour - 12 : hour}:30 ${hour >= 12 ? 'PM' : 'AM'}',
        );
      }

      // For "any technician", only show slots that have at least one available technician
      if (technicianId == 'any' || technicianId.isEmpty) {
        final employees = await getEmployees();
        final availableTechnicians = employees
            .where((e) => e.isActive)
            .toList();
        final availableSlots = <String>[];

        for (final slot in allSlots) {
          // Check if at least one technician is available for this slot
          bool hasAvailableTechnician = false;
          for (final tech in availableTechnicians) {
            final techAppointments = await getTechnicianAppointments(
              tech.id,
              date,
            );
            final techBookedSlots = techAppointments
                .where((apt) => apt.status != AppointmentStatus.cancelled)
                .map((apt) => apt.timeSlot)
                .toSet();
            if (!techBookedSlots.contains(slot)) {
              hasAvailableTechnician = true;
              break;
            }
          }
          if (hasAvailableTechnician) {
            availableSlots.add(slot);
          }
        }
        return availableSlots;
      } else {
        // Filter out booked slots for specific technician
        final availableSlots = allSlots
            .where((slot) => !bookedSlots.contains(slot))
            .toList();
        return availableSlots;
      }
    } catch (e) {
      print('Error getting available time slots: $e');
      return [];
    }
  }

  // Generate confirmation code
  static String generateConfirmationCode() {
    final now = DateTime.now();
    return 'CE${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(3, '0')}';
  }

  // Get appointment by confirmation code
  static Future<Appointment?> getAppointmentByConfirmationCode(
    String confirmationCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('confirmationCode', isEqualTo: confirmationCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Appointment.fromJson({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting appointment by confirmation code: $e');
      return null;
    }
  }
}
