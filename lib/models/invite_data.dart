class InviteFetchData {
  final List<InviteCode> codes;
  final dynamic stat;

  InviteFetchData({
    this.codes = const [],
    this.stat,
  });

  factory InviteFetchData.fromJson(Map<String, dynamic> json) {
    var codesList = <InviteCode>[];
    if (json['codes'] is List) {
      codesList = (json['codes'] as List)
          .map((e) => InviteCode.fromJson(e))
          .toList();
    }
    return InviteFetchData(
      codes: codesList,
      stat: json['stat'],
    );
  }
}

class InviteCode {
  final int id;
  final String code;
  final int status; // 0: available, 1: used
  final int pv;
  final int createdAt;
  final int updatedAt;

  InviteCode({
    required this.id,
    required this.code,
    required this.status,
    required this.pv,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 0,
      pv: json['pv'] is int ? json['pv'] : int.tryParse(json['pv'].toString()) ?? 0,
      createdAt: json['created_at'] is int ? json['created_at'] : int.tryParse(json['created_at'].toString()) ?? 0,
      updatedAt: json['updated_at'] is int ? json['updated_at'] : int.tryParse(json['updated_at'].toString()) ?? 0,
    );
  }
}

class InviteDetail {
  final int id;
  final int userId;
  final int type;
  final String getAmount;
  final int status;
  final int createdAt;
  final int updatedAt;

  InviteDetail({
    required this.id,
    required this.userId,
    required this.type,
    required this.getAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InviteDetail.fromJson(Map<String, dynamic> json) {
    return InviteDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      type: json['type'] is int ? json['type'] : int.tryParse(json['type'].toString()) ?? 0,
      getAmount: json['get_amount']?.toString() ?? '0',
      status: json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 0,
      createdAt: json['created_at'] is int ? json['created_at'] : int.tryParse(json['created_at'].toString()) ?? 0,
      updatedAt: json['updated_at'] is int ? json['updated_at'] : int.tryParse(json['updated_at'].toString()) ?? 0,
    );
  }
}
