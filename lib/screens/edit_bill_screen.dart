import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';

class EditBillScreen extends StatefulWidget {
  final Bill bill;

  const EditBillScreen({super.key, required this.bill});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late bool _isIncome;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing bill data
    _titleController = TextEditingController(text: widget.bill.title);
    _amountController = TextEditingController(text: widget.bill.amount.toString());
    _descriptionController = TextEditingController(text: widget.bill.description);
    _selectedCategory = widget.bill.category;
    _selectedPaymentMethod = widget.bill.paymentMethod;
    _isIncome = widget.bill.isIncome;
    _selectedDate = widget.bill.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedBill = widget.bill.copyWith(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        isIncome: _isIncome,
        date: _selectedDate,
      );

      await context.read<BillProvider>().updateBill(updatedBill);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('账单已更新'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败：$e'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('编辑账单'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBill,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  )
                : Text(
                    '保存',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Income/Expense Toggle
            Container(
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF64748B).withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: !_isIncome ? Color(0xFFDC2626) : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Text(
                          '支出',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isIncome ? Colors.white : Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isIncome ? Color(0xFF059669) : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Text(
                          '收入',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isIncome ? Colors.white : Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title Field
            _buildCard(
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '账单标题',
                  hintText: '输入账单标题',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入账单标题';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: 16),

            // Amount Field
            _buildCard(
              child: TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '金额',
                  hintText: '输入金额',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                  prefixText: '¥ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入金额';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: 16),

            // Category Field
            _buildCard(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '分类',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
                items: Bill.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择分类';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: 16),

            // Payment Method Field
            _buildCard(
              child: DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: '支付方式',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
                items: Bill.paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择支付方式';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: 16),

            // Date Field
            _buildCard(
              child: InkWell(
                onTap: _selectDate,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '日期时间',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Description Field
            _buildCard(
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '备注',
                  hintText: '输入备注信息（可选）',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}