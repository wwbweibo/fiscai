import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        if (billProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final bills = billProvider.bills;
        
        if (bills.isEmpty) {
          return const Center(
            child: Text(
              '暂无账单记录，无法进行分析',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        // Calculate statistics
        double totalIncome = 0;
        double totalExpense = 0;
        
        // Category breakdown
        final categoryMap = <String, double>{};
        
        for (var bill in bills) {
          if (bill.isIncome) {
            totalIncome += bill.amount;
          } else {
            totalExpense += bill.amount;
            
            if (categoryMap.containsKey(bill.category)) {
              categoryMap[bill.category] = categoryMap[bill.category]! + bill.amount;
            } else {
              categoryMap[bill.category] = bill.amount;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              '总收入',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '¥${totalIncome.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              '总支出',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '¥${totalExpense.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Net balance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '净余额',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '¥${(totalIncome - totalExpense).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: (totalIncome - totalExpense) >= 0 
                            ? Colors.green 
                            : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Category breakdown
              const Text(
                '分类统计',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              ...categoryMap.entries.map((entry) {
                final percentage = totalExpense > 0 
                  ? (entry.value / totalExpense * 100).toStringAsFixed(1) 
                  : '0.0';
                
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    trailing: Text('¥${entry.value.toStringAsFixed(2)} ($percentage%)'),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}