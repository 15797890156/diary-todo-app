/// 收支类型
enum TransactionType {
  income,  // 收入
  expense, // 支出
}

/// 收支分类
enum TransactionCategory {
  // ===== 支出分类 =====
  food,           // 餐饮 🍽️
  transport,      // 交通 🚗
  shopping,       // 购物 🛒
  housing,        // 住房 🏠
  entertainment,  // 娱乐 🎬
  medical,        // 医疗 💊
  education,      // 教育 📚
  clothing,       // 服饰 👔
  communication,  // 通讯 📱
  daily,          // 日用 🧴
  social,         // 社交 👥
  pet,            // 宠物 🐱
  gift,           // 礼物 🎁
  otherExpense,   // 其他支出 📌

  // ===== 收入分类 =====
  salary,         // 工资 💰
  bonus,          // 奖金 🎉
  investment,     // 投资 📈
  parttime,       // 兼职 💼
  freelance,      // 自由职业 💻
  refund,         // 退款 ↩️
  otherIncome,    // 其他收入 💵
}

/// 收支记录模型
class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;       // 收入/支出
  final TransactionCategory category; // 分类
  final double amount;               // 金额
  final String? note;                // 备注
  final String? icon;                // 自定义图标
  final DateTime date;               // 记录日期
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    this.note,
    this.icon,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      note: json['note'],
      icon: json['icon'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'note': note,
      'icon': icon,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? note,
    String? icon,
    DateTime? date,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      icon: icon ?? this.icon,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 格式化金额
  String get formattedAmount {
    final prefix = type == TransactionType.income ? '+' : '-';
    return '$prefix¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化金额（无符号）
  String get formattedAmountPlain {
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 获取分类图标
  String get categoryIcon {
    if (icon != null) return icon!;
    switch (category) {
      case TransactionCategory.food: return '🍽️';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.shopping: return '🛒';
      case TransactionCategory.housing: return '🏠';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.medical: return '💊';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.clothing: return '👔';
      case TransactionCategory.communication: return '📱';
      case TransactionCategory.daily: return '🧴';
      case TransactionCategory.social: return '👥';
      case TransactionCategory.pet: return '🐱';
      case TransactionCategory.gift: return '🎁';
      case TransactionCategory.otherExpense: return '📌';
      case TransactionCategory.salary: return '💰';
      case TransactionCategory.bonus: return '🎉';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.parttime: return '💼';
      case TransactionCategory.freelance: return '💻';
      case TransactionCategory.refund: return '↩️';
      case TransactionCategory.otherIncome: return '💵';
    }
  }

  /// 获取分类名称
  String get categoryName {
    switch (category) {
      case TransactionCategory.food: return '餐饮';
      case TransactionCategory.transport: return '交通';
      case TransactionCategory.shopping: return '购物';
      case TransactionCategory.housing: return '住房';
      case TransactionCategory.entertainment: return '娱乐';
      case TransactionCategory.medical: return '医疗';
      case TransactionCategory.education: return '教育';
      case TransactionCategory.clothing: return '服饰';
      case TransactionCategory.communication: return '通讯';
      case TransactionCategory.daily: return '日用';
      case TransactionCategory.social: return '社交';
      case TransactionCategory.pet: return '宠物';
      case TransactionCategory.gift: return '礼物';
      case TransactionCategory.otherExpense: return '其他支出';
      case TransactionCategory.salary: return '工资';
      case TransactionCategory.bonus: return '奖金';
      case TransactionCategory.investment: return '投资';
      case TransactionCategory.parttime: return '兼职';
      case TransactionCategory.freelance: return '自由职业';
      case TransactionCategory.refund: return '退款';
      case TransactionCategory.otherIncome: return '其他收入';
    }
  }

  /// 是否是支出
  bool get isExpense => type == TransactionType.expense;

  /// 是否是收入
  bool get isIncome => type == TransactionType.income;

  /// 获取支出分类列表
  static List<TransactionCategory> get expenseCategories => [
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.shopping,
    TransactionCategory.housing,
    TransactionCategory.entertainment,
    TransactionCategory.medical,
    TransactionCategory.education,
    TransactionCategory.clothing,
    TransactionCategory.communication,
    TransactionCategory.daily,
    TransactionCategory.social,
    TransactionCategory.pet,
    TransactionCategory.gift,
    TransactionCategory.otherExpense,
  ];

  /// 获取收入分类列表
  static List<TransactionCategory> get incomeCategories => [
    TransactionCategory.salary,
    TransactionCategory.bonus,
    TransactionCategory.investment,
    TransactionCategory.parttime,
    TransactionCategory.freelance,
    TransactionCategory.refund,
    TransactionCategory.otherIncome,
  ];
}

/// 月度收支汇总
class MonthlyTransactionSummary {
  final int year;
  final int month;
  final double totalIncome;    // 总收入
  final double totalExpense;   // 总支出
  final double balance;        // 结余
  final Map<TransactionCategory, double> expenseByCategory; // 支出分类汇总
  final Map<TransactionCategory, double> incomeByCategory;   // 收入分类汇总
  final List<TransactionModel> transactions; // 所有记录

  MonthlyTransactionSummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.transactions,
  });

  /// 格式化收入
  String get formattedIncome => '¥${totalIncome.toStringAsFixed(2)}';

  /// 格式化支出
  String get formattedExpense => '¥${totalExpense.toStringAsFixed(2)}';

  /// 格式化结余
  String get formattedBalance {
    final prefix = balance >= 0 ? '+' : '';
    return '$prefix¥${balance.toStringAsFixed(2)}';
  }

  /// 日均支出
  double get dailyAvgExpense {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return daysInMonth > 0 ? totalExpense / daysInMonth : 0;
  }

  /// 支出分类排行（从高到低）
  List<MapEntry<TransactionCategory, double>> get expenseRanking {
    final sorted = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }
}

/// 日度收支汇总
class DailyTransactionSummary {
  final DateTime date;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<TransactionModel> transactions;

  DailyTransactionSummary({
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactions,
  });
}
