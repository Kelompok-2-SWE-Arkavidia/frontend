class DashboardStats {
  final int totalItems;
  final int safeItems;
  final int warningItems;
  final int expiredItems;

  DashboardStats({
    required this.totalItems,
    required this.safeItems,
    required this.warningItems,
    required this.expiredItems,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalItems: json['total_items'] ?? 0,
      safeItems: json['safe_items'] ?? 0,
      warningItems: json['warning_items'] ?? 0,
      expiredItems: json['expired_items'] ?? 0,
    );
  }

  factory DashboardStats.empty() {
    return DashboardStats(
      totalItems: 0,
      safeItems: 0,
      warningItems: 0,
      expiredItems: 0,
    );
  }
}
