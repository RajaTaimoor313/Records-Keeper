import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../../../database_helper.dart';

class ViewInvoicesTab extends StatefulWidget {
  const ViewInvoicesTab({super.key});

  @override
  State<ViewInvoicesTab> createState() => _ViewInvoicesTabState();
}

class _ViewInvoicesTabState extends State<ViewInvoicesTab> {
  bool _isLoading = true;
  List<Invoice> _invoices = [];
  int _currentPage = 0;
  final Set<String> _selectedInvoices = {};
  Uint8List? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _loadLogoImage();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoicesData = await DatabaseHelper.instance.getInvoices();
      setState(() {
        _invoices = invoicesData.map((data) => Invoice.fromMap(data)).toList();
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
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Invoices'),
        content: Text('Are you sure you want to delete ${_selectedInvoices.length} selected invoice(s)?'),
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
    ) ?? false;

    if (!confirm) return;

    try {
      // Delete invoices from database
      for (final invoiceId in _selectedInvoices) {
        await DatabaseHelper.instance.deleteInvoice(invoiceId);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected invoices deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear selection and reload invoices
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

    // Create PDF document
    final pdf = pw.Document();

    // Get selected invoices
    final selectedInvoices = _invoices.where((invoice) => _selectedInvoices.contains(invoice.id)).toList();

    // Calculate number of pages needed
    final int totalPages = (selectedInvoices.length / 4).ceil();

    // Create logo image if available
    final logoImage = _logoImage != null ? pw.MemoryImage(_logoImage!) : null;

    // Generate pages
    for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIdx = pageIndex * 4;
      final endIdx = (startIdx + 4 > selectedInvoices.length) ? selectedInvoices.length : startIdx + 4;
      final pageInvoices = selectedInvoices.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),  // Wider margins for better appearance
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.8,  // Make invoices slightly taller
              mainAxisSpacing: 20,      // More space between rows
              crossAxisSpacing: 20,     // More space between columns
              children: pageInvoices.map((invoice) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.white,
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey200,
                        offset: const PdfPoint(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildPdfInvoice(invoice, logoImage),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    // Show print preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoices_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildPdfInvoice(Invoice invoice, pw.ImageProvider? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with Logo
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 24,
                height: 24,
                child: pw.ClipRRect(
                  horizontalRadius: 2,
                  verticalRadius: 2,
                  child: pw.Image(logoImage),
                ),
              ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Invoice #: ${invoice.invoiceNumber}',
                          style: pw.TextStyle(
                            fontSize: 6.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(invoice.date),
                        style: pw.TextStyle(
                          fontSize: 6.5,
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
        pw.SizedBox(height: 6),

        // Shop Details
        pw.Text(
          '${invoice.shopName}  -> code: ${invoice.shopCode}',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Owner: ${invoice.ownerName}',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple,
                ),
              ),
            ),
            pw.Text(
              'Category: ${invoice.category}',
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),

        // Items Table
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Column(
              children: [
                // Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
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
                      _buildPdfTableHeaderCell('Units', 1),
                      _buildPdfTableHeaderCell('Price', 2),
                    ],
                  ),
                ),
                // Table Rows
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      ...invoice.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1),
                          decoration: pw.BoxDecoration(
                            color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                            ),
                          ),
                          child: pw.Row(
                            children: [
                              _buildPdfTableCell((index + 1).toString(), 1),
                              _buildPdfTableCell(item.description, 4),
                              _buildPdfTableCell(item.rate.toStringAsFixed(2), 2),
                              _buildPdfTableCell(item.unit.toString(), 1),
                              _buildPdfTableCell(item.amount.toStringAsFixed(2), 2),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),

        // Totals Section
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(2),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            children: [
              _buildPdfTotalRow('Subtotal:', invoice.subtotal),
              pw.SizedBox(height: 1),
              _buildPdfTotalRow('Discount:', invoice.discount),
              pw.Divider(color: PdfColors.grey300, height: 2),
              _buildPdfTotalRow('Total:', invoice.total, isTotal: true),
            ],
          ),
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
            fontSize: 6,
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
          style: const pw.TextStyle(
            fontSize: 6,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildPdfTotalRow(String label, double amount, {bool isTotal = false}) {
    final textStyle = pw.TextStyle(
      fontSize: 6.5,
      fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: isTotal ? PdfColors.deepPurple : PdfColors.black,
    );

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: textStyle),
        pw.Text(amount.toStringAsFixed(2), style: textStyle),
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
              'Generate some invoices to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int invoicesPerRow = (maxWidth / 350).floor().clamp(1, 2);
        final double availableWidth = maxWidth - 32;
        final double scale = ((availableWidth / invoicesPerRow) / 297).clamp(0.5, 1.0);

        final int totalPages = (_invoices.length / 4).ceil();
        final int startIndex = _currentPage * 4;
        final int endIndex = (startIndex + 4 > _invoices.length)
            ? _invoices.length
            : startIndex + 4;
        final List<Invoice> currentPageInvoices =
            _invoices.sublist(startIndex, endIndex);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_selectedInvoices.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedInvoices,
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: Text('Delete (${_selectedInvoices.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _printInvoices,
                          icon: const Icon(Icons.print),
                          label: Text('Print (${_selectedInvoices.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (totalPages > 1)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          color: Colors.deepPurple,
                        ),
                        Text(
                          'Page ${_currentPage + 1} of $totalPages',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Invoices Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: currentPageInvoices.map((invoice) {
                  final bool isSelected = _selectedInvoices.contains(invoice.id);
                  return Stack(
                    children: [
                      InvoiceWidget(
                        invoice: invoice,
                        scale: scale,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
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
                                  color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 20,
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.shopName,
    required this.shopCode,
    required this.ownerName,
    required this.category,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
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
      items: (map['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList(),
      subtotal: map['subtotal'],
      discount: map['discount'],
      total: map['total'],
    );
  }
}

class InvoiceItem {
  final String description;
  final double rate;
  final int unit;
  final double amount;

  InvoiceItem({
    required this.description,
    required this.rate,
    required this.unit,
    required this.amount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'],
      rate: map['rate'],
      unit: map['unit'],
      amount: map['amount'],
    );
  }
}

class InvoiceWidget extends StatelessWidget {
  final Invoice invoice;
  final double scale;

  const InvoiceWidget({
    super.key,
    required this.invoice,
    required this.scale,
  });

  Widget _buildTableHeaderCell(String text, int flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 4 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, int flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 4 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 11 * scale,
            color: Colors.black87,
          ),
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
            fontSize: 11 * scale,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 297 * scale,
      padding: EdgeInsets.all(12.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2 * scale),
                child: Image.asset(
                  'assets/logo.png',
                  width: 40 * scale,
                  height: 40 * scale,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice #',
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                invoice.invoiceNumber,
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                DateFormat('dd/MM/yyyy').format(invoice.date),
                                style: TextStyle(
                                  fontSize: 12 * scale,
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
          SizedBox(height: 16 * scale),

          // Shop Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${invoice.shopName}  -> code: ${invoice.shopCode}',
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 4 * scale),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Owner: ${invoice.ownerName}',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      'Category: ${invoice.category}',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16 * scale),

          // Items Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTableHeaderCell('Sr.', 1, align: TextAlign.center),
                      _buildTableHeaderCell('Description', 4, align: TextAlign.center),
                      _buildTableHeaderCell('Rate', 2, align: TextAlign.center),
                      _buildTableHeaderCell('Units', 2, align: TextAlign.center),
                      _buildTableHeaderCell('Price', 2, align: TextAlign.center),
                    ],
                  ),
                ),
                // Table Rows
                ...invoice.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.grey.shade50 : Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableCell((index + 1).toString(), 1, align: TextAlign.center),
                        _buildTableCell(item.description, 4, align: TextAlign.center),
                        _buildTableCell(item.rate.toStringAsFixed(2), 2, align: TextAlign.center),
                        _buildTableCell(item.unit.toString(), 2, align: TextAlign.center),
                        _buildTableCell(item.amount.toStringAsFixed(2), 2, align: TextAlign.center),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),

          // Totals Section
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal:', invoice.subtotal),
                SizedBox(height: 4 * scale),
                _buildTotalRow('Discount:', invoice.discount),
                SizedBox(height: 4 * scale),
                Divider(color: Colors.grey.shade300),
                SizedBox(height: 4 * scale),
                _buildTotalRow('Total:', invoice.total, isTotal: true),
              ],
            ),
          ),
          SizedBox(height: 24 * scale),

          // Signature Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20 * scale,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    Text(
                      'Customer Signature',
                      style: TextStyle(fontSize: 8 * scale),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20 * scale,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    Text(
                      'Authorized Signature',
                      style: TextStyle(fontSize: 8 * scale),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 