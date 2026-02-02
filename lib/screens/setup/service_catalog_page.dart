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
    return SizedBox(
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
}
