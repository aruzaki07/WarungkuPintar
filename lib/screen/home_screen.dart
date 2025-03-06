// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/inventory_provider.dart';
import '../model/sale_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    provider.loadItems();
    provider.loadSales();
  }

  List<BarChartGroupData> _getSalesTrend(InventoryProvider provider) {
    final salesByDay = <int, double>{};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Hitung total penjualan per hari (7 hari terakhir)
    for (var sale in provider.sales) {
      if (sale.date != null && sale.date!.isAfter(sevenDaysAgo)) {
        final dayDiff = now.difference(sale.date!).inDays;
        salesByDay[dayDiff] =
            (salesByDay[dayDiff] ?? 0) + (sale.totalPrice ?? 0);
      }
    }

    return List.generate(7, (index) {
      final day = 6 - index; // Hari terakhir (0) sampai 6 hari lalu
      final sales = salesByDay[day] ?? 0;
      return BarChartGroupData(
        x: index + 1,
        barRods: [
          BarChartRodData(
            toY: sales,
            color: Colors.blue,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Penjualan Hari Ini",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Rp ${provider.todaySales.toStringAsFixed(0)}",
                        style:
                            const TextStyle(fontSize: 24, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tren Penjualan (7 Hari)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: _getSalesTrend(provider),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final day = 6 - (value.toInt() - 1);
                            return Text('H${day + 1}');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Stok Kritis",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: provider.criticalStock.isEmpty
                    ? const Center(child: Text("Tidak ada stok kritis"))
                    : ListView.builder(
                        itemCount: provider.criticalStock.length,
                        itemBuilder: (context, index) {
                          final item = provider.criticalStock[index];
                          return ListTile(
                            title: Text(item.name ?? ''),
                            subtitle: Text(
                                "Sisa: ${item.quantity ?? 0} ${item.prediction != null ? '- ${item.stockPrediction}' : ''}"),
                            trailing:
                                const Icon(Icons.warning, color: Colors.red),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
