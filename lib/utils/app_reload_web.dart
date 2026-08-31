import 'dart:html' as html;

void reloadApp({bool forceRefresh = false}) {
  if (forceRefresh) {
    final uri = Uri.parse(html.window.location.href);
    final next = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'v': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    html.window.location.href = next.toString();
    return;
  }
  html.window.location.reload();
}
