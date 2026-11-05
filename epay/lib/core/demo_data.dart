import 'dart:math';

/// Offline demo dataset. Used when the backend is unreachable so that every
/// screen in the app remains explorable without a running server.
class Demo {
  Demo._();
  static final Demo i = Demo._();

  final _rnd = Random();

  Map<String, dynamic> user = {
    'id': 'demo-user',
    'phone': '8769293125',
    'nickname': 'Nic',
    'inviteCode': '82777',
    'vipLevel': 0,
    'rechargeBalance': 0.0,
    'withdrawBalance': 0.0,
    'productIncome': 0.0,
    'totalInvested': 0.0,
    'drawChances': 0,
    'checkedInToday': false,
    'createdAt': DateTime.now().toIso8601String(),
  };

  final List<Map<String, dynamic>> transactions = [];
  final List<Map<String, dynamic>> orders = [];

  static const _img =
      'https://images.unsplash.com/photo-1565514020179-026b92b84bb6?w=900&q=70';
  static const _img2 =
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&q=70';
  static const _img3 =
      'https://images.unsplash.com/photo-1494412574643-ff11b0a5c1c3?w=900&q=70';
  static const _img4 =
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=900&q=70';

  List<Map<String, dynamic>> banners = [
    {'id': 'b1', 'image': _img2, 'link': null},
    {'id': 'b2', 'image': _img3, 'link': null},
  ];

  List<Map<String, dynamic>> products = [
    {
      'id': 'p1', 'title': 'Upgrade VIP1', 'image': _img2, 'category': 'steady',
      'vipRequired': 0, 'price': 280.0, 'periodEarning': 240.8, 'duration': 47,
      'cycleUnit': 'Days', 'total': 11317.6, 'maxPerUser': 1, 'hot': false, 'active': true,
    },
    {
      'id': 'p2', 'title': 'Upgrade VIP2', 'image': _img4, 'category': 'steady',
      'vipRequired': 0, 'price': 4800.0, 'periodEarning': 4176.0, 'duration': 47,
      'cycleUnit': 'Days', 'total': 196272.0, 'maxPerUser': 1, 'hot': false, 'active': true,
    },
    {
      'id': 'p3', 'title': 'Upgrade VIP3', 'image': _img3, 'category': 'steady',
      'vipRequired': 0, 'price': 9800.0, 'periodEarning': 8526.0, 'duration': 47,
      'cycleUnit': 'Days', 'total': 400722.0, 'maxPerUser': 1, 'hot': false, 'active': true,
    },
    {
      'id': 'p4', 'title': 'EPay Turbo B-X', 'image': _img, 'category': 'benefits',
      'vipRequired': 1, 'price': 1599.0, 'periodEarning': 3731.0, 'duration': 1,
      'cycleUnit': 'Hours', 'total': 3725.03, 'maxPerUser': 3, 'hot': true, 'active': true,
    },
    {
      'id': 'p5', 'title': 'EPay Turbo B-X Pro', 'image': _img, 'category': 'benefits',
      'vipRequired': 1, 'price': 3399.0, 'periodEarning': 9347.25, 'duration': 1,
      'cycleUnit': 'Hours', 'total': 9332.29, 'maxPerUser': 3, 'hot': true, 'active': true,
    },
    {
      'id': 'p6', 'title': 'EPay Turbo Max', 'image': _img4, 'category': 'benefits',
      'vipRequired': 2, 'price': 7999.0, 'periodEarning': 21877.0, 'duration': 1,
      'cycleUnit': 'Hours', 'total': 21860.0, 'maxPerUser': 2, 'hot': false, 'active': true,
    },
    {
      'id': 'p7', 'title': 'Festival Boost', 'image': _img, 'category': 'event',
      'vipRequired': 1, 'price': 499.0, 'periodEarning': 673.65, 'duration': 23,
      'cycleUnit': 'Days', 'total': 15493.95, 'maxPerUser': 5, 'hot': true, 'active': true,
    },
    {
      'id': 'p8', 'title': 'Festival Boost Plus', 'image': _img2, 'category': 'event',
      'vipRequired': 1, 'price': 1399.0, 'periodEarning': 2308.35, 'duration': 23,
      'cycleUnit': 'Days', 'total': 53092.05, 'maxPerUser': 5, 'hot': false, 'active': true,
    },
    {
      'id': 'p9', 'title': 'Festival Boost Elite', 'image': _img3, 'category': 'event',
      'vipRequired': 2, 'price': 2999.0, 'periodEarning': 4948.35, 'duration': 23,
      'cycleUnit': 'Days', 'total': 113812.05, 'maxPerUser': 5, 'hot': false, 'active': true,
    },
  ];

