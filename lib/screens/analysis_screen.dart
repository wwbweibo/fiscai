import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  // 计算最近7天的每日账单金额
  Map<DateTime, double> _getLast7DaysAmounts(List<Bill> bills) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6)); // 包括今天共7天
    
    // 初始化7天的金额为0
    final dailyAmounts = <DateTime, double>{};
    for (int i = 0; i < 7; i++) {
      final date = sevenDaysAgo.add(Duration(days: i));
      // 只保留日期部分，忽略时间
      final dateOnly = DateTime(date.year, date.month, date.day);
      dailyAmounts[dateOnly] = 0.0;
    }
    
    // 填充实际账单金额
    for (var bill in bills) {
      final billDate = DateTime(bill.date.year, bill.date.month, bill.date.day);
      if (dailyAmounts.containsKey(billDate)) {
        dailyAmounts[billDate] = dailyAmounts[billDate]! + bill.amount;
      }
    }
    
    return dailyAmounts;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        if (billProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        final bills = billProvider.bills;
        
        if (bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无账单记录',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '添加一些账单来查看分析数据',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
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

        final netBalance = totalIncome - totalExpense;
        
        // 计算最近7天的账单金额
        final dailyAmounts = _getLast7DaysAmounts(bills);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  '财务分析',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: '总收入',
                        amount: totalIncome,
                        icon: Icons.trending_up,
                        gradientColors: [Colors.green.shade400, Colors.green.shade600],
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: '总支出',
                        amount: totalExpense,
                        icon: Icons.trending_down,
                        gradientColors: [Colors.red.shade400, Colors.red.shade600],
                        isPositive: false,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Net balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: netBalance >= 0 
                        ? [Colors.blue.shade400, Colors.blue.shade600]
                        : [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (netBalance >= 0 ? Colors.blue : Colors.orange).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '净余额',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${netBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 近7天账单趋势图表
                _buildTrendChart(dailyAmounts),
                
                const SizedBox(height: 32),
                
                // Category breakdown header
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '支出分类统计',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Category breakdown
                if (categoryMap.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '暂无支出分类数据',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  // 按照金额从高到低排序
                  ...(categoryMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((entry) {
                    final percentage = totalExpense > 0 
                      ? (entry.value / totalExpense * 100)
                      : 0.0;
                    
                    return _buildCategoryCard(
                      category: entry.key,
                      amount: entry.value,
                      percentage: percentage,
                      totalExpense: totalExpense,
                    );
                  }).toList(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required double amount,
    required double percentage,
    required double totalExpense,
  }) {
    // 根据分类选择图标和颜色
    final categoryIcons = {
      '餐饮': Icons.restaurant,
      '购物': Icons.shopping_bag,
      '交通': Icons.directions_car,
      '娱乐': Icons.movie,
      '医疗': Icons.local_hospital,
      '教育': Icons.school,
      '住房': Icons.home,
      '其他': Icons.category,
    };

    final categoryColors = [
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];

    final icon = categoryIcons[category] ?? Icons.category;
    final color = categoryColors[category.hashCode % categoryColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '¥${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 创建近7天账单金额趋势图表
  Widget _buildTrendChart(Map<DateTime, double> dailyAmounts) {
    // 检查是否有数据
    final hasData = dailyAmounts.values.any((amount) => amount > 0);
    
    if (!hasData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图表标题
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '近7天账单趋势',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '暂无最近7天的账单数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // 按日期排序
    final sortedDates = dailyAmounts.keys.toList()..sort();
    
    // 准备图表数据
    final spots = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final amount = dailyAmounts[date]!;
      
      return FlSpot(index.toDouble(), amount);
    }).toList();
    
    // 格式化日期显示
    final dateLabels = sortedDates.map((date) {
      final day = date.day;
      final month = date.month;
      return '$month/$day';
    }).toList();
    
    // 获取最大金额用于Y轴刻度
    final maxAmount = dailyAmounts.values.reduce((a, b) => a > b ? a : b);
    final yAxisMax = maxAmount * 1.2; // 留出一些空间
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图表标题
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '近7天账单趋势',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 图表
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dateLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateLabels[index],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0');
                        return Text(
                          '¥${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                minX: 0,
                maxX: (dateLabels.length - 1).toDouble(),
                minY: 0,
                maxY: yAxisMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 图表说明
          const SizedBox(height: 8),
          Text(
            '显示最近7天的每日账单总金额趋势',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
