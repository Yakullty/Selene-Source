import '../models/epg_program.dart';
import '../models/live_channel.dart';

enum CatchupMode {
  disabled,
  defaultMode,
  append,
  shift,
  flussonic,
  xtreamCodes,
}

class CatchupUrlBuilder {
  static bool supportsCatchup(LiveChannel channel) {
    final template = resolveTemplate(channel);
    return template != null && template.isNotEmpty;
  }

  static String? build(LiveChannel channel, EpgProgram program) {
    final template = resolveTemplate(channel);
    if (template == null || template.isEmpty) {
      return null;
    }
    return formatTemplate(template, program);
  }

  static CatchupMode parseMode(String catchup) {
    final value = catchup.trim().toLowerCase();
    switch (value) {
      case 'default':
      case 'vod':
        return CatchupMode.defaultMode;
      case 'append':
        return CatchupMode.append;
      case 'shift':
      case 'timeshift':
        return CatchupMode.shift;
      case 'flussonic':
      case 'fs':
      case 'flussonic-ts':
      case 'flussonic-hls':
        return CatchupMode.flussonic;
      case 'xc':
      case 'xtream':
      case 'xtream codes':
        return CatchupMode.xtreamCodes;
      case '':
      case 'disabled':
        return CatchupMode.disabled;
      default:
        return CatchupMode.defaultMode;
    }
  }

  static String? resolveTemplate(LiveChannel channel) {
    var mode = parseMode(channel.catchup);

    if (mode == CatchupMode.disabled && channel.catchupSource.isNotEmpty) {
      mode = CatchupMode.defaultMode;
    }

    switch (mode) {
      case CatchupMode.disabled:
        return null;
      case CatchupMode.defaultMode:
        if (channel.catchupSource.isNotEmpty) {
          return channel.catchupSource;
        }
        return null;
      case CatchupMode.append:
        if (channel.catchupSource.isEmpty) {
          return null;
        }
        return channel.url + channel.catchupSource;
      case CatchupMode.shift:
        return _generateShiftTemplate(channel.url);
      case CatchupMode.flussonic:
        return _generateFlussonicTemplate(channel.url) ??
            _nonEmptyOrNull(channel.catchupSource);
      case CatchupMode.xtreamCodes:
        return _generateXtreamTemplate(channel.url) ??
            _nonEmptyOrNull(channel.catchupSource);
    }
  }

  static String? _nonEmptyOrNull(String value) {
    return value.isEmpty ? null : value;
  }

  static String _generateShiftTemplate(String url) {
    if (url.contains('?')) {
      return '$url&utc={utc}&lutc={lutc}';
    }
    return '$url?utc={utc}&lutc={lutc}';
  }

  static String? _generateFlussonicTemplate(String url) {
    final fsRegex = RegExp(
      r'^(https?://[^/]+)/(.*)/([^/]*)(mpegts|\.m3u8)(\?.+=.+)?$',
    );
    final match = fsRegex.firstMatch(url);
    if (match != null) {
      final host = match.group(1)!;
      final channelId = match.group(2)!;
      final listType = match.group(3)!;
      final streamType = match.group(4)!;
      final urlAppend = match.group(5) ?? '';

      if (streamType == 'mpegts') {
        return '$host/$channelId/timeshift_abs-\${start}.ts$urlAppend';
      }
      if (listType == 'index') {
        return '$host/$channelId/timeshift_rel-{offset:1}.m3u8$urlAppend';
      }
      return '$host/$channelId/$listType-timeshift_rel-{offset:1}.m3u8$urlAppend';
    }

    final genericRegex = RegExp(r'^(https?://[^/]+)/(.*)/([^\?]*)(\?.+=.+)?$');
    final genericMatch = genericRegex.firstMatch(url);
    if (genericMatch != null) {
      final host = genericMatch.group(1)!;
      final channelId = genericMatch.group(2)!;
      final streamPath = genericMatch.group(3)!;
      final urlAppend = genericMatch.group(4) ?? '';
      if (streamPath.endsWith('.ts') || streamPath.contains('mpegts')) {
        return '$host/$channelId/timeshift_abs-\${start}.ts$urlAppend';
      }
      return '$host/$channelId/timeshift_rel-{offset:1}.m3u8$urlAppend';
    }

    return null;
  }

