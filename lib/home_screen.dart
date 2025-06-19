import 'package:flutter/material.dart';
import 'package:records_keeper/screens/cash_flow_screen.dart';
import 'package:records_keeper/screens/tabs/stock_tab.dart';
import 'package:records_keeper/screens/tabs/stock_report_tab.dart';
import 'package:records_keeper/screens/tabs/stock_summary_tab.dart';
import 'package:records_keeper/screens/tabs/shops/add_shop_tab.dart';
import 'package:records_keeper/screens/tabs/shops/view_shops_tab.dart';
import 'package:records_keeper/screens/tabs/sales/invoice_tab.dart';
import 'package:records_keeper/screens/tabs/view_products_tab.dart';
import 'package:records_keeper/screens/tabs/sales/view_invoices_tab.dart';
import 'package:records_keeper/screens/tabs/sales/load_form.dart';
import 'package:records_keeper/screens/tabs/sales/pick_list_tab.dart';
import 'package:records_keeper/screens/dashboard_screen.dart';
import 'screens/tabs/suppliers/add_supplier_tab.dart';
import 'screens/tabs/suppliers/view_suppliers_tab.dart';
import 'screens/tabs/sales/realisation_tab.dart';
import 'screens/tabs/ledger_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 12;
  bool _panelVisible = true;
  bool _cashFlowExpanded = false;
  bool _stockExpanded = false;
  bool _newTabExpanded = false;
  bool _salesExpanded = false;
  bool _supplierExpanded = false;
  bool _creditExpanded = false;
  String? _cashFlowSubTab;
  String? _stockSubTab;
  String? _newTabSubTab;
  String? _salesSubTab;
  String? _selectedSupplierTab;
  String? _creditSubTab;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.value = _panelVisible ? 0.0 : 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _panelVisible = !_panelVisible;
      _panelVisible ? _animationController.reverse() : _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
          final panelWidth = isDesktop ? 250.0 : (isTablet ? 200.0 : 250.0);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildAppBar(isDesktop),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        ClipRect(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _panelVisible ? panelWidth : 0,
                            child: OverflowBox(
                              minWidth: panelWidth,
                              maxWidth: panelWidth,
                              alignment: Alignment.topLeft,
                              child: _panelVisible ? _buildPanelShow(panelWidth) : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: _panelVisible ? 8.0 : 0,
                            ),
                            child: _buildSelectedScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePanel,
            icon: AnimatedIcon(
              icon: AnimatedIcons.close_menu,
              progress: _animationController,
              color: Colors.white,
            ),
            tooltip: _panelVisible ? 'Close side panel' : 'Open side panel',
          ),
          const Expanded(
            child: Text(
              'Accounts Holder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPanelShow(double width) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDashItem(),
                  _buildCashFlowItem(),
                  _buildStockItem(),
                  _buildNewTabItem(),
                  _buildSupplierItem(),
                  _buildSalesItem(),
                  _buildCreditItem(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowItem() {
    return Column(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          minLeadingWidth: 20,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 20,
              color: (_selectedIndex == 1 && _cashFlowSubTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Cash Flow',
                style: TextStyle(
                  color: (_selectedIndex == 1 && _cashFlowSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 1 && _cashFlowSubTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _cashFlowExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 1 && _cashFlowSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _cashFlowExpanded = !_cashFlowExpanded;
            });
          },
        ),
        if (_cashFlowExpanded)
          Column(
            children: [
              _buildSubMenuItem(
                'Income',
                _cashFlowSubTab == 'Income',
                () {
                  setState(() {
                    _selectedIndex = 1;
                    _cashFlowSubTab = 'Income';
                  });
                },
              ),
              _buildSubMenuItem(
                'Expenditure',
                _cashFlowSubTab == 'Expenditure',
                () {
                  setState(() {
                    _selectedIndex = 1;
                    _cashFlowSubTab = 'Expenditure';
                  });
                },
              ),
              _buildSubMenuItem(
                'B/F',
                _cashFlowSubTab == 'B/F',
                () {
                  setState(() {
                    _selectedIndex = 1;
                    _cashFlowSubTab = 'B/F';
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSubMenuItem(String title, bool isSelected, VoidCallback onTap) => ListTile(
    title: Text(
      title,
      style: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.only(left: 48),
  );

  Widget _buildStockItem() {
    return Column(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          minLeadingWidth: 20,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: (_selectedIndex == 2 && _stockSubTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Stock',
                style: TextStyle(
                  color: (_selectedIndex == 2 && _stockSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 2 && _stockSubTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _stockExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 2 && _stockSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _stockExpanded = !_stockExpanded;
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _stockExpanded ? 192 : 0, // 48 pixels per item * 4 items
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildStockSubItem('Add New Product'),
                _buildStockSubItem('View Products'),
                _buildStockSubItem('Stock Report'),
                _buildStockSubItem('Stock Summary'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockSubItem(String tabName) {
    final isSelected = _selectedIndex == 2 && _stockSubTab == tabName;

    return Container(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.arrow_right_rounded,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
          ),
        ),
        title: Text(
          tabName,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 2;
            _stockSubTab = tabName;
          });
        },
      ),
    );
  }

  Widget _buildSalesItem() {
    return Column(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          minLeadingWidth: 20,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.point_of_sale_rounded,
              size: 20,
              color: (_selectedIndex == 10 && _salesSubTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Sales',
                style: TextStyle(
                  color: (_selectedIndex == 10 && _salesSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 10 && _salesSubTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _salesExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 10 && _salesSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _salesExpanded = !_salesExpanded;
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _salesExpanded ? 192 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSalesSubItem('Create Invoice'),
                _buildSalesSubItem('View Invoices'),
                _buildSalesSubItem('Load Form'),
                _buildSalesSubItem('Pick List'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSubItem(String tabName) {
    final isSelected = _selectedIndex == 10 && _salesSubTab == tabName;

    return Container(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.arrow_right_rounded,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
          ),
        ),
        title: Text(
          tabName,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 10;
            _salesSubTab = tabName;
          });
        },
      ),
    );
  }

  Widget _buildNewTabItem() {
    return Column(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          minLeadingWidth: 20,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.store_mall_directory_rounded,
              size: 20,
              color: (_selectedIndex == 9 && _newTabSubTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Shops',
                style: TextStyle(
                  color: (_selectedIndex == 9 && _newTabSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 9 && _newTabSubTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _newTabExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 9 && _newTabSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _newTabExpanded = !_newTabExpanded;
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _newTabExpanded ? 96 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildNewTabSubItem('Add'),
                _buildNewTabSubItem('View'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewTabSubItem(String tabName) {
    final isSelected = _selectedIndex == 9 && _newTabSubTab == tabName;

    return Container(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.arrow_right_rounded,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
          ),
        ),
        title: Text(
          tabName,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 9;
            _newTabSubTab = tabName;
          });
        },
      ),
    );
  }

  Widget _buildSupplierItem() {
    return Column(
      children: [
        ListTile(
      horizontalTitleGap: 8,
      minLeadingWidth: 20,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
              Icons.local_shipping_rounded,
          size: 20,
              color: (_selectedIndex == 13 && _selectedSupplierTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Man Power',
                style: TextStyle(
                  color: (_selectedIndex == 13 && _selectedSupplierTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 13 && _selectedSupplierTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _supplierExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 13 && _selectedSupplierTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _supplierExpanded = !_supplierExpanded;
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _supplierExpanded ? 96 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSupplierSubItem('Add'),
                _buildSupplierSubItem('View'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierSubItem(String tabName) {
    final isSelected = _selectedIndex == 13 && _selectedSupplierTab == tabName;
    return Container(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.arrow_right_rounded,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
        ),
      ),
      title: Text(
          tabName,
        style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 13;
            _selectedSupplierTab = tabName;
          });
        },
      ),
    );
  }

  Widget _buildCreditItem() {
    return Column(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          minLeadingWidth: 20,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.credit_score_rounded,
              size: 20,
              color: (_selectedIndex == 14 && _creditSubTab != null)
                  ? Colors.deepPurple
                  : Colors.grey.shade700,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Credit',
                style: TextStyle(
                  color: (_selectedIndex == 14 && _creditSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                  fontWeight: (_selectedIndex == 14 && _creditSubTab != null)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _creditExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: (_selectedIndex == 14 && _creditSubTab != null)
                      ? Colors.deepPurple
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _creditExpanded = !_creditExpanded;
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _creditExpanded ? 96 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildCreditSubItem('Ledger'),
                _buildCreditSubItem('Realisation'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditSubItem(String tabName) {
    final isSelected = _selectedIndex == 14 && _creditSubTab == tabName;
    return Container(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.arrow_right_rounded,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
          ),
        ),
        title: Text(
          tabName,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 14;
            _creditSubTab = tabName;
          });
        },
      ),
    );
  }

  Widget _buildDashItem() {
    return ListTile(
      horizontalTitleGap: 8,
      minLeadingWidth: 20,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          Icons.analytics_rounded,
          size: 20,
          color: _selectedIndex == 12 ? Colors.deepPurple : Colors.grey.shade700,
        ),
      ),
      title: Text(
        'Dashboard',
        style: TextStyle(
          color: _selectedIndex == 12 ? Colors.deepPurple : Colors.grey.shade700,
          fontWeight: _selectedIndex == 12 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSelectedScreen() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildScreenContent(),
    );
  }

  Widget _buildScreenContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildPlaceholder('Dashboard');
      case 1:
        if (_cashFlowSubTab == null) {
          return _buildCashFlowEmptyState();
        }
        return CashFlowScreen(initialTab: _cashFlowSubTab);
      case 2:
        if (_stockSubTab == null) {
          return _buildStockEmptyState();
        }
        switch (_stockSubTab) {
          case 'Add New Product':
            return const StockTab();
          case 'Stock Report':
            return const StockReportTab();
          case 'Stock Summary':
            return const StockSummaryTab();
          case 'View Products':
            return const ViewProductsTab();
          default:
            return _buildPlaceholder('Stock - $_stockSubTab');
        }
      case 9:
        if (_newTabSubTab == null) {
          return _buildNewTabEmptyState();
        }
        switch (_newTabSubTab) {
          case 'Add':
            return const AddShopTab();
          case 'View':
            return const ViewShopsTab();
          default:
            return _buildPlaceholder('Shops - $_newTabSubTab');
        }
      case 10:
        if (_salesSubTab == null) {
          return _buildSalesEmptyState();
        }
        switch (_salesSubTab) {
          case 'Create Invoice':
            return const InvoiceTab();
          case 'View Invoices':
            return const ViewInvoicesTab();
          case 'Load Form':
            return const LoadFormTab();
          case 'Pick List':
            return const PickListTab();
          default:
            return _buildPlaceholder('Sales - $_salesSubTab');
        }
      case 12:
        return const DashboardScreen();
      case 13:
        if (_selectedSupplierTab == null) {
          return _buildPlaceholder('Man Power');
        }
        switch (_selectedSupplierTab) {
          case 'Add':
            return const AddSupplierTab();
          case 'View':
            return const ViewSuppliersTab();
          default:
            return _buildPlaceholder('Man Power - $_selectedSupplierTab');
        }
      case 14:
        if (_creditSubTab == null) {
          return _buildPlaceholder('Credit');
        }
        switch (_creditSubTab) {
          case 'Ledger':
            return const LedgerTab();
          case 'Realisation':
            return const RealisationTab();
          default:
            return _buildPlaceholder('Credit - $_creditSubTab');
        }
      default:
        return _buildPlaceholder('Dashboard');
    }
  }

  Widget _buildCashFlowEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Cash Flow option',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose Income, Expenditure, or B/F from the menu',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStockEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Stock option',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from Add New Product, Update Stock, Enter Sale, Stock Summary, or Adjustments',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewTabEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a sub-item from the Shops menu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.point_of_sale_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Sales option',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from Invoice, Load Form, or Pick List',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This section is under construction',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
} 