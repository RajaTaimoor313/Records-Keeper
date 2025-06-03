import 'package:flutter/material.dart';
import 'package:records_keeper/screens/cash_flow_screen.dart';
import 'package:records_keeper/screens/tabs/stock_tab.dart';

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
  String? _cashFlowSubTab;
  String? _stockSubTab;
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
            _buildPanelItem(3, Icons.shopping_cart_rounded, 'Add Sales'),
            _buildPanelItem(4, Icons.store_rounded, 'Check Stock'),
            _buildPanelItem(5, Icons.people_rounded, 'Buyers List'),
            _buildPanelItem(6, Icons.payments_rounded, 'Pending Payments'),
            _buildPanelItem(7, Icons.inventory_2_rounded, 'Pending Stock'),
            _buildPanelItem(8, Icons.history_rounded, 'History'),
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
          height: _stockExpanded ? 240 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildStockSubItem('Add New Product'),
                _buildStockSubItem('Update Stock (Closing)'),
                _buildStockSubItem('Enter Sale'),
                _buildStockSubItem('Stock Summary'),
                _buildStockSubItem('Adjustments'),
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
          default:
            return _buildPlaceholder('Stock - $_stockSubTab');
        }
      case 3:
        return _buildPlaceholder('Add Sales');
      case 4:
        return _buildPlaceholder('Check Stock');
      case 5:
        return _buildPlaceholder('Buyers List');
      case 6:
        return _buildPlaceholder('Pending Payments');
      case 7:
        return _buildPlaceholder('Pending Stock');
      case 8:
        return _buildPlaceholder('History');
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