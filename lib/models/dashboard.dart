import 'badge.dart';
import 'checkin.dart';

class DashboardData {
  final int totalCheckins;
  final double? promedioEmocional;
  final int totalCvReviews;
  final int totalInterviewSessions;
  final List<AppBadge> badges;
  final List<CheckinResult> ultimosCheckins;

  DashboardData({
    required this.totalCheckins,
    required this.promedioEmocional,
    required this.totalCvReviews,
    required this.totalInterviewSessions,
    required this.badges,
    required this.ultimosCheckins,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalCheckins: json['total_checkins'] as int,
      promedioEmocional: (json['promedio_emocional'] as num?)?.toDouble(),
      totalCvReviews: json['total_cv_reviews'] as int,
      totalInterviewSessions: json['total_interview_sessions'] as int,
      badges: (json['badges'] as List).map((b) => AppBadge.fromJson(b as Map<String, dynamic>)).toList(),
      ultimosCheckins:
          (json['ultimos_checkins'] as List).map((c) => CheckinResult.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}
