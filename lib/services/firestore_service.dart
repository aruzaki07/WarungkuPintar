// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/item_model.dart';
import '../model/sale_model.dart';
import '../services/ai_service.dart';
import '../services/prediction_service.dart';
import '../provider/inventory_provider.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createItem(String userId, Item item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final predictedCategory = await AIService.predictCategory(item.name);
    final itemWithCategory = Item(
      name: item.name,
      quantity: item.quantity,
      buyPrice: item.buyPrice,
      sellPrice: item.sellPrice,
      barcode: item.barcode,
      category: predictedCategory,
      prediction: 'Diprediksi oleh AI (Google Cloud NLP)',
      stockPrediction: null,
      imageUrl: item.imageUrl,
      unit: item.unit,
    );

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .add(itemWithCategory.toMap());

    final provider = InventoryProvider();
    provider.loadSales();
    final stockPrediction = PredictionService.predictStockExhaustion(itemWithCategory, provider.sales);
    await docRef.update({'stock_prediction': stockPrediction});
  }

  Future<void> updateItem(String userId, Item item) async {
    if (item.docId == null) throw Exception('Item ID not found');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .doc(item.docId)
        .update(item.toMap());
  }

  Future<void> deleteItem(String userId, String docId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .doc(docId)
        .delete();
  }

  Stream<List<Item>> getItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Item.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<Sale>> getSales(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sales')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Sale.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> createSale(String userId, Sale sale) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sales')
        .add(sale.toMap());
  }

  Future<void> deleteSale(String userId, String docId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sales')
        .doc(docId)
        .delete();
  }
}