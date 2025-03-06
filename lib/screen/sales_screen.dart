// // sales_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../provider/inventory_provider.dart';
//
// class SalesScreen extends StatefulWidget {
//   @override
//   _SalesScreenState createState() => _SalesScreenState();
// }
//
// class _SalesScreenState extends State<SalesScreen> {
//   String? selectedItem;
//   final _quantityController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<InventoryProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text("Penjualan"),
//             backgroundColor: Colors.blue,
//           ),
//           body: Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Card(
//                   elevation: 4,
//                   child: Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: Column(
//                       children: [
//                         DropdownButton<String>(
//                           hint: Text("Pilih Barang"),
//                           value: selectedItem,
//                           items: provider.items.map((item) {
//                             return DropdownMenuItem<String>(
//                               value: item.name,
//                               child: Text(item.name),
//                             );
//                           }).toList(),
//                           onChanged: (newValue) {
//                             setState(() {
//                               selectedItem = newValue;
//                             });
//                           },
//                         ),
//                         TextField(
//                           controller: _quantityController,
//                           decoration:
//                               InputDecoration(labelText: "Jumlah Terjual"),
//                           keyboardType: TextInputType.number,
//                         ),
//                         SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () {
//                             if (selectedItem != null) {
//                               provider.addSale(
//                                 selectedItem!,
//                                 int.parse(_quantityController.text),
//                               );
//                               _quantityController.clear();
//                               selectedItem = null;
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text("Penjualan dicatat!")),
//                               );
//                             }
//                           },
//                           child: Text("Catat Penjualan"),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: provider.sales.length,
//                     itemBuilder: (context, index) {
//                       final sale = provider.sales[index];
//                       return ListTile(
//                         title: Text("${sale.itemName} - ${sale.quantitySold}"),
//                         subtitle: Text("Rp ${sale.totalPrice}"),
//                         trailing: Text("${sale.date.day}/${sale.date.month}"),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
