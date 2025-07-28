import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  String _selectedCategory = '全部';
  
  final List<String> _categories = ['全部', ...Bill.categories];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Load bills when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBills();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Bill> _filterBills(List<Bill> bills) {
    return bills.where((bill) {
      final matchesSearch = bill.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           bill.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == '全部' || bill.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Map<String, List<Bill>> _groupBillsByDate(List<Bill> bills) {
    final Map<String, List<Bill>> groupedBills = {};
    
    for (final bill in bills) {
      final dateKey = _formatDateKey(bill.date);
      if (!groupedBills.containsKey(dateKey)) {
        groupedBills[dateKey] = [];
      }
      groupedBills[dateKey]!.add(bill);
    }
    
    // Sort each group by time (newest first)
    groupedBills.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });
    
    return groupedBills;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final billDate = DateTime(date.year, date.month, date.day);
    
    if (billDate == today) {
      return '今天';
    } else if (billDate == yesterday) {
      return '昨天';
    } else if (now.difference(billDate).inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  double _calculateDayTotal(List<Bill> bills) {
    return bills.fold(0.0, (sum, bill) => sum + (bill.isIncome ? bill.amount : -bill.amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('账单列表'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF2563EB)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BillSearchDelegate(_filterBills),
              );
            },
          ),
          // 清空账单
          IconButton(
            icon: Icon(Icons.delete, color: Color.fromARGB(255, 250, 74, 74),),
            onPressed: () => {
              context.read<BillProvider>().clearBills(),
              context.read<BillProvider>().loadBills()
            },
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          if (billProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载中...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final allBills = billProvider.bills;
          if (allBills.isEmpty) {
            return _buildEmptyState();
          }

          final filteredBills = _filterBills(allBills);
          final groupedBills = _groupBillsByDate(filteredBills);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Statistics card
                _buildStatisticsCard(filteredBills),
                
                // Category filter
                _buildCategoryFilter(),
                
                // Bills list
                Expanded(
                  child: filteredBills.isEmpty
                      ? _buildNoResultsState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: groupedBills.length,
                          itemBuilder: (context, index) {
                            final dateKey = groupedBills.keys.elementAt(index);
                            final dayBills = groupedBills[dateKey]!;
                            final dayTotal = _calculateDayTotal(dayBills);
                            
                            return _buildDateGroup(dateKey, dayBills, dayTotal);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 60,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无账单记录',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始记录您的第一笔账单吧',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到匹配的账单',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试调整搜索条件',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(List<Bill> bills) {
    final totalIncome = bills.where((b) => b.isIncome).fold(0.0, (sum, b) => sum + b.amount);
    final totalExpense = bills.where((b) => !b.isIncome).fold(0.0, (sum, b) => sum + b.amount);
    final balance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '总余额',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('收入', totalIncome, Icons.trending_up, true),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem('支出', totalExpense, Icons.trending_down, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, IconData icon, bool isIncome) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF2563EB),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Color(0xFF2563EB),
              side: BorderSide(
                color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<Bill> bills, double dayTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${dayTotal >= 0 ? '+' : ''}¥${dayTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dayTotal >= 0 ? Color(0xFF059669) : Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          
          // Bills in this date
          ...bills.map((bill) => _buildBillCard(bill)),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showBillDetails(bill);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(bill.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(bill.category),
                    color: _getCategoryColor(bill.category),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bill info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bill.category} • ${bill.paymentMethod}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bill.isIncome ? '+' : '-'}¥${bill.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: bill.isIncome ? Color(0xFF059669) : Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bill.date.hour.toString().padLeft(2, '0')}:${bill.date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '餐饮': return Color(0xFFFF6B6B);
      case '交通': return Color(0xFF4ECDC4);
      case '购物': return Color(0xFFFFE66D);
      case '娱乐': return Color(0xFFFF8E53);
      case '医疗': return Color(0xFF95E1D3);
      case '教育': return Color(0xFFC7CEEA);
      case '住房': return Color(0xFF3D5A80);
      default: return Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '餐饮': return Icons.restaurant;
      case '交通': return Icons.directions_car;
      case '购物': return Icons.shopping_bag;
      case '娱乐': return Icons.sports_esports;
      case '医疗': return Icons.local_hospital;
      case '教育': return Icons.school;
      case '住房': return Icons.home;
      default: return Icons.category;
    }
  }

  void _showBillDetails(Bill bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              bill.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              bill.description,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('关闭'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: bill.title));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已复制账单标题')),
                    );
                  },
                  child: Text('复制'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BillSearchDelegate extends SearchDelegate {
  final List<Bill> Function(List<Bill>) filterFunction;

  BillSearchDelegate(this.filterFunction);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final bills = billProvider.bills
            .where((bill) =>
                bill.title.toLowerCase().contains(query.toLowerCase()) ||
                bill.description.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (bills.isEmpty) {
          return Center(
            child: Text('没有找到匹配的账单'),
          );
        }

        return ListView.builder(
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return ListTile(
              title: Text(bill.title),
              subtitle: Text(bill.description),
              trailing: Text('¥${bill.amount.toStringAsFixed(2)}'),
              onTap: () {
                close(context, bill);
              },
            );
          },
        );
      },
    );
  }
}