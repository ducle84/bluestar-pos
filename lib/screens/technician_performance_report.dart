import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_order.dart';
import '../models/service_order_item.dart';
import '../models/employee.dart';
import '../provider/catalog_provider.dart';
import '../services/firebase_service.dart';

class TechnicianPerformanceReport extends StatefulWidget {
  const TechnicianPerformanceReport({super.key});

  @override
  State<TechnicianPerformanceReport> createState() =>
      _TechnicianPerformanceReportState();
}

class _TechnicianPerformanceReportState
    extends State<TechnicianPerformanceReport> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<ServiceOrder> _serviceOrders = [];
  List<Employee> _employees = [];
  Map<String, List<ServiceOrderItem>> _orderItemsMap = {};
  String? _selectedTechnicianId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final catalogProvider = Provider.of<CatalogProvider>(
        context,
        listen: false,
      );

      // Load employees
      await catalogProvider.loadAllData();
      _employees = catalogProvider.employees;

      // Load service orders for the date range
      final startOfDay = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
      final endOfDay = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      );

      _serviceOrders = await FirebaseService.getServiceOrdersByDateRange(
        startOfDay,
        endOfDay,
      );

      // Load service order items for each order
      _orderItemsMap.clear();
      for (final order in _serviceOrders) {
        if (order.id != null) {
          try {
            final items = await FirebaseService.getServiceOrderItems(order.id!);
            _orderItemsMap[order.id!] = items;
          } catch (e) {
            debugPrint('Error loading items for order ${order.id}: $e');
            _orderItemsMap[order.id!] = [];
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _getEmployeeName(String employeeId) {
    final employee = _employees.firstWhere(
      (emp) => emp.id == employeeId,
      orElse: () => Employee(
        id: employeeId,
        name: 'Unknown Employee',
        email: '',
        phone: '',
        position: '',
        commissionRate: 0,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
    return employee.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with date range selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Technician Performance Report',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    Text(
                      '${_startDate.month}/${_startDate.day}/${_startDate.year} - ${_endDate.month}/${_endDate.day}/${_endDate.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Change Range'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Content area
        Expanded(
          child: _selectedTechnicianId == null
              ? _buildTechnicianOverview()
              : _buildTechnicianDetail(_selectedTechnicianId!),
        ),
      ],
    );
  }

  Widget _buildTechnicianOverview() {
    // Group orders by technician
    final technicianStats = <String, Map<String, dynamic>>{};

    for (final order in _serviceOrders) {
      // Check if order has technicians
      if (order.technicianIds.isEmpty) continue;

      // For now, use the first technician (could be enhanced to handle multiple)
      final techId = order.technicianIds.first;
      if (!technicianStats.containsKey(techId)) {
        technicianStats[techId] = {
          'orders': 0,
          'totalRevenue': 0.0,
          'totalServices': 0,
          'cancelledOrders': 0,
        };
      }

      technicianStats[techId]!['orders']++;

      if (order.status == ServiceOrderStatus.cancelled) {
        technicianStats[techId]!['cancelledOrders']++;
      } else {
        technicianStats[techId]!['totalRevenue'] += order.total;

        // Count actual services by summing quantities from service order items
        final items = _orderItemsMap[order.id] ?? [];
        int serviceCount = 0;
        for (final item in items) {
          // Only count services performed by this technician
          if (item.technicianId == techId) {
            serviceCount += item.quantity;
          }
        }
        technicianStats[techId]!['totalServices'] += serviceCount;
      }
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(
                  'All Technicians Performance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Technician')),
                  DataColumn(label: Text('Orders'), numeric: true),
                  DataColumn(label: Text('Services'), numeric: true),
                  DataColumn(label: Text('Revenue'), numeric: true),
                  DataColumn(label: Text('Avg/Order'), numeric: true),
                  DataColumn(label: Text('Cancelled'), numeric: true),
                ],
                rows: technicianStats.entries.map((entry) {
                  final techId = entry.key;
                  final stats = entry.value;
                  final orders = stats['orders'] as int;
                  final revenue = stats['totalRevenue'] as double;
                  final avgPerOrder = orders > 0 ? revenue / orders : 0.0;

                  return DataRow(
                    onSelectChanged: (_) {
                      setState(() {
                        _selectedTechnicianId = techId;
                      });
                    },
                    cells: [
                      DataCell(Text(_getEmployeeName(techId))),
                      DataCell(Text(orders.toString())),
                      DataCell(Text(stats['totalServices'].toString())),
                      DataCell(Text('\$${revenue.toStringAsFixed(2)}')),
                      DataCell(Text('\$${avgPerOrder.toStringAsFixed(2)}')),
                      DataCell(Text(stats['cancelledOrders'].toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianDetail(String technicianId) {
    final techOrders = _serviceOrders
        .where((order) => order.technicianIds.contains(technicianId))
        .toList();

    // Calculate stats
    final totalOrders = techOrders.length;
    final activeOrders = techOrders
        .where((o) => o.status != ServiceOrderStatus.cancelled)
        .length;
    final cancelledOrders = techOrders
        .where((o) => o.status == ServiceOrderStatus.cancelled)
        .length;
    final totalRevenue = techOrders
        .where((o) => o.status != ServiceOrderStatus.cancelled)
        .fold(0.0, (sum, order) => sum + order.total);
    final totalServices = techOrders
        .where((o) => o.status != ServiceOrderStatus.cancelled)
        .fold(0, (sum, order) {
          final items = _orderItemsMap[order.id] ?? [];
          int serviceCount = 0;
          for (final item in items) {
            if (item.technicianId == technicianId) {
              serviceCount += item.quantity;
            }
          }
          return sum + serviceCount;
        });
    final avgPerOrder = activeOrders > 0 ? totalRevenue / activeOrders : 0.0;

    return Column(
      children: [
        // Back button and technician name
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedTechnicianId = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  _getEmployeeName(technicianId),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Summary cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        totalOrders.toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Total Orders'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        totalServices.toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Services'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Revenue'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '\$${avgPerOrder.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Avg/Order'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        cancelledOrders.toString(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: cancelledOrders > 0 ? Colors.red : null,
                            ),
                      ),
                      const Text('Cancelled'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Orders table
        Expanded(
          child: Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt),
                      const SizedBox(width: 8),
                      Text(
                        'Service Orders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Order #')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Services'), numeric: true),
                        DataColumn(label: Text('Amount'), numeric: true),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: techOrders.map((order) {
                        return DataRow(
                          cells: [
                            DataCell(Text(order.orderNumber)),
                            DataCell(
                              Text(
                                '${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year}',
                              ),
                            ),
                            DataCell(Text(order.customerName ?? 'Walk-in')),
                            DataCell(
                              Text(() {
                                final items = _orderItemsMap[order.id] ?? [];
                                int serviceCount = 0;
                                for (final item in items) {
                                  if (item.technicianId == technicianId) {
                                    serviceCount += item.quantity;
                                  }
                                }
                                return serviceCount.toString();
                              }()),
                            ),
                            DataCell(
                              Text('\$${order.total.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      order.status ==
                                          ServiceOrderStatus.cancelled
                                      ? Colors.red.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.status.displayName.toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        order.status ==
                                            ServiceOrderStatus.cancelled
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
