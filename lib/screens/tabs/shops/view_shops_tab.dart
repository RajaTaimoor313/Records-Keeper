import 'package:flutter/material.dart';
import '../../../database_helper.dart';
import '../../../models/shop.dart';

class ViewShopsTab extends StatefulWidget {
  const ViewShopsTab({super.key});

  @override
  State<ViewShopsTab> createState() => _ViewShopsTabState();
}

class _ViewShopsTabState extends State<ViewShopsTab> {
  List<Shop> _shops = [];
  List<Shop> _filteredShops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterShops(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredShops = _shops.where((shop) {
        return shop.name.toLowerCase().contains(_searchQuery) ||
            shop.ownerName.toLowerCase().contains(_searchQuery) ||
            shop.category.toLowerCase().contains(_searchQuery) ||
            shop.code.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shopsData = await DatabaseHelper.instance.getShops();
      setState(() {
        _shops = shopsData.map((data) => Shop.fromMap(data)).toList();
        _filteredShops = List.from(_shops);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteShop(String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text('Are you sure you want to delete this shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await DatabaseHelper.instance.deleteShop(code);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadShops();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete shop'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          : _shops.isEmpty
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
                          Icons.store_mall_directory_outlined,
                          size: 64,
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No shops added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first shop using the Add tab',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.store_mall_directory_rounded,
                              color: Colors.deepPurple,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All Shops',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_shops.length} shops found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Search Field
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterShops,
                              decoration: InputDecoration(
                                hintText: 'Search shops...',
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

                      // Table
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
                                        'Code',
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
                                        'Owner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Category',
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
                                  rows: _filteredShops.map((shop) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              shop.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(shop.name)),
                                        DataCell(Text(shop.ownerName)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              shop.category,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteShop(shop.code),
                                            tooltip: 'Delete Shop',
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