  static String? _generateXtreamTemplate(String url) {
    final xcRegex = RegExp(
      r'^(https?://[^/]+)/(?:live/)?([^/]+)/([^/]+)/([^/\.\?]+)(\.m3u8?)?$',
    );
    final match = xcRegex.firstMatch(url);
    if (match == null) {
      return null;
    }

    final host = match.group(1)!;
    final username = match.group(2)!;
    final password = match.group(3)!;
    final channelId = match.group(4)!;
    var extension = match.group(5) ?? '';
    if (extension.isEmpty) {
      extension = '.ts';
    }

    return '$host/timeshift/$username/$password/{duration:60}/{Y}-{m}-{d}:{H}-{M}/$channelId$extension';
  }

  static String formatTemplate(String template, EpgProgram program) {
    final startSeconds = program.startTime.millisecondsSinceEpoch ~/ 1000;
    final endSeconds = program.endTime.millisecondsSinceEpoch ~/ 1000;
    final durationSeconds = endSeconds - startSeconds;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final offsetSeconds = nowSeconds - startSeconds;

    var result = template;

    result = _replaceUnits(result, 'duration', durationSeconds);
    result = _replaceUnits(result, 'offset', offsetSeconds);

    result = _replaceDateComponents(result, program.startTime);
    result = _replaceFormattedTime(result, 'utc', program.startTime);
    result = _replaceFormattedTime(result, 'start', program.startTime);
    result = _replaceFormattedTime(result, 'utcend', program.endTime);
    result = _replaceFormattedTime(result, 'end', program.endTime);
    result = _replaceFormattedTime(result, 'lutc', DateTime.now());
    result = _replaceFormattedTime(result, 'now', DateTime.now());
    result = _replaceFormattedTime(result, 'timestamp', DateTime.now());

    final replacements = <String, String>{
      r'${start}': startSeconds.toString(),
      r'${begin}': startSeconds.toString(),
      r'{utc}': startSeconds.toString(),
      r'${end}': endSeconds.toString(),
      r'{utcend}': endSeconds.toString(),
      r'${timestamp}': nowSeconds.toString(),
      r'${now}': nowSeconds.toString(),
      r'{lutc}': nowSeconds.toString(),
      r'${duration}': durationSeconds.toString(),
      r'{duration}': durationSeconds.toString(),
      r'${offset}': offsetSeconds.toString(),
      r'{offset}': offsetSeconds.toString(),
      r'${YmdHMS}': _formatYmdHms(program.startTime, utc: false),
      r'${utc}': _formatYmdHms(program.startTime, utc: true),
    };

    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  static String _replaceUnits(String input, String name, int seconds) {
    var result = input;
    final plain = RegExp('\\{$name\\}|\\\${$name}');
    result = result.replaceAll(plain, seconds.toString());

    final divided = RegExp('\\{$name:(\\d+)\\}|\\\${$name:(\\d+)\\}');
    result = result.replaceAllMapped(divided, (match) {
      final divider = int.tryParse(match.group(1) ?? match.group(2) ?? '1') ?? 1;
      if (divider <= 0) {
        return seconds.toString();
      }
      final units = seconds ~/ divider;
      return units < 0 ? '0' : units.toString();
    });
    return result;
  }

  static String _replaceDateComponents(String input, DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    final replacements = {
      '{Y}': dateTime.year.toString(),
      '{m}': two(dateTime.month),
      '{d}': two(dateTime.day),
      '{H}': two(dateTime.hour),
      '{M}': two(dateTime.minute),
      '{S}': two(dateTime.second),
    };

    var result = input;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static String _replaceFormattedTime(
    String input,
    String name,
    DateTime dateTime,
  ) {
    final pattern = RegExp('\\{$name:([^}]+)\\}|\\\${$name:([^}]+)\\}');
    return input.replaceAllMapped(pattern, (match) {
      final format = match.group(1) ?? match.group(2) ?? '';
      return _formatCustomDate(dateTime, format);
    });
  }

  static String _formatCustomDate(DateTime dateTime, String format) {
    String two(int value) => value.toString().padLeft(2, '0');
    return format
        .replaceAll('Y', dateTime.year.toString())
        .replaceAll('m', two(dateTime.month))
        .replaceAll('d', two(dateTime.day))
        .replaceAll('H', two(dateTime.hour))
        .replaceAll('M', two(dateTime.minute))
        .replaceAll('S', two(dateTime.second));
  }

  static String _formatYmdHms(DateTime value, {required bool utc}) {
    final date = utc ? value.toUtc() : value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}'
        '${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}
