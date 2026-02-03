import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_catalog.dart';
import '../../models/category.dart';
import '../../provider/catalog_provider.dart';
import '../../utils/service_importer.dart';

class ServiceCatalogPage extends StatefulWidget {
  const ServiceCatalogPage({super.key});

  @override
  State<ServiceCatalogPage> createState() => _ServiceCatalogPageState();
}

class _ServiceCatalogPageState extends State<ServiceCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Catalog'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'import':
                  await _importServices();
                  break;
                case 'export':
                  await _exportServices();
                  break;
                case 'add':
                  await _showServiceDialog(context);
                  break;
                case 'manage_categories':
                  await _showCategoryManagementDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import Services'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Services'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add Service'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage_categories',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Manage Categories'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CatalogProvider>(
        builder: (context, catalogProvider, child) {
          if (catalogProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter services based on category and search
          final filteredServices = catalogProvider.services.where((service) {
            final matchesCategory =
                _selectedCategoryId == null ||
                service.categoryId == _selectedCategoryId;
            final matchesSearch =
                _searchQuery.isEmpty ||
                service.name.toLowerCase().contains(_searchQuery) ||
                service.description.toLowerCase().contains(_searchQuery);
            return matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Filter
                    _buildCategoryFilter(catalogProvider),
                  ],
                ),
              ),
              // Services Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Showing ${filteredServices.length} of ${catalogProvider.services.length} services',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (_isImporting)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Importing...'),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              catalogProvider.services.isEmpty
                                  ? 'No services available'
                                  : 'No services match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (catalogProvider.services.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _importServices();
                                },
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Import Sample Services'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          final category = catalogProvider.categories
                              .firstWhere(
                                (c) => c.id == service.categoryId,
                                orElse: () => Category(
                                  id: '',
                                  name: 'Unknown',
                                  description: '',
                                  icon: Icons.help,
                                  color: Colors.grey,
                                  createdAt: DateTime.now(),
                                ),
                              );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color.withOpacity(
                                  0.2,
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                ),
                              ),
                              title: Text(service.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.description),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          category.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: category.color
                                            .withOpacity(0.1),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        service.formattedDuration,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    service.formattedPrice,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[600],
                                        ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'edit':
                                          await _showServiceDialog(
                                            context,
                                            service: service,
                                          );
                                          break;
                                        case 'delete':
                                          await _deleteService(
                                            catalogProvider,
                                            service,
                                          );
                                          break;
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(CatalogProvider catalogProvider) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // All Categories Filter
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: _selectedCategoryId == null,
                    label: const Text('All'),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    },
                  ),
                ),
                // Individual Category Filters
                ...catalogProvider.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _selectedCategoryId == category.id,
                      label: Text(category.name),
                      backgroundColor: category.color.withOpacity(0.1),
                      selectedColor: category.color.withOpacity(0.3),
                      checkmarkColor: category.color,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category.id : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Manage Categories Button
        IconButton(
          onPressed: () => _showCategoryManagementDialog(context),
          icon: const Icon(Icons.settings),
          tooltip: 'Manage Categories',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Future<void> _importServices() async {
    try {
      setState(() {
        _isImporting = true;
      });

      await ServiceImporter.importServicesFromCSV();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the data
        context.read<CatalogProvider>().loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _exportServices() async {
    try {
      final csvData = await ServiceImporter.exportServicesToCSV();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showServiceDialog(
    BuildContext context, {
    ServiceCatalog? service,
  }) async {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    final priceController = TextEditingController(
      text: service?.price.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: service?.durationMinutes.toString() ?? '60',
    );
    String? selectedCategoryId = service?.categoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer<CatalogProvider>(
        builder: (context, catalogProvider, child) => AlertDialog(
          title: Text(isEdit ? 'Edit Service' : 'Add Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: catalogProvider.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(category.icon, color: category.color),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    selectedCategoryId = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text) ?? 0.0;
                final duration = int.tryParse(durationController.text) ?? 60;

                final newService = ServiceCatalog(
                  id: service?.id ?? '',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: price,
                  durationMinutes: duration,
                  categoryId: selectedCategoryId!,
                  createdAt: service?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (isEdit) {
                    await catalogProvider.updateService(newService);
                  } else {
                    await catalogProvider.addService(newService);
                  }

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving service: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Service updated successfully'
                  : 'Service added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteService(
    CatalogProvider catalogProvider,
    ServiceCatalog service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await catalogProvider.deleteService(service.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${service.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
        }
      }
    }
  }

  Future<void> _showCategoryManagementDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Consumer<CatalogProvider>(
        builder: (context, catalogProvider, child) => AlertDialog(
          title: const Text('Manage Categories'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${catalogProvider.categories.length} categories',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCategoryDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: catalogProvider.categories.isEmpty
                      ? const Center(child: Text('No categories available'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: catalogProvider.categories.length,
                          itemBuilder: (context, index) {
                            final category = catalogProvider.categories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: category.color.withOpacity(
                                    0.2,
                                  ),
                                  child: Icon(
                                    category.icon,
                                    color: category.color,
                                  ),
                                ),
                                title: Text(category.name),
                                subtitle: Text(category.description),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showCategoryDialog(
                                        context,
                                        category: category,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteCategory(
                                        catalogProvider,
                                        category,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    Category? category,
  }) async {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    IconData selectedIcon = category?.icon ?? Icons.miscellaneous_services;
    Color selectedColor = category?.color ?? Colors.blue;

    final predefinedIcons = [
      Icons.miscellaneous_services,
      Icons.home_repair_service,
      Icons.build,
      Icons.cleaning_services,
      Icons.electrical_services,
      Icons.plumbing,
      Icons.handyman,
      Icons.design_services,
      Icons.computer,
      Icons.phone,
      Icons.car_repair,
      Icons.medical_services,
      Icons.fitness_center,
      Icons.restaurant,
      Icons.shopping_bag,
    ];

    final predefinedColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text('Icon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withOpacity(0.2)
                                : null,
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? selectedColor
                                : Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedColors.map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newCategory = Category(
                  id:
                      category?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                  createdAt: category?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  final catalogProvider = context.read<CatalogProvider>();
                  if (isEdit) {
                    await catalogProvider.updateCategory(newCategory);
                  } else {
                    await catalogProvider.addCategory(newCategory);
                  }

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving category: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Category updated successfully'
                  : 'Category added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(
    CatalogProvider catalogProvider,
    Category category,
  ) async {
    // Check if category is in use
    final servicesUsingCategory = catalogProvider.services
        .where((service) => service.categoryId == category.id)
        .length;

    if (servicesUsingCategory > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Category'),
          content: Text(
            'This category is being used by $servicesUsingCategory service(s). '
            'Please reassign or delete those services before deleting this category.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await catalogProvider.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${category.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }
}
