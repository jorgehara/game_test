import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AssetManifestEntry {
  const AssetManifestEntry({
    required this.id,
    required this.path,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
    required this.attribution,
    required this.approved,
    required this.approvedBy,
    required this.approvedAt,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
    required this.sha256,
    this.thumbnailPath,
  });

  factory AssetManifestEntry.fromJson(Map<String, Object?> json) {
    final dimensions = json['dimensions'] as Map<String, Object?>? ?? const {};
    return AssetManifestEntry(
      id: _string(json, 'id'),
      path: _string(json, 'path'),
      thumbnailPath: _nullableString(json, 'thumbnailPath'),
      sourceTitle: _string(json, 'sourceTitle', fallbackKey: 'origin'),
      sourceUrl: _string(json, 'sourceUrl', fallbackKey: 'origin'),
      license: _string(json, 'license'),
      licenseUrl: _string(json, 'licenseUrl'),
      attribution: _string(json, 'attribution'),
      approved: json['approved'] == true,
      approvedBy: _string(json, 'approvedBy'),
      approvedAt: _string(json, 'approvedAt'),
      width: _int(dimensions, 'width', fallback: _int(json, 'width')),
      height: _int(dimensions, 'height', fallback: _int(json, 'height')),
      format: _string(json, 'format').toLowerCase(),
      bytes: _int(json, 'bytes'),
      sha256: _string(json, 'sha256', fallbackKey: 'hash').toLowerCase(),
    );
  }

  final String id;
  final String path;
  final String? thumbnailPath;
  final String sourceTitle;
  final String sourceUrl;
  final String license;
  final String licenseUrl;
  final String attribution;
  final bool approved;
  final String approvedBy;
  final String approvedAt;
  final int width;
  final int height;
  final String format;
  final int bytes;
  final String sha256;

  String get origin => sourceUrl;

  static String _string(
    Map<String, Object?> json,
    String key, {
    String? fallbackKey,
  }) {
    final value = json[key];
    if (value is String) return value;
    final fallback = fallbackKey == null ? null : json[fallbackKey];
    return fallback is String ? fallback : '';
  }

  static String? _nullableString(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static int _int(Map<String, Object?> json, String key, {int fallback = 0}) {
    final value = json[key];
    return value is int ? value : fallback;
  }
}

class AssetManifestPolicy {
  const AssetManifestPolicy({
    this.allowedFormats = const {'png', 'webp'},
    this.allowedLicenses = const {
      'PROJECT-OWNED',
      'CC0-1.0',
      'PUBLIC-DOMAIN',
      'CC-BY-4.0',
      'CC-BY-3.0',
    },
    this.attributionRequiredLicenses = const {'CC-BY-4.0', 'CC-BY-3.0'},
    this.maxBytes = 800 * 1024,
    this.maxThumbnailBytes = 80 * 1024,
    this.maxDimension = 2048,
    this.thumbnailDimension = 256,
    this.localPathPrefix = 'assets/images/',
  });

  static const defaultPolicy = AssetManifestPolicy();

  final Set<String> allowedFormats;
  final Set<String> allowedLicenses;
  final Set<String> attributionRequiredLicenses;
  final int maxBytes;
  final int maxThumbnailBytes;
  final int maxDimension;
  final int thumbnailDimension;
  final String localPathPrefix;
}

class AssetManifestIssue {
  const AssetManifestIssue({
    required this.id,
    required this.field,
    required this.message,
  });

  final String id;
  final String field;
  final String message;

  @override
  String toString() => '$id.$field: $message';
}

class AssetProbeResult {
  const AssetProbeResult({
    required this.exists,
    this.bytes = 0,
    this.width = 0,
    this.height = 0,
    this.format = '',
    this.sha256 = '',
  });

  const AssetProbeResult.missing() : this(exists: false);

  final bool exists;
  final int bytes;
  final int width;
  final int height;
  final String format;
  final String sha256;
}

abstract interface class AssetProbe {
  Future<AssetProbeResult> probe(String path);
}

class LocalAssetProbe implements AssetProbe {
  const LocalAssetProbe();

  @override
  Future<AssetProbeResult> probe(String path) async {
    final file = File(path);
    if (!file.existsSync()) return const AssetProbeResult.missing();
    final bytes = await file.readAsBytes();
    final decoded = _decodeImageHeader(bytes);
    return AssetProbeResult(
      exists: true,
      bytes: bytes.length,
      width: decoded.width,
      height: decoded.height,
      format: decoded.format,
      sha256: sha256.convert(bytes).toString(),
    );
  }
}

class AssetManifestValidator {
  const AssetManifestValidator._();

  static List<AssetManifestIssue> validateEntries(
    Iterable<AssetManifestEntry> entries, {
    Set<String>? existingAssetPaths,
    AssetManifestPolicy policy = AssetManifestPolicy.defaultPolicy,
  }) {
    final issues = <AssetManifestIssue>[];
    final ids = <String>{};

    for (final entry in entries) {
      final id = entry.id.trim().isEmpty ? '<missing-id>' : entry.id;
      if (entry.id.trim().isEmpty) {
        issues.add(_issue(id, 'id', 'Asset id is required.'));
      } else if (!ids.add(entry.id)) {
        issues.add(_issue(id, 'id', 'Asset id must be unique.'));
      }

      _validatePath(entry, policy, existingAssetPaths, issues);
      _validateFormat(entry, policy, issues);
      _validateDimensions(entry, policy, issues);
      _validateBytes(entry, policy, issues);
      _validateHashMetadata(entry, issues);
      _validateApproval(entry, issues);
      _validateProvenance(entry, policy, issues);
    }

    return List.unmodifiable(issues);
  }

  static Future<List<AssetManifestIssue>> validateEntriesWithProbe(
    Iterable<AssetManifestEntry> entries,
    AssetProbe probe, {
    AssetManifestPolicy policy = AssetManifestPolicy.defaultPolicy,
  }) async {
    final manifestIssues = validateEntries(entries, policy: policy);
    final issues = <AssetManifestIssue>[...manifestIssues];

    for (final entry in entries) {
      if (!entry.approved) continue;
      if (!_isSafeLocalPath(entry.path, policy)) continue;
      final result = await probe.probe(entry.path);
      if (!result.exists) {
        issues.add(_issue(entry.id, 'path', 'Image file is missing locally.'));
      } else {
        _validateProbeResult(entry, result, issues);
      }

      final thumbnailPath = entry.thumbnailPath;
      if (thumbnailPath == null || !_isSafeLocalPath(thumbnailPath, policy)) {
        continue;
      }
      final thumbnailResult = await probe.probe(thumbnailPath);
      if (!thumbnailResult.exists) {
        issues.add(
          _issue(
            entry.id,
            'thumbnailPath',
            'Thumbnail file is missing locally.',
          ),
        );
      } else {
        _validateThumbnailProbeResult(
          entry,
          thumbnailPath,
          thumbnailResult,
          policy,
          issues,
        );
      }
    }

    return List.unmodifiable(issues);
  }

  static List<AssetManifestIssue> validateCatalogAndPubspec({
    required Iterable<AssetManifestEntry> entries,
    required Iterable<String> catalogPaths,
    required Iterable<String> pubspecAssets,
  }) {
    final issues = <AssetManifestIssue>[];
    final entryList = entries.toList(growable: false);
    final manifestPaths = <String>{
      for (final entry in entryList) entry.path,
      for (final entry in entryList)
        if (entry.thumbnailPath != null) entry.thumbnailPath!,
    };
    final catalogPathSet = catalogPaths.toSet();
    final pubspecAssetSet = pubspecAssets.toSet();

    for (final entry in entryList) {
      if (!entry.approved) continue;
      if (!catalogPathSet.contains(entry.path)) {
        issues.add(
          _issue(
            entry.id,
            'catalog',
            'Image path is not referenced by catalog.',
          ),
        );
      }
      if (!_isDeclaredInPubspec(entry.path, pubspecAssetSet)) {
        issues.add(
          _issue(
            entry.id,
            'pubspec',
            'Image path is not declared in pubspec assets.',
          ),
        );
      }

      final thumbnailPath = entry.thumbnailPath;
      if (thumbnailPath == null) continue;
      if (!catalogPathSet.contains(thumbnailPath)) {
        issues.add(
          _issue(
            entry.id,
            'thumbnailCatalog',
            'Thumbnail path is not referenced by catalog.',
          ),
        );
      }
      if (!_isDeclaredInPubspec(thumbnailPath, pubspecAssetSet)) {
        issues.add(
          _issue(
            entry.id,
            'thumbnailPubspec',
            'Thumbnail path is not declared in pubspec assets.',
          ),
        );
      }
    }

    for (final path in catalogPathSet) {
      if (!manifestPaths.contains(path)) {
        issues.add(
          _issue(path, 'catalog', 'Catalog path has no manifest entry.'),
        );
      }
    }

    return List.unmodifiable(issues);
  }

  static List<AssetManifestEntry> approvedUsableAssets(
    Iterable<AssetManifestEntry> entries, {
    Set<String> existingAssetPaths = const {},
    AssetManifestPolicy policy = AssetManifestPolicy.defaultPolicy,
  }) {
    return List.unmodifiable(
      entries.where((entry) {
        if (!entry.approved) return false;
        return validateEntries(
          [entry],
          existingAssetPaths: existingAssetPaths,
          policy: policy,
        ).isEmpty;
      }),
    );
  }

  static List<AssetManifestEntry> sortedById(
    Iterable<AssetManifestEntry> entries,
  ) {
    return List.unmodifiable(
      [...entries]..sort((a, b) => a.id.compareTo(b.id)),
    );
  }

  static void _validateApproval(
    AssetManifestEntry entry,
    List<AssetManifestIssue> issues,
  ) {
    if (!entry.approved) {
      issues.add(
        _issue(entry.id, 'approved', 'Asset must be approved before use.'),
      );
      return;
    }

    if (entry.approvedBy.trim().isEmpty) {
      issues.add(
        _issue(entry.id, 'approvedBy', 'Approved assets require reviewer.'),
      );
    }

    final approvedAt = entry.approvedAt.trim();
    if (approvedAt.isEmpty || DateTime.tryParse(approvedAt) == null) {
      issues.add(
        _issue(
          entry.id,
          'approvedAt',
          'Approved assets require an ISO-8601 approval date.',
        ),
      );
    }
  }

  static void _validateProvenance(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    List<AssetManifestIssue> issues,
  ) {
    if (entry.sourceTitle.trim().isEmpty) {
      issues.add(
        _issue(entry.id, 'sourceTitle', 'Assets require source title.'),
      );
    }
    if (entry.sourceUrl.trim().isEmpty) {
      issues.add(_issue(entry.id, 'sourceUrl', 'Assets require source URL.'));
    } else if (entry.sourceUrl.toLowerCase().contains('pinterest.')) {
      issues.add(
        _issue(
          entry.id,
          'sourceUrl',
          'Pinterest is reference-only and cannot be binary source evidence.',
        ),
      );
    }
    if (!policy.allowedLicenses.contains(entry.license)) {
      issues.add(
        _issue(entry.id, 'license', 'Asset license is not whitelisted.'),
      );
    }
    if (entry.licenseUrl.trim().isEmpty) {
      issues.add(_issue(entry.id, 'licenseUrl', 'Assets require license URL.'));
    }
    if (entry.attribution.trim().isEmpty) {
      issues.add(
        _issue(entry.id, 'attribution', 'Assets require attribution evidence.'),
      );
    }
  }

  static void _validatePath(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    Set<String>? existingAssetPaths,
    List<AssetManifestIssue> issues,
  ) {
    if (!_isSafeLocalPath(entry.path, policy)) {
      issues.add(
        _issue(
          entry.id,
          'path',
          'Asset path must be safe and local under ${policy.localPathPrefix}.',
        ),
      );
      return;
    }

    final thumbnailPath = entry.thumbnailPath;
    if (thumbnailPath != null && !_isSafeLocalPath(thumbnailPath, policy)) {
      issues.add(
        _issue(
          entry.id,
          'thumbnailPath',
          'Thumbnail path must be safe and local.',
        ),
      );
    }

    if (entry.approved &&
        existingAssetPaths != null &&
        !existingAssetPaths.contains(entry.path)) {
      issues.add(
        _issue(entry.id, 'path', 'Approved asset file is missing locally.'),
      );
    }
  }

  static void _validateFormat(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    List<AssetManifestIssue> issues,
  ) {
    final format = entry.format.toLowerCase();
    if (!policy.allowedFormats.contains(format) ||
        !entry.path.toLowerCase().endsWith('.$format')) {
      issues.add(
        _issue(
          entry.id,
          'format',
          'Format must match path extension and PNG/WebP policy.',
        ),
      );
    }
  }

  static void _validateDimensions(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    List<AssetManifestIssue> issues,
  ) {
    if (entry.width <= 0 ||
        entry.height <= 0 ||
        entry.width > policy.maxDimension ||
        entry.height > policy.maxDimension) {
      issues.add(
        _issue(
          entry.id,
          'dimensions',
          'Dimensions must be positive and within policy.',
        ),
      );
    }
  }

  static void _validateBytes(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    List<AssetManifestIssue> issues,
  ) {
    if (entry.bytes <= 0) {
      issues.add(
        _issue(entry.id, 'bytes', 'Asset byte size metadata is required.'),
      );
      return;
    }

    final maxBytes = entry.path.contains('_thumb.')
        ? policy.maxThumbnailBytes
        : policy.maxBytes;
    if (entry.bytes > maxBytes) {
      issues.add(
        _issue(entry.id, 'bytes', 'Asset byte size is outside policy.'),
      );
    }
  }

  static void _validateHashMetadata(
    AssetManifestEntry entry,
    List<AssetManifestIssue> issues,
  ) {
    final hash = entry.sha256.trim();
    if (hash.length != 64 || !RegExp(r'^[a-f0-9]+$').hasMatch(hash)) {
      issues.add(
        _issue(entry.id, 'sha256', 'Asset sha256 metadata is required.'),
      );
    }
  }

  static void _validateProbeResult(
    AssetManifestEntry entry,
    AssetProbeResult result,
    List<AssetManifestIssue> issues,
  ) {
    if (entry.bytes != result.bytes) {
      issues.add(
        _issue(
          entry.id,
          'bytes',
          'Image manifest bytes do not match file bytes.',
        ),
      );
    }
    if (entry.width != result.width || entry.height != result.height) {
      issues.add(
        _issue(
          entry.id,
          'dimensions',
          'Image manifest dimensions do not match decoded file.',
        ),
      );
    }
    if (entry.format.toLowerCase() != result.format.toLowerCase()) {
      issues.add(
        _issue(
          entry.id,
          'format',
          'Image manifest format does not match decoded file.',
        ),
      );
    }
    if (entry.sha256.toLowerCase() != result.sha256.toLowerCase()) {
      issues.add(
        _issue(
          entry.id,
          'sha256',
          'Image manifest sha256 does not match file.',
        ),
      );
    }
  }

  static void _validateThumbnailProbeResult(
    AssetManifestEntry entry,
    String thumbnailPath,
    AssetProbeResult result,
    AssetManifestPolicy policy,
    List<AssetManifestIssue> issues,
  ) {
    if (result.bytes <= 0 || result.bytes > policy.maxThumbnailBytes) {
      issues.add(
        _issue(
          entry.id,
          'thumbnailBytes',
          'Thumbnail byte size is outside policy.',
        ),
      );
    }
    if (result.width != policy.thumbnailDimension ||
        result.height != policy.thumbnailDimension) {
      issues.add(
        _issue(
          entry.id,
          'thumbnailDimensions',
          'Thumbnail decoded dimensions must be ${policy.thumbnailDimension}x${policy.thumbnailDimension}.',
        ),
      );
    }
    final extension = thumbnailPath.split('.').last.toLowerCase();
    if (!policy.allowedFormats.contains(result.format.toLowerCase()) ||
        result.format.toLowerCase() != extension) {
      issues.add(
        _issue(
          entry.id,
          'thumbnailFormat',
          'Thumbnail decoded format must match PNG/WebP path extension.',
        ),
      );
    }
  }

  static bool _isSafeLocalPath(String path, AssetManifestPolicy policy) {
    final trimmed = path.trim();
    return trimmed.isNotEmpty &&
        trimmed.startsWith(policy.localPathPrefix) &&
        !trimmed.startsWith('/') &&
        !trimmed.startsWith('\\') &&
        !trimmed.contains('..') &&
        !trimmed.contains('\\') &&
        !trimmed.contains(':') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://');
  }

  static bool _isDeclaredInPubspec(String path, Set<String> pubspecAssets) {
    return pubspecAssets.contains(path) ||
        pubspecAssets.any(
          (asset) => asset.endsWith('/') && path.startsWith(asset),
        );
  }

  static AssetManifestIssue _issue(String id, String field, String message) {
    return AssetManifestIssue(id: id, field: field, message: message);
  }
}

({String format, int width, int height}) _decodeImageHeader(Uint8List bytes) {
  if (_isPng(bytes)) {
    return (
      format: 'png',
      width: _uint32(bytes, 16),
      height: _uint32(bytes, 20),
    );
  }
  if (_isWebP(bytes)) {
    return _decodeWebPHeader(bytes);
  }
  return (format: 'unknown', width: 0, height: 0);
}

bool _isPng(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  return bytes.length >= 24 &&
      Iterable<int>.generate(
        signature.length,
      ).every((i) => bytes[i] == signature[i]);
}

bool _isWebP(Uint8List bytes) {
  return bytes.length >= 16 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
}

({String format, int width, int height}) _decodeWebPHeader(Uint8List bytes) {
  final chunk = bytes.length >= 16
      ? String.fromCharCodes(bytes.sublist(12, 16))
      : '';
  if (chunk == 'VP8X' && bytes.length >= 30) {
    return (
      format: 'webp',
      width: 1 + _uint24(bytes, 24),
      height: 1 + _uint24(bytes, 27),
    );
  }
  if (chunk == 'VP8 ' && bytes.length >= 30) {
    return (
      format: 'webp',
      width: _uint16(bytes, 26) & 0x3fff,
      height: _uint16(bytes, 28) & 0x3fff,
    );
  }
  if (chunk == 'VP8L' && bytes.length >= 25) {
    final b0 = bytes[21];
    final b1 = bytes[22];
    final b2 = bytes[23];
    final b3 = bytes[24];
    return (
      format: 'webp',
      width: 1 + (((b1 & 0x3f) << 8) | b0),
      height: 1 + (((b3 & 0x0f) << 10) | (b2 << 2) | ((b1 & 0xc0) >> 6)),
    );
  }
  return (format: 'webp', width: 0, height: 0);
}

int _uint16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _uint24(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}

int _uint32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