  List<Map<String, dynamic>> vipTiers = [
    {'level': 0, 'requiredAmount': 0.0, 'dailyBonus': 0.0, 'perks': 'Browse products and daily blog rewards'},
    {'level': 1, 'requiredAmount': 280.0, 'dailyBonus': 6.0, 'perks': 'Unlock Benefits products, 60% L1 rebate'},
    {'level': 2, 'requiredAmount': 4800.0, 'dailyBonus': 16.0, 'perks': 'Higher daily cap and faster withdrawals'},
    {'level': 3, 'requiredAmount': 9800.0, 'dailyBonus': 36.0, 'perks': 'Priority support channel'},
    {'level': 4, 'requiredAmount': 28000.0, 'dailyBonus': 166.0, 'perks': 'Exclusive event products'},
    {'level': 5, 'requiredAmount': 68000.0, 'dailyBonus': 366.0, 'perks': 'Dedicated account manager'},
    {'level': 6, 'requiredAmount': 150000.0, 'dailyBonus': 666.0, 'perks': 'Zero withdrawal fee'},
    {'level': 7, 'requiredAmount': 300000.0, 'dailyBonus': 766.0, 'perks': 'Top-tier partner benefits'},
  ];

  List<Map<String, dynamic>> notices = [
    {
      'id': 'n1',
      'title': 'Cumulative Rewards',
      'image': '',
      'createdAt': '2026-10-08T07:26:02Z',
      'body': '1: Cumulative top-up of 15,000: Reward of 1,000\n\n'
          '2: Cumulative top-up of 30,000: Reward of 3,000\n\n'
          '3: Cumulative top-up of 50,000: Reward of 6,000\n\n'
          'A: Total top-up of 30,000: Bonus awarded: 1,000 + 3,000\n\n'
          'B: Total top-up of 50,000: Bonus awarded: 1,000 + 3,000 + 6,000\n\n'
          'C: Once the conditions are met, the corresponding rewards will be '
          'automatically distributed; no manual claim is required.',
    },
    {
      'id': 'n2',
      'title': 'Referral Rewards',
      'image': '',
      'createdAt': '2026-10-08T07:25:32Z',
      'body': '1: Activate 10 Level 1 members to earn ₹1,000\n'
          '2: Activate 20 Level 1 members to earn ₹3,000\n'
          '3: Activate 50 Level 1 members to earn ₹10,000\n'
          '4: Activate 150 Level 1 members to earn ₹40,000\n'
          '5: Activate 500 Level 1 members to earn ₹150,000\n'
          '6: Blogs that charge fees are not eligible for this reward!\n'
          '7: Complete the corresponding task and contact customer service to claim your reward',
    },
    {
      'id': 'n3',
      'title': 'Daily Bonuses',
      'image': '',
      'createdAt': '2026-10-08T07:25:04Z',
      'body': 'VIP1: Earn ₹6 for checking in every day\n\n'
          'VIP2: Earn ₹16 for checking in every day\n\n'
          'VIP3: Earn ₹36 for checking in every day\n\n'
          'VIP4: Earn ₹166 for checking in every day\n\n'
          'VIP5: Earn ₹366 for checking in every day\n\n'
          'VIP6: Earn ₹666 for checking in every day\n\n'
          'VIP7: Earn ₹766 for checking in every day',
    },
    {
      'id': 'n4',
      'title': 'Lucky Draw',
      'image': '',
      'createdAt': '2026-10-08T07:24:34Z',
      'body': '1: Purchase any item — for every 2 items bought, receive 2 chances '
          'to enter the draw, with no upper limit!\n\n'
          '2: Invite friends to join — for every 2 people invited, receive 2 '
          'chances to enter the draw, with no upper limit!',
    },
    {
      'id': 'n5',
      'title': 'Official Channel',
      'image': '',
      'createdAt': '2026-10-08T07:23:36Z',
      'body': 'Join the official EPay Telegram channel for the latest news, '
          'events and benefits. Beware of impostors — we never ask for your '
          'password or OTP.',
    },
  ];

  List<Map<String, dynamic>> blogs = [
    {
      'id': 'bl1',
      'authorPhone': '8169293396',
      'content': 'Very fast withdrawal and very nice app, this is trustworthy.',
      'photos': [],
      'reward': 22.0,
      'createdAt': '2026-11-02T09:15:21Z',
    },
    {
      'id': 'bl2',
      'authorPhone': '9122114477',
      'content': 'Received my payout in 9 minutes. Thanks EPay team!',
      'photos': [],
      'reward': 18.0,
      'createdAt': '2026-11-01T09:18:48Z',
    },
    {
      'id': 'bl3',
      'authorPhone': '7788991122',
      'content': 'Third withdrawal completed today. Steady products are working well for me.',
      'photos': [],
      'reward': 15.0,
      'createdAt': '2026-10-31T11:02:10Z',
    },
  ];

