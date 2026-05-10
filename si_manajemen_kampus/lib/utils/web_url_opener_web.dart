import 'dart:html' as html;

bool openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
  return true;
}

bool downloadUrl(String url, {String? fileName}) {
  final anchor =
      html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = fileName ?? '';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
