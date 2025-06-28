import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProfitLossTab extends StatefulWidget {
  const ProfitLossTab({super.key});

  @override
  State<ProfitLossTab> createState() => _ProfitLossTabState();
}

class _ProfitLossTabState extends State<ProfitLossTab> {
  double? grossProfit;
  double? netProfit;
  double? totalExpenditure;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _calculateProfits();
  }

  Future<void> _calculateProfits() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get current date in the format used in the database
      final currentDate = DateTime.now();
      final dateString = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      
      // Get all products with their rates
      final products = await db.query('products');
      final Map<String, Map<String, dynamic>> productRates = {};
      for (var p in products) {
        final brand = p['brand'] as String? ?? '';
        final boxRate = p['boxRate'] ?? 0.0;
        final salePrice = p['salePrice'] ?? 0.0;
        productRates[brand] = {
          'boxRate': boxRate,
          'salePrice': salePrice,
        };
      }
      
      
      // Track totals by source for detailed breakdown
      double stockBoxTotal = 0.0;
      double stockTradeTotal = 0.0;
      
      // 1. Calculate from Invoices (current date only)
      final invoices = await db.query(
        'invoices',
        where: 'date = ?',
        whereArgs: [dateString],
      );
      
      for (final invoice in invoices) {
        final itemsJson = invoice['items'] as String?;
        if (itemsJson == null || itemsJson.isEmpty) {
          continue;
        }
        
        try {
          final List<dynamic> items = jsonDecode(itemsJson);
          
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final brand = item['description'] ?? item['brand'] ?? item['brandName'] ?? '';
              
              // Try exact match first
              var rates = productRates[brand];
              
              // If not found, try case-insensitive match
              if (rates == null) {
                for (final availableBrand in productRates.keys) {
                  if (availableBrand.toLowerCase().trim() == brand.toLowerCase().trim()) {
                    rates = productRates[availableBrand];
                    break;
                  }
                }
              }
              
              // If still not found, try partial match
              if (rates == null) {
                for (final availableBrand in productRates.keys) {
                  if (availableBrand.toLowerCase().contains(brand.toLowerCase()) || 
                      brand.toLowerCase().contains(availableBrand.toLowerCase())) {
                    rates = productRates[availableBrand];
                    break;
                  }
                }
              }
              
              if (rates != null) {
                
                
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      // 2. Calculate from Load Forms (no date column in this table)
      final loadForms = await db.query('load_form');
      
      for (final loadForm in loadForms) {
        final brandName = loadForm['brandName'] as String? ?? '';
        final saleQty = (loadForm['sale'] ?? 0) as num;
        final rates = productRates[brandName];
        
        if (rates != null && saleQty > 0) {
          
          
        }
      }
      
      // 3. Calculate from Stock Records (current date only)
      final stockRecords = await db.query(
        'stock_records',
        where: 'date = ?',
        whereArgs: [dateString],
      );
      
      for (final record in stockRecords) {
        final productId = record['product_id'] as String? ?? '';
        final saleValue = (record['sale_value'] ?? 0) as num;
        
        if (saleValue > 0) {
          // Get product details to find brand
          final productResult = await db.query(
            'products',
            where: 'id = ?',
            whereArgs: [productId],
          );
          
          if (productResult.isNotEmpty) {
            final brand = productResult.first['brand'] as String? ?? '';
            final rates = productRates[brand];
            
            if (rates != null) {
              final boxRate = rates['boxRate'] as num;
              final tradeRate = rates['salePrice'] as num;
              
              // Calculate the box rate portion of the sale value
              // If trade rate is 100 and box rate is 80, then 80% of sale value is box cost
              final boxRatio = boxRate / tradeRate;
              final boxValue = saleValue * boxRatio;
              
              
              stockBoxTotal += boxValue;
              stockTradeTotal += saleValue;
            }
          }
        }
      }
      
      // 4. Calculate from Pick Lists (no date column in this table)
      final pickLists = await db.query('pick_list');
      
      for (final pickList in pickLists) {
        final billAmount = (pickList['billAmount'] ?? 0) as num;
        final recovery = (pickList['recovery'] ?? 0) as num;
        
        // If there's a bill amount and recovery, it indicates a sale
        if (billAmount > 0 && recovery > 0) {
          // For pick lists, we'll use the bill amount as trade rate
          // and estimate box rate based on average margin
// Assuming 20% margin
          
        }
      }
      
      final gross = stockTradeTotal - stockBoxTotal;
      
      // Get total expenditure for current date only
      final expResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenditure WHERE date = ?',
        [dateString],
      );
      final exp = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      setState(() {
        grossProfit = gross;
        totalExpenditure = exp;
        netProfit = gross - exp;
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ');
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(
                'Calculating Profits...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _calculateProfits,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profit & Loss Statement',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Financial Performance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Gross Profit Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: (grossProfit ?? 0) >= 0
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.red.shade50, Colors.red.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (grossProfit ?? 0) >= 0
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            (grossProfit ?? 0) >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: (grossProfit ?? 0) >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gross Profit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Revenue minus Cost of Goods Sold',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currency.format(grossProfit ?? 0),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: (grossProfit ?? 0) >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Net Profit Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: (netProfit ?? 0) >= 0
                        ? [Colors.blue.shade50, Colors.blue.shade100]
                        : [Colors.orange.shade50, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (netProfit ?? 0) >= 0
                                ? Colors.blue.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            (netProfit ?? 0) >= 0
                                ? Icons.account_balance_wallet_rounded
                                : Icons.warning_rounded,
                            color: (netProfit ?? 0) >= 0
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Profit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gross Profit minus Total Expenditure',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currency.format(netProfit ?? 0),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: (netProfit ?? 0) >= 0
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.deepPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Total Expenditure',
                            currency.format(totalExpenditure ?? 0),
                            Icons.money_off_rounded,
                            Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryItem(
                            'Profit Margin',
                            '${((grossProfit ?? 0) > 0 && (totalExpenditure ?? 0) > 0) ? (((grossProfit ?? 0) / (totalExpenditure ?? 1)) * 100).toStringAsFixed(1) : '0.0'}%',
                            Icons.percent_rounded,
                            Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateProfits,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Calculations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 