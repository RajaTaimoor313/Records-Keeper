import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:haider_traders/tabs/suppliers/supplier.dart';

class ViewSuppliersTab extends StatefulWidget {
  const ViewSuppliersTab({super.key});

  @override
  State<ViewSuppliersTab> createState() => _ViewSuppliersTabState();
}

class _ViewSuppliersTabState extends State<ViewSuppliersTab> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSuppliers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(_searchQuery) ||
            supplier.fatherName.toLowerCase().contains(_searchQuery) ||
            supplier.address.toLowerCase().contains(_searchQuery) ||
            supplier.cnic.toLowerCase().contains(_searchQuery) ||
            supplier.phone.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final suppliersData = await DatabaseHelper.instance.getSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliersData
            .map((data) => Supplier.fromMap(data))
            .toList();
        _filteredSuppliers = List.from(_suppliers);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSupplier(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Man Power'),
        content: const Text('Are you sure you want to delete this man power?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteSupplier(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Man Power deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _loadSuppliers();
  }

  void _showEditSupplierDialog(Supplier supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final fatherNameController = TextEditingController(
      text: supplier.fatherName,
    );
    final addressController = TextEditingController(text: supplier.address);
    final cnicController = TextEditingController(text: supplier.cnic);
    final phoneController = TextEditingController(text: supplier.phone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Man Power'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: fatherNameController,
                  decoration: const InputDecoration(labelText: 'Father Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: cnicController,
                  decoration: const InputDecoration(labelText: 'CNIC'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone No.'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedSupplier = Supplier(
                  id: supplier.id,
                  name: nameController.text.trim(),
                  fatherName: fatherNameController.text.trim(),
                  address: addressController.text.trim(),
                  cnic: cnicController.text.trim(),
                  phone: phoneController.text.trim(),
                  type: supplier.type,
                );
                await DatabaseHelper.instance.updateSupplier(
                  updatedSupplier.toMap(),
                );
                Navigator.of(context).pop();
                _loadSuppliers();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : _suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.deepPurple.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No man powers added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first man power using the Add tab',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Man Powers',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_suppliers.length} man powers found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterSuppliers,
                          decoration: InputDecoration(
                            hintText: 'Search man powers...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.deepPurple.withOpacity(0.1),
                              ),
                              columnSpacing: 32,
                              horizontalMargin: 24,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'No.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Father Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'CNIC',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Phone No.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _filteredSuppliers.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final supplier = entry.value;
                                return DataRow(
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text(supplier.name)),
                                    DataCell(Text(supplier.fatherName)),
                                    DataCell(Text(supplier.address)),
                                    DataCell(Text(supplier.cnic)),
                                    DataCell(Text(supplier.phone)),
                                    DataCell(Text(supplier.type)),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.deepPurple,
                                            ),
                                            onPressed: () =>
                                                _showEditSupplierDialog(
                                                  supplier,
                                                ),
                                            tooltip: 'Edit Man Power',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deleteSupplier(supplier.id!),
                                            tooltip: 'Delete Man Power',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
