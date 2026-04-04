import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';

final budgetsListProvider =
    StateProvider.autoDispose<List<Budget>>((ref) => const <Budget>[]);
final budgetsLoadingProvider = StateProvider.autoDispose<bool>((ref) => true);
