import 'package:flutter/material.dart';
import 'package:records_keeper/screens/cash_flow_screen.dart';
import 'package:records_keeper/screens/tabs/stock_tab.dart';
import 'package:records_keeper/screens/tabs/stock_report_tab.dart';
import 'package:records_keeper/screens/tabs/stock_summary_tab.dart';
import 'package:records_keeper/screens/tabs/shops/add_shop_tab.dart';
import 'package:records_keeper/screens/tabs/shops/view_shops_tab.dart';
import 'package:records_keeper/screens/tabs/sales/invoice_tab.dart';
import 'package:records_keeper/screens/tabs/view_products_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _panelVisible = true;
  bool _cashFlowExpanded = false;
  bool _stockExpanded = false;
  bool _newTabExpanded = false;
  bool _salesExpanded = false;
  String? _cashFlowSubTab;
  String? _stockSubTab;
  String? _newTabSubTab;
  String? _salesSubTab;
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
      if (_panelVisible) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildPanelItem(0, Icons.dashboard_rounded, 'Dashboard'),
            _buildCashFlowItem(),
            _buildStockItem(),
            _buildNewTabItem(),
            _buildSalesItem(),
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
              // Don't change _selectedIndex or _cashFlowSubTab
            });
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _cashFlowExpanded ? 144 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSubItem('Income'),
                _buildSubItem('Expenditure'),
                _buildSubItem('B/F'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubItem(String tabName) {
    final isSelected = _selectedIndex == 1 && _cashFlowSubTab == tabName;

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
            _selectedIndex = 1;
            _cashFlowSubTab = tabName;
          });
        },
      ),
    );
  }

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
              // Don't change _selectedIndex or _stockSubTab
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
          height: _salesExpanded ? 144 : 0, // 48 pixels per item * 3 items
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSalesSubItem('Invoice'),
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

  Widget _buildPanelItem(int index, IconData icon, String title) {
    final isSelected = index == 1 
        ? (_selectedIndex == 1 && _cashFlowSubTab != null)
        : index == 2
            ? (_selectedIndex == 2 && _stockSubTab != null)
            : _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            if (index != 1 && index != 2) {  // Not Cash Flow or Stock
              _selectedIndex = index;
              _cashFlowExpanded = false;
              _stockExpanded = false;
              _cashFlowSubTab = null;
              _stockSubTab = null;
            }
          });
        },
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
          case 'Invoice':
            return const InvoiceTab();
          case 'Load Form':
            return _buildPlaceholder('Sales - Load Form');
          case 'Pick List':
            return _buildPlaceholder('Sales - Pick List');
          default:
            return _buildPlaceholder('Sales - $_salesSubTab');
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