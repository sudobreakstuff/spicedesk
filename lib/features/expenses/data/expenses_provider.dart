import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../workspace/domain/workspace_state.dart';

final expensesProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];
  final data = await supabase.from('expenses').select('*').eq('workspace_id',wsId).order('created_at',ascending:false).limit(200);
  return data.map<ExpenseItem>((row)=>(ExpenseItem(id:row['id'],description:row['description']??'',category:row['category']??'general',amount:(row['amount']as num?)?.toDouble()??0,date:DateTime.tryParse(row['expense_date']??'')??DateTime.now(),notes:row['notes']))).toList();
});

final monthlyExpensesProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final now = DateTime.now();
  double sum = 0;
  for (final e in expenses) {
    if (e.date.month == now.month && e.date.year == now.year) {
      sum += e.amount;
    }
  }
  return sum;
});

class ExpenseItem { final String id,description,category; final double amount; final DateTime date; final String? notes; const ExpenseItem({required this.id,required this.description,this.category='general',required this.amount,required this.date,this.notes});}
