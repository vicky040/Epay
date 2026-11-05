double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

class AppUser {
  final String id;
  final String phone;
  final String nickname;
  final String? avatar;
  final String inviteCode;
  final int vipLevel;
  final double rechargeBalance;
  final double withdrawBalance;
  final double productIncome;
  final double totalInvested;
  final int drawChances;
  final bool checkedInToday;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatar,
    required this.inviteCode,
    required this.vipLevel,
    required this.rechargeBalance,
    required this.withdrawBalance,
    required this.productIncome,
    required this.totalInvested,
    required this.drawChances,
    required this.checkedInToday,
    this.createdAt,
  });

  double get totalBalance => rechargeBalance + withdrawBalance;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: '${j['id'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        nickname: '${j['nickname'] ?? 'User'}',
        avatar: j['avatar'] as String?,
        inviteCode: '${j['inviteCode'] ?? ''}',
        vipLevel: _i(j['vipLevel']),
        rechargeBalance: _d(j['rechargeBalance']),
        withdrawBalance: _d(j['withdrawBalance']),
        productIncome: _d(j['productIncome']),
        totalInvested: _d(j['totalInvested']),
        drawChances: _i(j['drawChances']),
        checkedInToday: j['checkedInToday'] == true,
        createdAt: _dt(j['createdAt']),
      );

  AppUser copyWith({String? nickname, String? avatar}) => AppUser(
        id: id,
        phone: phone,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        inviteCode: inviteCode,
        vipLevel: vipLevel,
        rechargeBalance: rechargeBalance,
        withdrawBalance: withdrawBalance,
        productIncome: productIncome,
        totalInvested: totalInvested,
        drawChances: drawChances,
        checkedInToday: checkedInToday,
        createdAt: createdAt,
      );
}

enum ProductCategory { steady, benefits, event }

ProductCategory categoryFrom(String? s) => switch (s) {
      'benefits' => ProductCategory.benefits,
      'event' => ProductCategory.event,
      _ => ProductCategory.steady,
    };

extension ProductCategoryX on ProductCategory {
  String get api => name;
  String get label => switch (this) {
        ProductCategory.steady => 'Steady',
        ProductCategory.benefits => 'Benefits',
        ProductCategory.event => 'Event',
      };
}

class Product {
  final String id;
  final String title;
  final String image;
  final ProductCategory category;
  final int vipRequired;
  final double price;
  final double periodEarning;
  final int duration;
  final String cycleUnit; // Days | Hours
  final double total;
  final int maxPerUser;
  final bool hot;
  final bool active;

  const Product({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.vipRequired,
    required this.price,
    required this.periodEarning,
    required this.duration,
    required this.cycleUnit,
    required this.total,
    required this.maxPerUser,
    required this.hot,
    required this.active,
  });

  bool get hourly => cycleUnit.toLowerCase().startsWith('hour');
  String get earningLabel => hourly ? 'Hourly Earnings' : 'Daily Earnings';
  String get durationLabel => '$duration $cycleUnit';

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        image: '${j['image'] ?? ''}',
        category: categoryFrom(j['category'] as String?),
        vipRequired: _i(j['vipRequired']),
        price: _d(j['price']),
        periodEarning: _d(j['periodEarning']),
        duration: _i(j['duration']),
        cycleUnit: '${j['cycleUnit'] ?? 'Days'}',
        total: _d(j['total']),
        maxPerUser: _i(j['maxPerUser']) == 0 ? 1 : _i(j['maxPerUser']),
        hot: j['hot'] == true,
        active: j['active'] != false,
      );
}

class Order {
  final String id;
  final String productTitle;
  final String productImage;
  final int shares;
  final double amount;
  final double earnedSoFar;
  final double expectedTotal;
  final String status; // active | finished
  final DateTime? createdAt;
  final DateTime? endsAt;

  const Order({
    required this.id,
    required this.productTitle,
    required this.productImage,
    required this.shares,
    required this.amount,
    required this.earnedSoFar,
    required this.expectedTotal,
    required this.status,
    this.createdAt,
    this.endsAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: '${j['id'] ?? ''}',
        productTitle: '${j['productTitle'] ?? j['title'] ?? ''}',
        productImage: '${j['productImage'] ?? j['image'] ?? ''}',
        shares: _i(j['shares']),
        amount: _d(j['amount']),
        earnedSoFar: _d(j['earnedSoFar']),
        expectedTotal: _d(j['expectedTotal']),
        status: '${j['status'] ?? 'active'}',
        createdAt: _dt(j['createdAt']),
        endsAt: _dt(j['endsAt']),
      );
}

class Txn {
  final String id;
  final String type; // recharge | withdraw | income | bonus | purchase | rebate
  final double amount;
  final String status; // pending | success | rejected
  final String? note;
  final DateTime? createdAt;

  const Txn({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.note,
    this.createdAt,
  });

