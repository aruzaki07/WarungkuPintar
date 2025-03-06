// lib/provider/inventory_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/item_model.dart';
import '../model/sale_model.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../services/prediction_service.dart';

class InventoryProvider with ChangeNotifier {
  final List<Item> _items = [];
  final List<Sale> _sales = [];
  final FirestoreService _firestoreService = FirestoreService();

  List<Item> get items => _items;
  List<Sale> get sales => _sales;
  double get todaySales => _calculateTodaySales();
  List<Item> get criticalStock => _items.where((item) => (item.quantity ?? 0) <= 5).toList();

  Future<void> addItem(String name, int quantity, double buyPrice, double sellPrice, String category, String unit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final item = Item(
      name: name,
      quantity: quantity,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      barcode: "BRG-${DateTime.now().millisecondsSinceEpoch}",
      category: category,
      prediction: 'Diprediksi oleh AI (Google Cloud NLP)',
      stockPrediction: null,
      imageUrl: null,
      unit: unit,
    );

    await _firestoreService.createItem(user.uid, item);
    final newItem = await _getItemFromFirestore(user.uid, item);
    if (!_items.any((existingItem) => existingItem.docId == newItem.docId)) {
      _items.add(newItem);
      notifyListeners();
    }
  }

  Future<void> updateItem(Item item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    if (item.docId == null) throw Exception('Item ID not found');

    await _firestoreService.updateItem(userId, item);
    final index = _items.indexWhere((existingItem) => existingItem.docId == item.docId);
    if (index != -1) {
      final updatedItem = Item(
        docId: item.docId,
        name: item.name,
        quantity: item.quantity,
        buyPrice: item.buyPrice,
        sellPrice: item.sellPrice,
        barcode: item.barcode,
        category: item.category,
        prediction: item.prediction,
        stockPrediction: predictStockForItem(item), // Update prediksi stok
        imageUrl: item.imageUrl,
        unit: item.unit,
      );
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  Future<Item> _getItemFromFirestore(String userId, Item item) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .where('name', isEqualTo: item.name)
        .where('quantity', isEqualTo: item.quantity)
        .where('buy_price', isEqualTo: item.buyPrice)
        .where('sell_price', isEqualTo: item.sellPrice)
        .get();
    if (query.docs.isNotEmpty) {
      return Item.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return item;
  }

  Future<void> deleteItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    await _firestoreService.deleteItem(userId, docId);
    _items.removeWhere((item) => item.docId == docId);
    notifyListeners();
  }

  void loadItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getItems(user.uid).listen((items) {
        final uniqueItems = <Item>[];
        for (final item in items) {
          final updatedItem = Item(
            docId: item.docId,
            name: item.name,
            quantity: item.quantity,
            buyPrice: item.buyPrice,
            sellPrice: item.sellPrice,
            barcode: item.barcode,
            category: item.category,
            prediction: item.prediction,
            stockPrediction: predictStockForItem(item),
            imageUrl: item.imageUrl,
            unit: item.unit,
          );
          if (!uniqueItems.any((existingItem) => existingItem.docId == updatedItem.docId)) {
            uniqueItems.add(updatedItem);
          }
        }
        _items.clear();
        _items.addAll(uniqueItems);
        notifyListeners();
      }, onError: (error) {
        debugPrint('Error loading items: $error');
      });
    }
  }

  String predictStockForItem(Item item) {
    return PredictionService.predictStockExhaustion(item, _sales);
  }

  void loadSales() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getSales(user.uid).listen((sales) {
        _sales.clear();
        _sales.addAll(sales);
        final updatedItems = _items.map((item) {
          return Item(
            docId: item.docId,
            name: item.name,
            quantity: item.quantity,
            buyPrice: item.buyPrice,
            sellPrice: item.sellPrice,
            barcode: item.barcode,
            category: item.category,
            prediction: item.prediction,
            stockPrediction: predictStockForItem(item),
            imageUrl: item.imageUrl,
            unit: item.unit,
          );
        }).toList();
        _items.clear();
        _items.addAll(updatedItems);
        notifyListeners();
      }, onError: (error) {
        debugPrint('Error loading sales: $error');
      });
    }
  }

  double _calculateTodaySales() {
    final now = DateTime.now();
    return _sales
        .where((sale) =>
    sale.date != null &&
        sale.date!.day == now.day &&
        sale.date!.month == now.month &&
        sale.date!.year == now.year)
        .fold(0, (total, sale) => total + (sale.totalPrice ?? 0));
  }

  Future<void> addSale(String itemName, int quantitySold, double totalPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final sale = Sale(
      itemName: itemName,
      quantitySold: quantitySold,
      totalPrice: totalPrice,
      date: DateTime.now(),
    );

    await _firestoreService.createSale(user.uid, sale);
    _sales.add(sale);
    final updatedItems = _items.map((item) {
      if (item.name == itemName) {
        return Item(
          docId: item.docId,
          name: item.name,
          quantity: item.quantity! - quantitySold,
          buyPrice: item.buyPrice,
          sellPrice: item.sellPrice,
          barcode: item.barcode,
          category: item.category,
          prediction: item.prediction,
          stockPrediction: predictStockForItem(item),
          imageUrl: item.imageUrl,
          unit: item.unit,
        );
      }
      return item;
    }).toList();
    _items.clear();
    _items.addAll(updatedItems);
    notifyListeners();
  }

  Future<void> deleteSale(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    await _firestoreService.deleteSale(userId, docId);
    final saleToDelete = _sales.firstWhere((sale) => sale.docId == docId);
    _sales.removeWhere((sale) => sale.docId == docId);
    notifyListeners();
  }
}