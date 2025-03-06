import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../provider/inventory_provider.dart';
import '../model/item_model.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Item item;

  const InventoryDetailScreen({super.key, required this.item});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  String? _selectedCategory;
  String? _selectedUnit;
  bool _isLoading = false;

  final List<String> _categories = [
    'Sembako',
    'Minuman',
    'Makanan',
    'Kebutuhan Pribadi',
    'Kantor',
    'Lainnya'
  ];

  final List<String> _units = ['Liter (L)', 'Kilogram (kg)', 'Pcs/Buah'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: widget.item.quantity?.toString());
    _buyPriceController =
        TextEditingController(text: widget.item.buyPrice?.toString());
    _sellPriceController =
        TextEditingController(text: widget.item.sellPrice?.toString());

    // Validasi kategori dan satuan agar sesuai dengan daftar
    _selectedCategory = _categories.contains(widget.item.category)
        ? widget.item.category
        : _categories.firstWhere(
            (category) => category == 'Lainnya',
            orElse: () => _categories.first,
          ); // Fallback ke "Lainnya" atau kategori pertama
    _selectedUnit = _units.contains(widget.item.unit)
        ? widget.item.unit
        : _units.first; // Fallback ke satuan pertama
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _updateItem(InventoryProvider provider) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }
      if (_selectedUnit == null || _selectedUnit!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih satuan terlebih dahulu')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final updatedItem = Item(
        docId: widget.item.docId,
        name: _nameController.text,
        quantity: int.parse(_quantityController.text),
        buyPrice: double.parse(_buyPriceController.text),
        sellPrice: double.parse(_sellPriceController.text),
        barcode: widget.item.barcode,
        category: _selectedCategory,
        prediction: widget.item.prediction,
        stockPrediction: widget.item.stockPrediction,
        imageUrl: widget.item.imageUrl,
        unit: _selectedUnit,
      );

      try {
        await provider.updateItem(updatedItem);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data barang diperbarui!')),
        );
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Detail Barang",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFCA28),
                    Color(0xFF4CAF50),
                  ],
                ),
              ),
            ),
            elevation: 6,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(
                      color: Color(0xFFFFCA28),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Barang',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Jumlah wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Satuan',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            items: _units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUnit = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Satuan wajib dipilih' : null,
                            hint: Text('Pilih Satuan',
                                style: GoogleFonts.poppins()),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _buyPriceController,
                            decoration: InputDecoration(
                              labelText: 'Harga Beli',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty
                                ? 'Harga beli wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sellPriceController,
                            decoration: InputDecoration(
                              labelText: 'Harga Jual',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty
                                ? 'Harga jual wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category,
                                    style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Kategori wajib dipilih' : null,
                            hint: Text('Pilih Kategori',
                                style: GoogleFonts.poppins()),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Prediksi Stok: ${widget.item.stockPrediction ?? "Belum diprediksi"}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _updateItem(provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Simpan Perubahan',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Center(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Lottie.asset(
                        'assets/loading.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
