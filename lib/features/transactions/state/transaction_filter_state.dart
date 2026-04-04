import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionFilterIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);

final transactionCustomDateRangeProvider =
    StateProvider.autoDispose<DateTimeRange?>((ref) => null);
