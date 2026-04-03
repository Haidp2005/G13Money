import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final email = Platform.environment['FIREBASE_SEED_EMAIL'] ?? 'seed@g13money.com';
  final password = Platform.environment['FIREBASE_SEED_PASSWORD'] ?? '12345678';

  final auth = FirebaseAuth.instance;
  UserCredential credential;

  try {
    credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (error) {
    if (error.code == 'user-not-found' || error.code == 'invalid-credential') {
      credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      stderr.writeln('Auth error: ${error.code} ${error.message ?? ''}');
      exitCode = 1;
      return;
    }
  }

  final user = credential.user;
  if (user == null) {
    stderr.writeln('Unable to resolve authenticated user.');
    exitCode = 1;
    return;
  }

  final uid = user.uid;
  final db = FirebaseFirestore.instance;
  final userRef = db.collection('users').doc(uid);
  final now = DateTime.now();
  final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final accountCashRef = userRef.collection('accounts').doc('acc_cash');
  final accountBankRef = userRef.collection('accounts').doc('acc_vcb');

  final categoryFoodRef = userRef.collection('categories').doc('cat_food');
  final categorySalaryRef = userRef.collection('categories').doc('cat_salary');

  final txIncomeRef = userRef.collection('transactions').doc('txn_income_seed_001');
  final txExpenseRef = userRef.collection('transactions').doc('txn_expense_seed_001');

  final budgetFoodRef = userRef.collection('budgets').doc('budget_food_seed_001');
  final notificationRef = userRef.collection('notifications').doc('noti_seed_001');
  final settingsProfileRef = userRef.collection('settings').doc('profile');
  final settingsPreferencesRef = userRef.collection('settings').doc('preferences');

  final batch = db.batch();

  batch.set(userRef, {
    'fullName': 'G13 Demo User',
    'email': email,
    'phone': '0900000000',
    'avatarInitials': 'GD',
    'currency': 'VND',
    'locale': 'vi',
    'joinedAt': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(accountCashRef, {
    'name': 'Tien mat',
    'type': 'cash',
    'balance': 2500000,
    'colorHex': '#F2994A',
    'isArchived': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(accountBankRef, {
    'name': 'Vietcombank',
    'type': 'bank',
    'balance': 12000000,
    'colorHex': '#27AE60',
    'isArchived': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(categoryFoodRef, {
    'name': 'An uong',
    'type': 'expense',
    'iconKey': 'restaurant',
    'colorHex': '#E07A5F',
    'isDefault': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(categorySalaryRef, {
    'name': 'Luong',
    'type': 'income',
    'iconKey': 'payments',
    'colorHex': '#22B45E',
    'isDefault': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(txIncomeRef, {
    'title': 'Luong thang',
    'note': 'Seed data',
    'amount': 12000000,
    'type': 'income',
    'isIncome': true,
    'categoryId': 'cat_salary',
    'categoryName': 'Luong',
    'walletId': 'acc_vcb',
    'walletName': 'Vietcombank',
    'date': Timestamp.fromDate(DateTime(now.year, now.month, 1)),
    'attachmentUrls': <String>[],
    'tags': <String>['seed'],
    'year': now.year,
    'month': now.month,
    'day': 1,
    'yearMonth': yearMonth,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(txExpenseRef, {
    'title': 'An uong',
    'note': 'Seed data',
    'amount': 180000,
    'type': 'expense',
    'isIncome': false,
    'categoryId': 'cat_food',
    'categoryName': 'An uong',
    'walletId': 'acc_cash',
    'walletName': 'Tien mat',
    'date': Timestamp.fromDate(DateTime(now.year, now.month, 2)),
    'attachmentUrls': <String>[],
    'tags': <String>['seed'],
    'year': now.year,
    'month': now.month,
    'day': 2,
    'yearMonth': yearMonth,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(budgetFoodRef, {
    'title': 'An uong thang nay',
    'categoryId': 'cat_food',
    'categoryName': 'An uong',
    'walletId': 'ALL',
    'walletName': 'Tat ca vi',
    'limit': 3000000,
    'spent': 180000,
    'startDate': Timestamp.fromDate(DateTime(now.year, now.month, 1)),
    'endDate': Timestamp.fromDate(DateTime(now.year, now.month + 1, 0)),
    'periodKey': yearMonth,
    'colorHex': '#E07A5F',
    'iconKey': 'restaurant',
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(notificationRef, {
    'type': 'system',
    'title': 'Khoi tao du lieu mau',
    'body': 'Da tao thanh cong collection Firestore cho nguoi dung demo.',
    'isRead': false,
    'meta': {
      'source': 'seed_script',
    },
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(settingsProfileRef, {
    'fullName': 'G13 Demo User',
    'phone': '0900000000',
    'avatarUrl': '',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  batch.set(settingsPreferencesRef, {
    'language': 'vi',
    'themeMode': 'system',
    'budgetAlerts': true,
    'dailyReminder': false,
    'billReminder': false,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await batch.commit();

  stdout.writeln('Seed Firestore completed for uid: $uid');
  stdout.writeln('Email used: $email');
}