  List<Map<String, dynamic>> tasks = [
    {
      'id': 't1', 'title': 'Complete your first recharge',
      'description': 'Top up any amount to unlock withdrawals.',
      'reward': 50.0, 'progress': 0, 'target': 1, 'claimed': false,
    },
    {
      'id': 't2', 'title': 'Buy your first product',
      'description': 'Start earning daily returns.',
      'reward': 80.0, 'progress': 0, 'target': 1, 'claimed': false,
    },
    {
      'id': 't3', 'title': 'Invite 3 friends',
      'description': 'Earn ₹100 for every activated member.',
      'reward': 300.0, 'progress': 0, 'target': 3, 'claimed': false,
    },
    {
      'id': 't4', 'title': 'Check in for 7 days',
      'description': 'Keep your streak alive for a bonus.',
      'reward': 120.0, 'progress': 0, 'target': 7, 'claimed': false,
    },
    {
      'id': 't5', 'title': 'Publish a blog post',
      'description': 'Share your withdrawal proof with the community.',
      'reward': 22.0, 'progress': 0, 'target': 1, 'claimed': false,
    },
  ];

  List<Map<String, dynamic>> luckyPrizes = [
    {'slot': 1, 'amount': 99988.0},
    {'slot': 2, 'amount': 48888.0},
    {'slot': 3, 'amount': 3888.0},
    {'slot': 4, 'amount': 988.0},
    {'slot': 5, 'amount': 288.0},
    {'slot': 6, 'amount': 28.0},
    {'slot': 7, 'amount': 18.0},
    {'slot': 8, 'amount': 8.0},
  ];

  List<Map<String, dynamic>> luckyWins = [
    {'phone': '98xxxx3331', 'amount': 18.0, 'createdAt': null},
    {'phone': '80xxxx5367', 'amount': 18.0, 'createdAt': null},
    {'phone': '91xxxx5514', 'amount': 8.0, 'createdAt': null},
  ];

  Map<String, dynamic> team() => {
        'inviteLink': 'https://epay.app/?invitation_code=${user['inviteCode']}',
        'inviteCode': user['inviteCode'],
        'activationReward': 100.0,
        'levels': [
          {'level': 1, 'rebatePercent': 60.0, 'invited': 0, 'active': 0, 'earned': 0.0},
          {'level': 2, 'rebatePercent': 4.0, 'invited': 0, 'active': 0, 'earned': 0.0},
          {'level': 3, 'rebatePercent': 1.0, 'invited': 0, 'active': 0, 'earned': 0.0},
        ],
      };

  Map<String, dynamic>? bankCard;

  // ---- mutations -----------------------------------------------------------

  String _id() => '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(99)}';

