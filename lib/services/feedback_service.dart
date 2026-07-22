import 'package:url_launcher/url_launcher.dart';

/// §14 Feedback channel. Opens the user's own mail app via a `mailto:` intent
/// pre-addressed to the maker. **Nothing is sent automatically** — no
/// analytics, crash-reporting, or telemetry (§14, §1.1). If the user reports
/// nothing, Realmaya receives nothing.
class FeedbackService {
  const FeedbackService();

  static const makerEmail = 'veera@realmaya.com';

  /// Builds and launches the pre-filled feedback email. [appVersion] and
  /// [platformVersion] are woven into an optional template the user can edit or
  /// delete in their mail app before sending.
  Future<bool> sendFeedback({
    required String appVersion,
    required String platformVersion,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: makerEmail,
      query: _encodeQuery({
        'subject': 'Saara feedback',
        'body':
            'Hi Veera,\n\n'
            '(Your feedback here)\n\n'
            '---\n'
            'App version: $appVersion\n'
            'Platform: $platformVersion\n',
      }),
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');
}
