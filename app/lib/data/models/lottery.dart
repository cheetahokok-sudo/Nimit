/// Upcoming/latest draw info shown on the ตรวจหวย banner.
class DrawInfo {
  const DrawInfo({
    required this.drawDate,
    required this.isAnnounced,
    required this.statusTh,
  });

  final DateTime drawDate;
  final bool isAnnounced;
  final String statusTh; // e.g. "รอประกาศจากสำนักงานสลากกินแบ่งรัฐบาล"
}

/// A user-saved ticket number awaiting the draw.
class SavedTicket {
  const SavedTicket({required this.number, required this.savedAt});

  final String number;
  final DateTime savedAt;

  Map<String, dynamic> toJson() =>
      {'number': number, 'savedAt': savedAt.toIso8601String()};

  factory SavedTicket.fromJson(Map<String, dynamic> json) => SavedTicket(
        number: json['number'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

/// Responsible-use entertainment budget (งบความบันเทิง), in THB.
class BudgetState {
  const BudgetState({required this.spent, required this.limit});

  final int spent;
  final int limit;

  double get ratio => limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.0);

  BudgetState copyWith({int? spent, int? limit}) =>
      BudgetState(spent: spent ?? this.spent, limit: limit ?? this.limit);

  Map<String, dynamic> toJson() => {'spent': spent, 'limit': limit};

  factory BudgetState.fromJson(Map<String, dynamic> json) => BudgetState(
        spent: json['spent'] as int,
        limit: json['limit'] as int,
      );
}