  void addTxn(String type, double amount, {String status = 'success', String? note}) {
    transactions.insert(0, {
      'id': _id(),
      'type': type,
      'amount': amount,
      'status': status,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> recharge(double amount) {
    addTxn('recharge', amount, status: 'pending', note: 'Awaiting confirmation');
    return {'ok': true, 'message': 'Recharge request submitted'};
  }

  Map<String, dynamic> withdraw(double amount) {
    final bal = (user['withdrawBalance'] as num).toDouble();
    if (amount > bal) {
      throw Exception('Insufficient withdrawable balance');
    }
    user['withdrawBalance'] = bal - amount;
    addTxn('withdraw', amount, status: 'pending', note: 'Processing');
    return {'ok': true, 'message': 'Withdrawal request submitted'};
  }

  Map<String, dynamic> buy(String productId, int shares) {
    final p = products.firstWhere((e) => e['id'] == productId);
    final cost = (p['price'] as num).toDouble() * shares;
    final bal = (user['rechargeBalance'] as num).toDouble();
    if (cost > bal) throw Exception('Insufficient balance. Please recharge first.');

    final days = p['cycleUnit'] == 'Hours' ? 0 : (p['duration'] as num).toInt();
    final hours = p['cycleUnit'] == 'Hours' ? (p['duration'] as num).toInt() : 0;

    user['rechargeBalance'] = bal - cost;
    user['totalInvested'] = (user['totalInvested'] as num).toDouble() + cost;
    user['drawChances'] = (user['drawChances'] as num).toInt() + shares;

    // bump VIP level if the new total crosses a tier
    final invested = (user['totalInvested'] as num).toDouble();
    var lvl = 0;
    for (final t in vipTiers) {
      if (invested >= (t['requiredAmount'] as num).toDouble()) {
        lvl = (t['level'] as num).toInt();
      }
    }
    user['vipLevel'] = lvl;

    orders.insert(0, {
      'id': _id(),
      'productTitle': p['title'],
      'productImage': p['image'],
      'shares': shares,
      'amount': cost,
      'earnedSoFar': 0.0,
      'expectedTotal': (p['total'] as num).toDouble() * shares,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
      'endsAt': DateTime.now()
          .add(Duration(days: days, hours: hours))
          .toIso8601String(),
    });
    addTxn('purchase', cost, note: '${p['title']} x$shares');

    final t = tasks.firstWhere((e) => e['id'] == 't2');
    t['progress'] = 1;
    return {'ok': true, 'message': 'Investment successful'};
  }

  Map<String, dynamic> checkIn() {
    if (user['checkedInToday'] == true) {
      throw Exception('You have already checked in today');
    }
    final lvl = (user['vipLevel'] as num).toInt();
    final tier = vipTiers.firstWhere((t) => t['level'] == lvl,
        orElse: () => vipTiers.first);
    final bonus = (tier['dailyBonus'] as num).toDouble();
    user['checkedInToday'] = true;
    user['withdrawBalance'] = (user['withdrawBalance'] as num).toDouble() + bonus;
    if (bonus > 0) addTxn('bonus', bonus, note: 'Daily check-in');
    final t = tasks.firstWhere((e) => e['id'] == 't4');
    t['progress'] = ((t['progress'] as num).toInt() + 1).clamp(0, 7);
    return {'ok': true, 'reward': bonus};
  }

  Map<String, dynamic> spin() {
    final chances = (user['drawChances'] as num).toInt();
    if (chances <= 0) throw Exception('No draws remaining');
    user['drawChances'] = chances - 1;
    // weighted toward the smaller prizes
    final weights = [1, 2, 5, 12, 25, 60, 120, 200];
    final total = weights.reduce((a, b) => a + b);
    var r = _rnd.nextInt(total);
    var idx = 0;
    for (var i = 0; i < weights.length; i++) {
      if (r < weights[i]) {
        idx = i;
        break;
      }
      r -= weights[i];
    }
    final prize = luckyPrizes[idx];
    final amount = (prize['amount'] as num).toDouble();
    user['withdrawBalance'] = (user['withdrawBalance'] as num).toDouble() + amount;
    addTxn('bonus', amount, note: 'Lucky wheel');
    luckyWins.insert(0, {
      'phone': _mask('${user['phone']}'),
      'amount': amount,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return {'ok': true, 'slot': prize['slot'], 'amount': amount};
  }

  String _mask(String p) =>
      p.length < 6 ? p : '${p.substring(0, 2)}xxxx${p.substring(p.length - 4)}';

  Map<String, dynamic> postBlog(String content, List<String> photos) {
    blogs.insert(0, {
      'id': _id(),
      'authorPhone': _mask('${user['phone']}'),
      'content': content,
      'photos': photos,
      'reward': 0.0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    final t = tasks.firstWhere((e) => e['id'] == 't5');
    t['progress'] = 1;
    return {'ok': true, 'message': 'Submitted for review'};
  }

  Map<String, dynamic> claimTask(String id) {
    final t = tasks.firstWhere((e) => e['id'] == id);
    if ((t['progress'] as num).toInt() < (t['target'] as num).toInt()) {
      throw Exception('Task not completed yet');
    }
    if (t['claimed'] == true) throw Exception('Already claimed');
    t['claimed'] = true;
    final r = (t['reward'] as num).toDouble();
    user['withdrawBalance'] = (user['withdrawBalance'] as num).toDouble() + r;
    addTxn('bonus', r, note: t['title'] as String);
    return {'ok': true, 'reward': r};
  }

  void reset() {
    user = {
      'id': 'demo-user',
      'phone': '8769293125',
      'nickname': 'Nic',
      'inviteCode': '82777',
      'vipLevel': 0,
      'rechargeBalance': 0.0,
      'withdrawBalance': 0.0,
      'productIncome': 0.0,
      'totalInvested': 0.0,
      'drawChances': 0,
      'checkedInToday': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    transactions.clear();
    orders.clear();
    bankCard = null;
    for (final t in tasks) {
      t['progress'] = 0;
      t['claimed'] = false;
    }
  }
}
