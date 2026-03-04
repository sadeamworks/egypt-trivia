import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'analytics_service.dart';

/// Service for sharing scores and achievements
class ShareService {
  final AnalyticsService? _analyticsService;

  ShareService({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService;

  /// Share text with optional subject
  Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    await Share.share(
      text,
      subject: subject,
    );
  }

  /// Share score as text
  Future<void> shareScore({
    required int score,
    required String category,
    required int correctAnswers,
    required int totalQuestions,
    int? streak,
    String platform = 'unknown',
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🏆 تريفيا مصر');
    buffer.writeln('');
    buffer.writeln('حققت $score نقطة في $category!');
    buffer.writeln('✅ $correctAnswers/$totalQuestions إجابات صحيحة');
    if (streak != null && streak > 0) {
      buffer.writeln('🔥 سلسلة: $streak');
    }
    buffer.writeln('');
    buffer.writeln('هل تستطيع التغلب علي؟');
    buffer.writeln('حمّل تريفيا مصر الآن!');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.egypttrivia.app');

    await shareText(
      text: buffer.toString(),
      subject: 'نتيجتي في تريفيا مصر',
    );

    // Track score shared
    _analyticsService?.logScoreShared(platform: platform, score: score);
  }

  /// Share achievement unlock
  Future<void> shareAchievement({
    required String achievementName,
    required String achievementDescription,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🏆 تريفيا مصر');
    buffer.writeln('');
    buffer.writeln('🎉 فتحت إنجاز جديد!');
    buffer.writeln('$achievementName: $achievementDescription');
    buffer.writeln('');
    buffer.writeln('حمّل تريفيا مصر وجاري معي!');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.egypttrivia.app');

    await shareText(
      text: buffer.toString(),
      subject: 'إنجاز جديد في تريفيا مصر',
    );
  }

  /// Share daily challenge result
  Future<void> shareDailyChallenge({
    required int score,
    required int streak,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🏆 تريفيا مصر - التحدي اليومي');
    buffer.writeln('');
    buffer.writeln('حققت $score نقطة اليوم!');
    if (streak > 0) {
      buffer.writeln('🔥 $streak أيام متتالية');
    }
    buffer.writeln('');
    buffer.writeln('هل تستطيع التغلب علي؟');
    buffer.writeln('حمّل تريفيا مصر الآن!');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.egypttrivia.app');

    await shareText(
      text: buffer.toString(),
      subject: 'نتيجتي في التحدي اليومي',
    );
  }

  /// Capture widget as image and share
  Future<void> shareWidgetAsImage({
    required GlobalKey key,
    required String text,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        await shareText(text: text);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        await shareText(text: text);
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_score.png');
      await file.writeAsBytes(buffer);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'نتيجتي في تريفيا مصر',
      );
    } catch (e) {
      // Fallback to text sharing
      await shareText(text: text);
    }
  }
}
