import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionFilterIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);
