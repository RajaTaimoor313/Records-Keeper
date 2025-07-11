import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:haider_traders/tabs/sales/invoice_tab.dart';

class ViewInvoicesTab extends StatefulWidget {
  const ViewInvoicesTab({super.key});

  @override
  State<ViewInvoicesTab> createState() => _ViewInvoicesTabState();
}

class _ViewInvoicesTabState extends State<ViewInvoicesTab> {
  bool _isLoading = true;
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  final Set<String> _selectedInvoices = {};
  Uint8List? _logoImage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _loadLogoImage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = _invoices;
      } else {
        _filteredInvoices = _invoices.where((invoice) {
          final invoiceNumber = invoice.invoiceNumber.toLowerCase();
          final shopName = invoice.shopName.toLowerCase();
          final ownerName = invoice.ownerName.toLowerCase();
          final searchLower = query.toLowerCase();

          return invoiceNumber.contains(searchLower) ||
              shopName.contains(searchLower) ||
              ownerName.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoicesData = await DatabaseHelper.instance.getInvoices();
      setState(() {
        _invoices = invoicesData.map((data) => Invoice.fromMap(data)).toList();
        _filteredInvoices = _invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLogoImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      setState(() {
        _logoImage = data.buffer.asUint8List();
      });
    } catch (e) {
      print('Error loading logo: $e');
    }
  }

  Future<void> _deleteSelectedInvoices() async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Selected Invoices'),
            content: Text(
              'Are you sure you want to delete ${_selectedInvoices.length} selected invoice(s)?',
            ),
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
        ) ??
        false;

    if (!confirm) return;

    try {
      for (final invoiceId in _selectedInvoices) {
        await DatabaseHelper.instance.deleteInvoice(invoiceId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected invoices deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedInvoices.clear();
      });
      await _loadInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting invoices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoices() async {
    if (_selectedInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one invoice to print'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final selectedInvoices = _invoices
        .where((invoice) => _selectedInvoices.contains(invoice.id))
        .toList();

    final int totalPages = (selectedInvoices.length / 4).ceil();

    final logoImage = _logoImage != null ? pw.MemoryImage(_logoImage!) : null;

    for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIdx = pageIndex * 4;
      final endIdx = (startIdx + 4 > selectedInvoices.length)
          ? selectedInvoices.length
          : startIdx + 4;
      final pageInvoices = selectedInvoices.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: pageInvoices.map((invoice) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: _buildPdfInvoice(invoice, logoImage),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoices_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildPdfInvoice(Invoice invoice, pw.ImageProvider? logoImage) {
    final indianFormat = NumberFormat.decimalPattern('en_IN');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 32,
                height: 32,
                child: pw.ClipRRect(
                  horizontalRadius: 2,
                  verticalRadius: 2,
                  child: pw.Image(logoImage),
                ),
              ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Invoice #: ${invoice.invoiceNumber}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(invoice.date),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),

        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                invoice.shopName,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple,
                ),
              ),
            ),
            pw.Text(
              'Address: ${invoice.address ?? 'N/A'}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(2),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    _buildPdfTableHeaderCell('Sr.', 1),
                    _buildPdfTableHeaderCell('Description', 4),
                    _buildPdfTableHeaderCell('Rate', 2),
                    _buildPdfTableHeaderCell('Unit', 1),
                    _buildPdfTableHeaderCell('Price', 2),
                  ],
                ),
              ),
              ...invoice.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      _buildPdfTableCell((index + 1).toString(), 1),
                      _buildPdfTableCell(item.description, 4),
                      _buildPdfTableCell(indianFormat.format(item.rate), 2),
                      _buildPdfTableCell(item.unit.toString(), 1),
                      _buildPdfTableCell(indianFormat.format(item.amount), 2),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(2),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            children: [
              _buildPdfTotalRow('Subtotal:', invoice.subtotal, indianFormat),
              pw.SizedBox(height: 3),
              _buildPdfTotalRow('Discount:', invoice.discount, indianFormat),
              pw.Divider(color: PdfColors.grey300, height: 4),
              _buildPdfTotalRow(
                'Total:',
                invoice.total,
                indianFormat,
                isTotal: true,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 20,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Customer Signature',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 20,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableHeaderCell(String text, int flex) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, int flex) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7.5),
        ),
      ),
    );
  }

  pw.Widget _buildPdfTotalRow(
    String label,
    double amount,
    NumberFormat? indianFormat, {
    bool isTotal = false,
  }) {
    final textStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: isTotal ? PdfColors.deepPurple : PdfColors.black,
    );

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: textStyle),
        pw.Text(
          indianFormat != null
              ? indianFormat.format(amount)
              : amount.toStringAsFixed(2),
          style: textStyle,
        ),
      ],
    );
  }

  void _showCompleteInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 297,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INVOICE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Invoice #',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            invoice.invoiceNumber,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(invoice.date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.shopName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Address: ${invoice.address ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildTableHeaderCell(
                                    'Sr.',
                                    1,
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'Description',
                                    4,
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'Rate',
                                    2,
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'Unit',
                                    2,
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'Price',
                                    2,
                                    align: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            ...invoice.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? Colors.grey.shade50
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildTableCell(
                                      (index + 1).toString(),
                                      1,
                                      align: TextAlign.center,
                                    ),
                                    _buildTableCell(
                                      item.description,
                                      4,
                                      align: TextAlign.center,
                                    ),
                                    _buildTableCell(
                                      item.rate.toStringAsFixed(2),
                                      2,
                                      align: TextAlign.center,
                                    ),
                                    _buildTableCell(
                                      item.unit.toString(),
                                      2,
                                      align: TextAlign.center,
                                    ),
                                    _buildTableCell(
                                      item.amount.toStringAsFixed(2),
                                      2,
                                      align: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            _buildTotalRow('Subtotal:', invoice.subtotal),
                            const SizedBox(height: 4),
                            _buildTotalRow('Discount:', invoice.discount),
                            const SizedBox(height: 4),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 4),
                            _buildTotalRow(
                              'Total:',
                              invoice.total,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Customer Signature',
                                  style: TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Authorized Signature',
                                  style: TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String text,
    int flex, {
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text,
    int flex, {
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create some invoices to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final unGeneratedInvoices = _filteredInvoices
        .where((inv) => inv.generated != 1)
        .toList();
    final generatedInvoices = _filteredInvoices
        .where((inv) => inv.generated == 1)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search the Invoice...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterInvoices('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _filterInvoices,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectedInvoices.isEmpty
                        ? null
                        : _deleteSelectedInvoices,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text('Delete (${_selectedInvoices.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedInvoices.isEmpty
                        ? null
                        : _printInvoices,
                    icon: const Icon(Icons.print),
                    label: Text('Print (${_selectedInvoices.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _selectedInvoices.length == 1 &&
                            _filteredInvoices
                                    .firstWhere(
                                      (inv) =>
                                          inv.id == _selectedInvoices.first,
                                    )
                                    .generated !=
                                1
                        ? () async {
                            final selectedInvoice = _filteredInvoices
                                .firstWhere(
                                  (inv) => inv.id == _selectedInvoices.first,
                                );
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    InvoiceTab(invoiceToEdit: selectedInvoice),
                              ),
                            );
                            await _loadInvoices();
                          }
                        : null,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _selectedInvoices.isEmpty ||
                            _selectedInvoices.any(
                              (id) =>
                                  _filteredInvoices
                                      .firstWhere((inv) => inv.id == id)
                                      .generated ==
                                  1,
                            )
                        ? null
                        : _generateSelectedInvoices,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredInvoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matching invoices found',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try different search terms',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (unGeneratedInvoices.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: const [
                              Text(
                                'Un-Generated Invoices',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: unGeneratedInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = unGeneratedInvoices[index];
                            final bool isSelected = _selectedInvoices.contains(
                              invoice.id,
                            );
                            return _buildInvoiceCard(
                              invoice,
                              isSelected,
                              index,
                            );
                          },
                        ),
                      ],
                      if (generatedInvoices.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: const [
                              Text(
                                'Generated Invoices',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: generatedInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = generatedInvoices[index];
                            final bool isSelected = _selectedInvoices.contains(
                              invoice.id,
                            );
                            return _buildInvoiceCard(
                              invoice,
                              isSelected,
                              index,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _generateSelectedInvoices() async {
    if (_selectedInvoices.isEmpty) return;
    final alreadyGenerated = _selectedInvoices
        .where(
          (id) =>
              _filteredInvoices.firstWhere((inv) => inv.id == id).generated ==
              1,
        )
        .toList();
    if (alreadyGenerated.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some selected invoices are already generated.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      for (final invoiceId in _selectedInvoices) {
        final invoiceMap = await DatabaseHelper.instance.getInvoice(invoiceId);
        if (invoiceMap == null) continue;
        final invoice = Invoice.fromMap(invoiceMap);
        if (invoice.generated == 1) continue;
        for (final item in invoice.items) {
          await DatabaseHelper.instance.insertLoadFormItem({
            'brandName': item.description,
            'units': item.unit,
          });
        }
        await DatabaseHelper.instance.insertOrUpdatePickListItem({
          'code': invoice.shopCode,
          'shopName': invoice.shopName,
          'ownerName': invoice.ownerName,
          'billAmount': invoice.total,
          'recovery': 0,
          'discount': 0,
          'return': 0,
          'cash': 0,
          'credit': 0,
          'invoiceNumber': invoice.invoiceNumber,
        });
        await DatabaseHelper.instance.updateInvoiceGenerated(invoiceId, 1);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected invoices generated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _selectedInvoices.clear();
      });
      await _loadInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInvoiceCard(Invoice invoice, bool isSelected, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _showCompleteInvoice(context, invoice),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInvoices.remove(invoice.id);
                      } else {
                        _selectedInvoices.add(invoice.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.shopName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${invoice.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String shopName;
  final String shopCode;
  final String ownerName;
  final String category;
  final String? address;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final int generated;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.shopName,
    required this.shopCode,
    required this.ownerName,
    required this.category,
    this.address,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.generated,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      date: DateTime.parse(map['date']),
      shopName: map['shopName'],
      shopCode: map['shopCode'],
      ownerName: map['ownerName'],
      category: map['category'],
      address: map['address'],
      items: (map['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList(),
      subtotal: map['subtotal'],
      discount: map['discount'],
      total: map['total'],
      generated: map['generated'],
    );
  }
}

class InvoiceItem {
  final String description;
  final String company;
  final double rate;
  final int unit;
  final double amount;

  InvoiceItem({
    required this.description,
    required this.company,
    required this.rate,
    required this.unit,
    required this.amount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'],
      company: map['company'] ?? '',
      rate: map['rate'],
      unit: map['unit'],
      amount: map['amount'],
    );
  }
}
