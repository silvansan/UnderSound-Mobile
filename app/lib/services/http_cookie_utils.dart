String? cookieHeaderFromResponse(Map<String, String> headers) {
  final values = <String>[];

  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() != 'set-cookie') {
      continue;
    }
    final pair = entry.value.split(';').first.trim();
    if (pair.isNotEmpty) {
      values.add(pair);
    }
  }

  if (values.isEmpty) {
    return null;
  }

  return values.join('; ');
}
