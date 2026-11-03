class CheckinHistoryItem {
  final String checkinId;
  final String poiName;
  final String poemTitle;
  final DateTime checkinTime;
  final double lat;
  final double lon;
  final String? cardUrl;

  CheckinHistoryItem({
    required this.checkinId,
    required this.poiName,
    required this.poemTitle,
    required this.checkinTime,
    required this.lat,
    required this.lon,
    this.cardUrl,
  });

  factory CheckinHistoryItem.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    return CheckinHistoryItem(
      checkinId: (json['checkin_id'] ?? '').toString(),
      poiName: json['poi_name']?.toString() ?? '',
      poemTitle: json['poem_title']?.toString() ?? '',
      checkinTime: DateTime.tryParse(json['checkin_time']?.toString() ?? '') ?? DateTime.now(),
      lat: (location['lat'] as num?)?.toDouble() ?? 0,
      lon: (location['lon'] as num?)?.toDouble() ?? 0,
      cardUrl: json['card_url']?.toString(),
    );
  }
}

class CheckinHistoryResponse {
  final List<CheckinHistoryItem> checkins;
  final int total;
  final int totalPois;
  final int totalCities;

  CheckinHistoryResponse({
    required this.checkins,
    required this.total,
    required this.totalPois,
    required this.totalCities,
  });
}

class CheckinSubmitResult {
  final String checkinId;
  final String poiName;
  final String poemTitle;
  final DateTime checkinTime;
  final String? cardUrl;

  CheckinSubmitResult({
    required this.checkinId,
    required this.poiName,
    required this.poemTitle,
    required this.checkinTime,
    this.cardUrl,
  });
}
