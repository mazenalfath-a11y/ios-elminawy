import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SavedAccount {
  final String id;
  final String email;
  final String password;
  final String companyCode;
  final String companyName;
  final String token;
  final DateTime lastUsed;
  final String studentName;
  final String studentId;

  SavedAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.companyCode,
    required this.companyName,
    required this.token,
    required this.lastUsed,
    required this.studentName,
    required this.studentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'companyCode': companyCode,
        'companyName': companyName,
        'token': token,
        'lastUsed': lastUsed.toIso8601String(),
        'studentName': studentName,
        'studentId': studentId,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        id: json['id'],
        email: json['email'],
        password: json['password'],
        companyCode: json['companyCode'],
        companyName: json['companyName'],
        token: json['token'],
        lastUsed: DateTime.parse(json['lastUsed']),
        studentName: json['studentName'],
        studentId: json['studentId'],
      );
}

class SavedAccountsManager {
  static const String _accountsKey = 'saved_accounts';
  static const String _activeAccountIdKey = 'active_account_id';
  static final _storage = FlutterSecureStorage();
  static final _uuid = Uuid();

  // Save a new account after successful login
  static Future<void> saveAccount({
    required String email,
    required String password,
    required String companyCode,
    required String companyName,
    required String token,
    required String studentName,
    required String studentId,
  }) async {
    final accounts = await getAccounts();
    
    // Check if account already exists (same email + company)
    final existingIndex = accounts.indexWhere(
      (acc) => acc.email == email && acc.companyCode == companyCode,
    );

    if (existingIndex != -1) {
      // Update existing account
      accounts[existingIndex] = SavedAccount(
        id: accounts[existingIndex].id,
        email: email,
        password: password,
        companyCode: companyCode,
        companyName: companyName,
        token: token,
        lastUsed: DateTime.now(),
        studentName: studentName,
        studentId: studentId,
      );
    } else {
      // Add new account
      final newAccount = SavedAccount(
        id: _uuid.v4(),
        email: email,
        password: password,
        companyCode: companyCode,
        companyName: companyName,
        token: token,
        lastUsed: DateTime.now(),
        studentName: studentName,
        studentId: studentId,
      );
      accounts.add(newAccount);
    }

    await _saveAccounts(accounts);
    
    // Set as active account
    final accountId = existingIndex != -1 
        ? accounts[existingIndex].id 
        : accounts.last.id;
    await _storage.write(key: _activeAccountIdKey, value: accountId);
  }

  // Get all saved accounts
  static Future<List<SavedAccount>> getAccounts() async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      return decoded.map((json) => SavedAccount.fromJson(json)).toList();
    } catch (e) {
      print('Error loading saved accounts: $e');
      return [];
    }
  }

  // Get currently active account
  static Future<SavedAccount?> getActiveAccount() async {
    final activeId = await _storage.read(key: _activeAccountIdKey);
    if (activeId == null) return null;

    final accounts = await getAccounts();
    try {
      return accounts.firstWhere((acc) => acc.id == activeId);
    } catch (e) {
      return null;
    }
  }

  // Switch to a different account
  static Future<void> switchAccount(String accountId) async {
    final accounts = await getAccounts();
    final accountIndex = accounts.indexWhere((acc) => acc.id == accountId);
    
    if (accountIndex == -1) {
      throw Exception('Account not found');
    }

    // Update last used timestamp
    accounts[accountIndex] = SavedAccount(
      id: accounts[accountIndex].id,
      email: accounts[accountIndex].email,
      password: accounts[accountIndex].password,
      companyCode: accounts[accountIndex].companyCode,
      companyName: accounts[accountIndex].companyName,
      token: accounts[accountIndex].token,
      lastUsed: DateTime.now(),
      studentName: accounts[accountIndex].studentName,
      studentId: accounts[accountIndex].studentId,
    );

    await _saveAccounts(accounts);
    await _storage.write(key: _activeAccountIdKey, value: accountId);
  }

  // Remove an account
  static Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((acc) => acc.id == accountId);
    await _saveAccounts(accounts);

    // If removed account was active, clear active account
    final activeId = await _storage.read(key: _activeAccountIdKey);
    if (activeId == accountId) {
      await _storage.delete(key: _activeAccountIdKey);
    }
  }

  // Update account's last used timestamp
  static Future<void> updateAccountLastUsed(String accountId) async {
    final accounts = await getAccounts();
    final accountIndex = accounts.indexWhere((acc) => acc.id == accountId);
    
    if (accountIndex == -1) return;

    accounts[accountIndex] = SavedAccount(
      id: accounts[accountIndex].id,
      email: accounts[accountIndex].email,
      password: accounts[accountIndex].password,
      companyCode: accounts[accountIndex].companyCode,
      companyName: accounts[accountIndex].companyName,
      token: accounts[accountIndex].token,
      lastUsed: DateTime.now(),
      studentName: accounts[accountIndex].studentName,
      studentId: accounts[accountIndex].studentId,
    );

    await _saveAccounts(accounts);
  }

  // Clear all accounts (for testing or logout all)
  static Future<void> clearAllAccounts() async {
    await _storage.delete(key: _accountsKey);
    await _storage.delete(key: _activeAccountIdKey);
  }

  // Private helper to save accounts list
  static Future<void> _saveAccounts(List<SavedAccount> accounts) async {
    final accountsJson = jsonEncode(accounts.map((acc) => acc.toJson()).toList());
    await _storage.write(key: _accountsKey, value: accountsJson);
  }
}
