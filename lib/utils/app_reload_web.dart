// Solo se importa en web via conditional export.
// ignore_for_file: avoid_web_libraries_in_flutter

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