  bool get credit => const {'recharge', 'income', 'bonus', 'rebate'}.contains(type);

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: '${j['id'] ?? ''}',
        type: '${j['type'] ?? ''}',
        amount: _d(j['amount']),
        status: '${j['status'] ?? 'success'}',
        note: j['note'] as String?,
        createdAt: _dt(j['createdAt']),
      );
}

class Notice {
  final String id;
  final String title;
  final String image;
  final String body;
  final DateTime? createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.image,
    required this.body,
    this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        image: '${j['image'] ?? ''}',
        body: '${j['body'] ?? ''}',
        createdAt: _dt(j['createdAt']),
      );
}

class BlogPost {
  final String id;
  final String authorPhone;
  final String content;
  final List<String> photos;
  final double reward;
  final DateTime? createdAt;

  const BlogPost({
    required this.id,
    required this.authorPhone,
    required this.content,
    required this.photos,
    required this.reward,
    this.createdAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
        id: '${j['id'] ?? ''}',
        authorPhone: '${j['authorPhone'] ?? ''}',
        content: '${j['content'] ?? ''}',
        photos: (j['photos'] as List?)?.map((e) => '$e').toList() ?? const [],
        reward: _d(j['reward']),
        createdAt: _dt(j['createdAt']),
      );
}

class VipTier {
  final int level;
  final double requiredAmount;
  final double dailyBonus;
  final String perks;

  const VipTier({
    required this.level,
    required this.requiredAmount,
    required this.dailyBonus,
    required this.perks,
  });

  factory VipTier.fromJson(Map<String, dynamic> j) => VipTier(
        level: _i(j['level']),
        requiredAmount: _d(j['requiredAmount'] ?? j['required']),
        dailyBonus: _d(j['dailyBonus']),
        perks: '${j['perks'] ?? ''}',
      );
}

class TeamLevel {
  final int level;
  final double rebatePercent;
  final int invited;
  final int active;
  final double earned;

  const TeamLevel({
    required this.level,
    required this.rebatePercent,
    required this.invited,
    required this.active,
    required this.earned,
  });

  factory TeamLevel.fromJson(Map<String, dynamic> j) => TeamLevel(
        level: _i(j['level']),
        rebatePercent: _d(j['rebatePercent']),
        invited: _i(j['invited']),
        active: _i(j['active']),
        earned: _d(j['earned']),
      );
}

class TeamInfo {
  final String inviteLink;
  final String inviteCode;
  final double activationReward;
  final List<TeamLevel> levels;

  const TeamInfo({
    required this.inviteLink,
    required this.inviteCode,
    required this.activationReward,
    required this.levels,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> j) => TeamInfo(
        inviteLink: '${j['inviteLink'] ?? ''}',
        inviteCode: '${j['inviteCode'] ?? ''}',
        activationReward: _d(j['activationReward']),
        levels: (j['levels'] as List? ?? const [])
            .map((e) => TeamLevel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final double reward;
  final int progress;
  final int target;
  final bool claimed;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.target,
    required this.claimed,
  });

  bool get completed => progress >= target;

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        description: '${j['description'] ?? ''}',
        reward: _d(j['reward']),
        progress: _i(j['progress']),
        target: _i(j['target']) == 0 ? 1 : _i(j['target']),
        claimed: j['claimed'] == true,
      );
}

class BankCard {
  final String holder;
  final String accountNumber;
  final String ifsc;
  final String bankName;
  final String? upi;

  const BankCard({
    required this.holder,
    required this.accountNumber,
    required this.ifsc,
    required this.bankName,
    this.upi,
  });

  factory BankCard.fromJson(Map<String, dynamic> j) => BankCard(
        holder: '${j['holder'] ?? ''}',
        accountNumber: '${j['accountNumber'] ?? ''}',
        ifsc: '${j['ifsc'] ?? ''}',
        bankName: '${j['bankName'] ?? ''}',
        upi: j['upi'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'holder': holder,
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        'bankName': bankName,
        'upi': upi,
      };
}

class LuckyPrize {
  final int slot;
  final double amount;
  const LuckyPrize({required this.slot, required this.amount});

  factory LuckyPrize.fromJson(Map<String, dynamic> j) =>
      LuckyPrize(slot: _i(j['slot']), amount: _d(j['amount']));
}

class LuckyWin {
  final String phone;
  final double amount;
  final DateTime? createdAt;
  const LuckyWin({required this.phone, required this.amount, this.createdAt});

  factory LuckyWin.fromJson(Map<String, dynamic> j) => LuckyWin(
        phone: '${j['phone'] ?? ''}',
        amount: _d(j['amount']),
        createdAt: _dt(j['createdAt']),
      );
}

class AppBannerItem {
  final String id;
  final String image;
  final String? link;
  const AppBannerItem({required this.id, required this.image, this.link});

  factory AppBannerItem.fromJson(Map<String, dynamic> j) => AppBannerItem(
        id: '${j['id'] ?? ''}',
        image: '${j['image'] ?? ''}',
        link: j['link'] as String?,
      );
}
