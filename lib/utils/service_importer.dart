import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/service_catalog.dart';
import '../services/firebase_service.dart';

class ServiceImporter {
  static const String csvFilePath = 'assets/services_data.csv';

  /// Import services from CSV file
  static Future<void> importServicesFromCSV() async {
    try {
      // Load CSV data
      final String csvData = await rootBundle.loadString(csvFilePath);
      final List<String> lines = csvData.split('\n');

      // Skip header row
      final List<String> dataLines = lines.skip(1).toList();

      // Parse services and categories
      final Map<String, String> categories = {};
      final List<ServiceCatalog> services = [];

      for (String line in dataLines) {
        if (line.trim().isEmpty) continue;

        final List<String> fields = _parseCSVLine(line);
        if (fields.length >= 5) {
          final String categoryName = fields[0].trim();
          final String serviceName = fields[1].trim();
          final double price = double.tryParse(fields[2].trim()) ?? 0.0;
          final String description = fields[3].trim();
          final int duration = int.tryParse(fields[4].trim()) ?? 30;

          // Store unique categories
          if (!categories.containsKey(categoryName)) {
            categories[categoryName] = _generateCategoryId(categoryName);
          }

          // Create service
          final service = ServiceCatalog(
            id: _generateServiceId(serviceName),
            name: serviceName,
            price: price,
            categoryId: categories[categoryName]!,
            description: description,
            durationMinutes: duration,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          services.add(service);
        }
      }

      // Import categories first
      for (String categoryName in categories.keys) {
        final category = Category(
          id: categories[categoryName]!,
          name: categoryName,
          description: '$categoryName services',
          icon: _getCategoryIcon(categoryName),
          color: _getCategoryColor(categoryName),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirebaseService.saveCategory(category);
      }

      // Import services
      for (ServiceCatalog service in services) {
        await FirebaseService.saveService(service);
      }

      print(
        'Successfully imported ${categories.length} categories and ${services.length} services',
      );
    } catch (e) {
      print('Error importing services: $e');
      rethrow;
    }
  }

  /// Parse CSV line handling quoted fields
  static List<String> _parseCSVLine(String line) {
    final List<String> result = [];
    final StringBuffer buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString());
    return result;
  }

  /// Generate category ID from name
  static String _generateCategoryId(String categoryName) {
    return categoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Generate service ID from name
  static String _generateServiceId(String serviceName) {
    return serviceName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Clear all existing services and categories (use with caution)
  static Future<void> clearAllServicesAndCategories() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, just print a warning
      print(
        'Warning: Clear function not implemented. Manually delete from Firebase Console if needed.',
      );
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  /// Export current services to CSV format
  static Future<String> exportServicesToCSV() async {
    try {
      final categories = await FirebaseService.getCategories();
      final services = await FirebaseService.getServices();

      final StringBuffer csv = StringBuffer();
      csv.writeln('Category,Service Name,Price,Description,Duration');

      for (ServiceCatalog service in services) {
        final category = categories.firstWhere(
          (c) => c.id == service.categoryId,
          orElse: () => Category(
            id: '',
            name: 'Uncategorized',
            description: 'Uncategorized services',
            icon: Icons.miscellaneous_services,
            color: Colors.grey,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csv.writeln(
          '${category.name},${service.name},${service.price},"${service.description}",${service.durationMinutes}',
        );
      }

      return csv.toString();
    } catch (e) {
      print('Error exporting services: $e');
      rethrow;
    }
  }

  /// Get category-specific icon
  static IconData _getCategoryIcon(String categoryName) {
    final String normalizedName = categoryName.toLowerCase();

    if (normalizedName.contains('manicure')) {
      return Icons.back_hand;
    } else if (normalizedName.contains('pedicure')) {
      return Icons.water_drop;
    } else if (normalizedName.contains('enhancement') ||
        normalizedName.contains('nail')) {
      return Icons.star;
    } else if (normalizedName.contains('kids')) {
      return Icons.child_friendly;
    } else if (normalizedName.contains('nexgen') ||
        normalizedName.contains('dipping')) {
      return Icons.auto_awesome;
    } else if (normalizedName.contains('add-on') ||
        normalizedName.contains('art')) {
      return Icons.palette;
    } else if (normalizedName.contains('wax')) {
      return Icons.spa;
    } else {
      return Icons.miscellaneous_services;
    }
  }

  /// Get category color
  static Color _getCategoryColor(String categoryName) {
    final String normalizedName = categoryName.toLowerCase();

    if (normalizedName.contains('manicure')) {
      return Colors.pink;
    } else if (normalizedName.contains('pedicure')) {
      return Colors.blue;
    } else if (normalizedName.contains('enhancement') ||
        normalizedName.contains('nail')) {
      return Colors.purple;
    } else if (normalizedName.contains('kids')) {
      return Colors.orange;
    } else if (normalizedName.contains('nexgen') ||
        normalizedName.contains('dipping')) {
      return Colors.green;
    } else if (normalizedName.contains('add-on') ||
        normalizedName.contains('art')) {
      return Colors.red;
    } else if (normalizedName.contains('wax')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}
