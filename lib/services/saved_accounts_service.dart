import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedAccount {
  const SavedAccount({required this.email, required this.name});

  final String email;
  final String name;
}

class SavedAccountsService {
  SavedAccountsService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _indexKey = 'signl.saved.accounts';
  static const _sessionPrefix = 'signl.saved.session.';
  final FlutterSecureStorage _storage;

  Future<List<SavedAccount>> list() async {
    final raw = await _storage.read(key: _indexKey);
    if (raw == null) return const [];
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values
        .map((value) => SavedAccount(
              email: value['email'] as String,
              name: value['name'] as String? ?? value['email'] as String,
            ))
        .toList(growable: false);
  }

  Future<void> save(
      {required SavedAccount account, required String session}) async {
    final accounts =
        (await list()).where((item) => item.email != account.email).toList();
    accounts.insert(0, account);
    await _storage.write(
      key: _sessionKey(account.email),
      value: session,
    );
    await _storage.write(
      key: _indexKey,
      value: jsonEncode(accounts
          .map((item) => {'email': item.email, 'name': item.name})
          .toList()),
    );
  }

  Future<String?> sessionFor(String email) =>
      _storage.read(key: _sessionKey(email));

  Future<void> remove(String email) async {
    final accounts =
        (await list()).where((item) => item.email != email).toList();
    await _storage.delete(key: _sessionKey(email));
    await _storage.write(
      key: _indexKey,
      value: jsonEncode(accounts
          .map((item) => {'email': item.email, 'name': item.name})
          .toList()),
    );
  }

  Future<void> clear() async {
    for (final account in await list()) {
      await _storage.delete(key: _sessionKey(account.email));
    }
    await _storage.delete(key: _indexKey);
  }

  String _sessionKey(String email) =>
      '$_sessionPrefix${base64Url.encode(utf8.encode(email.toLowerCase()))}';
}
