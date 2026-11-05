import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'demo_data.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Thin REST client for the EPay backend.
///
/// Every call falls back to the bundled [Demo] dataset when the backend is
/// unreachable (and [AppConfig.demoFallback] is on), so the UI always has
/// something to render.
class Api {
  Api._();
  static final Api i = Api._();

  String? token;
  bool usingDemo = false;

  final _client = http.Client();
  static const _timeout = Duration(seconds: 12);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$base$path').replace(
      queryParameters: (q == null || q.isEmpty) ? null : q,
    );
  }

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? '{}' : r.body;
    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw ApiException('Unexpected server response', r.statusCode);
    }
    if (r.statusCode >= 400) {
      final msg = (json is Map && json['error'] != null)
          ? '${json['error']}'
          : 'Request failed (${r.statusCode})';
      throw ApiException(msg, r.statusCode);
    }
    return json;
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    final r = await _client.get(_uri(path, query), headers: _headers).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final req = http.Request(method, _uri(path))
      ..headers.addAll(_headers)
      ..body = jsonEncode(body ?? const {});
    final streamed = await _client.send(req).timeout(_timeout);
    return _decode(await http.Response.fromStream(streamed));
  }

  Future<dynamic> _post(String p, [Map<String, dynamic>? b]) => _send('POST', p, b);
  Future<dynamic> _patch(String p, [Map<String, dynamic>? b]) => _send('PATCH', p, b);

  /// Runs [live]; if the network fails, returns [fallback] instead.
  Future<T> _guard<T>(Future<T> Function() live, T Function() fallback) async {
    try {
      final v = await live();
      usingDemo = false;
      return v;
    } on ApiException {
      rethrow; // a real server answer — surface it
    } catch (_) {
      if (!AppConfig.demoFallback) {
        throw ApiException('Cannot reach the server. Check your connection.');
      }
      usingDemo = true;
      return fallback();
    }
  }

  List<Map<String, dynamic>> _list(dynamic v) => (v as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);

  // ---------------------------------------------------------------- auth ----

  Future<String> requestOtp(String phone) => _guard(
        () async {
          final r = await _post('/auth/otp', {'phone': phone});
          return '${(r as Map)['devCode'] ?? ''}';
        },
        () => '123456',
      );

  Future<({String token, AppUser user})> login(String phone, String password) =>
      _guard(
        () async {
          final r = await _post('/auth/login', {
            'phone': phone,
            'password': password,
          }) as Map<String, dynamic>;
          return (
            token: '${r['token']}',
            user: AppUser.fromJson(Map<String, dynamic>.from(r['user'] as Map)),
          );
        },
        () {
          Demo.i.user['phone'] = phone;
          return (token: 'demo-token', user: AppUser.fromJson(Demo.i.user));
        },
      );

  Future<({String token, AppUser user})> register({
    required String phone,
    required String password,
    required String nickname,
    String? inviteCode,
    String? otp,
  }) =>
      _guard(
        () async {
          final r = await _post('/auth/register', {
            'phone': phone,
            'password': password,
            'nickname': nickname,
            'inviteCode': inviteCode,
            'otp': otp,
          }) as Map<String, dynamic>;
          return (
            token: '${r['token']}',
            user: AppUser.fromJson(Map<String, dynamic>.from(r['user'] as Map)),
          );
        },
        () {
          Demo.i.reset();
          Demo.i.user['phone'] = phone;
          Demo.i.user['nickname'] = nickname;
          return (token: 'demo-token', user: AppUser.fromJson(Demo.i.user));
        },
      );

  Future<AppUser> me() => _guard(
        () async => AppUser.fromJson(
            Map<String, dynamic>.from(await _get('/me') as Map)),
        () => AppUser.fromJson(Demo.i.user),
      );

  Future<AppUser> updateProfile({String? nickname, String? avatar}) => _guard(
        () async => AppUser.fromJson(Map<String, dynamic>.from(
            await _patch('/me', {'nickname': nickname, 'avatar': avatar}) as Map)),
        () {
          if (nickname != null) Demo.i.user['nickname'] = nickname;
          if (avatar != null) Demo.i.user['avatar'] = avatar;
          return AppUser.fromJson(Demo.i.user);
        },
      );

  // ------------------------------------------------------------ catalogue ---

  Future<List<AppBannerItem>> banners() => _guard(
        () async => _list(await _get('/banners')).map(AppBannerItem.fromJson).toList(),
        () => Demo.i.banners.map(AppBannerItem.fromJson).toList(),
      );

  Future<List<Product>> products(ProductCategory c) => _guard(
        () async => _list(await _get('/products', query: {'category': c.api}))
            .map(Product.fromJson)
            .toList(),
        () => Demo.i.products
            .where((p) => p['category'] == c.api && p['active'] != false)
            .map(Product.fromJson)
            .toList(),
      );

  Future<List<VipTier>> vipTiers() => _guard(
        () async => _list(await _get('/vip-levels')).map(VipTier.fromJson).toList(),
        () => Demo.i.vipTiers.map(VipTier.fromJson).toList(),
      );

  // ---------------------------------------------------------------- money ---

  Future<List<Order>> orders({String status = 'all'}) => _guard(
        () async => _list(await _get('/orders', query: {'status': status}))
            .map(Order.fromJson)
            .toList(),
        () => Demo.i.orders
            .where((o) => status == 'all' || o['status'] == status)
            .map(Order.fromJson)
            .toList(),
      );

  Future<String> buy(String productId, int shares) => _guard(
        () async {
          final r = await _post('/orders', {
            'productId': productId,
            'shares': shares,
          }) as Map;
          return '${r['message'] ?? 'Investment successful'}';
        },
        () => '${Demo.i.buy(productId, shares)['message']}',
      );

  Future<List<Txn>> transactions({String type = 'all'}) => _guard(
        () async => _list(await _get('/transactions', query: {'type': type}))
            .map(Txn.fromJson)
            .toList(),
        () => Demo.i.transactions
            .where((t) => type == 'all' || t['type'] == type)
            .map(Txn.fromJson)
            .toList(),
      );

  Future<String> recharge(double amount, String method) => _guard(
        () async {
          final r = await _post('/recharge', {
            'amount': amount,
            'method': method,
          }) as Map;
          return '${r['message'] ?? 'Recharge request submitted'}';
        },
        () => '${Demo.i.recharge(amount)['message']}',
      );

  Future<String> withdraw(double amount) => _guard(
        () async {
          final r = await _post('/withdraw', {'amount': amount}) as Map;
          return '${r['message'] ?? 'Withdrawal request submitted'}';
        },
        () => '${Demo.i.withdraw(amount)['message']}',
      );

  Future<BankCard?> bankCard() => _guard(
        () async {
          final r = await _get('/bank-card');
          if (r == null || (r is Map && r.isEmpty)) return null;
          return BankCard.fromJson(Map<String, dynamic>.from(r as Map));
        },
        () => Demo.i.bankCard == null ? null : BankCard.fromJson(Demo.i.bankCard!),
      );

  Future<void> saveBankCard(BankCard c) => _guard(
        () async {
          await _post('/bank-card', c.toJson());
        },
        () {
          Demo.i.bankCard = c.toJson();
        },
      );

  // ----------------------------------------------------------- engagement ---

  Future<TeamInfo> team() => _guard(
        () async => TeamInfo.fromJson(
            Map<String, dynamic>.from(await _get('/team') as Map)),
        () => TeamInfo.fromJson(Demo.i.team()),
      );

  Future<List<Notice>> notices() => _guard(
        () async => _list(await _get('/notices')).map(Notice.fromJson).toList(),
        () => Demo.i.notices.map(Notice.fromJson).toList(),
      );

  Future<List<BlogPost>> blogs() => _guard(
        () async => _list(await _get('/blogs')).map(BlogPost.fromJson).toList(),
        () => Demo.i.blogs.map(BlogPost.fromJson).toList(),
      );

  Future<String> postBlog(String content, List<String> photos) => _guard(
        () async {
          final r = await _post('/blogs', {
            'content': content,
            'photos': photos,
          }) as Map;
          return '${r['message'] ?? 'Submitted for review'}';
        },
        () => '${Demo.i.postBlog(content, photos)['message']}',
      );

  Future<List<TaskItem>> tasks() => _guard(
        () async => _list(await _get('/tasks')).map(TaskItem.fromJson).toList(),
        () => Demo.i.tasks.map(TaskItem.fromJson).toList(),
      );

  Future<double> claimTask(String id) => _guard(
        () async {
          final r = await _post('/tasks/$id/claim') as Map;
          return (r['reward'] as num?)?.toDouble() ?? 0;
        },
        () => (Demo.i.claimTask(id)['reward'] as num).toDouble(),
      );

  Future<double> checkIn() => _guard(
        () async {
          final r = await _post('/checkin') as Map;
          return (r['reward'] as num?)?.toDouble() ?? 0;
        },
        () => (Demo.i.checkIn()['reward'] as num).toDouble(),
      );

  Future<({List<LuckyPrize> prizes, List<LuckyWin> wins, int chances})> lucky() =>
      _guard(
        () async {
          final r = await _get('/lucky') as Map<String, dynamic>;
          return (
            prizes: _list(r['prizes']).map(LuckyPrize.fromJson).toList(),
            wins: _list(r['wins']).map(LuckyWin.fromJson).toList(),
            chances: (r['chances'] as num?)?.toInt() ?? 0,
          );
        },
        () => (
          prizes: Demo.i.luckyPrizes.map(LuckyPrize.fromJson).toList(),
          wins: Demo.i.luckyWins.map(LuckyWin.fromJson).toList(),
          chances: (Demo.i.user['drawChances'] as num).toInt(),
        ),
      );

  Future<({int slot, double amount})> spin() => _guard(
        () async {
          final r = await _post('/lucky/spin') as Map;
          return (
            slot: (r['slot'] as num).toInt(),
            amount: (r['amount'] as num).toDouble(),
          );
        },
        () {
          final r = Demo.i.spin();
          return (
            slot: (r['slot'] as num).toInt(),
            amount: (r['amount'] as num).toDouble(),
          );
        },
      );
}
