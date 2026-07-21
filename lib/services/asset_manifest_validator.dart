class AssetManifestEntry {
  const AssetManifestEntry({
    required this.id,
    required this.path,
    required this.origin,
    required this.license,
    required this.attribution,
    required this.approved,
    required this.approvedBy,
    required this.approvedAt,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });

  factory AssetManifestEntry.fromJson(Map<String, Object?> json) {
    final dimensions = json['dimensions'] as Map<String, Object?>? ?? const {};
    return AssetManifestEntry(
      id: _string(json, 'id'),
      path: _string(json, 'path'),
      origin: _string(json, 'origin'),
      license: _string(json, 'license'),
      attribution: _string(json, 'attribution'),
      approved: json['approved'] == true,
      approvedBy: _string(json, 'approvedBy'),
      approvedAt: _string(json, 'approvedAt'),
      width: _int(dimensions, 'width'),
      height: _int(dimensions, 'height'),
      format: _string(json, 'format').toLowerCase(),
      bytes: _int(json, 'bytes'),
    );
  }

  final String id;
  final String path;
  final String origin;
  final String license;
  final String attribution;
  final bool approved;
  final String approvedBy;
  final String approvedAt;
  final int width;
  final int height;
  final String format;
  final int bytes;

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String ? value : '';
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is int ? value : 0;
  }
}

class AssetManifestPolicy {
  const AssetManifestPolicy({
    this.allowedFormats = const {'png', 'webp'},
    this.maxBytes = 800 * 1024,
    this.maxDimension = 2048,
    this.localPathPrefix = 'assets/images/',
  });

  static const defaultPolicy = AssetManifestPolicy();

  final Set<String> allowedFormats;
  final int maxBytes;
  final int maxDimension;
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

class AssetManifestValidator {
  const AssetManifestValidator._();

  static List<AssetManifestIssue> validateEntries(
    Iterable<AssetManifestEntry> entries, {
    Set<String> existingAssetPaths = const {},
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

      _validateApproval(entry, issues);
      _validateProvenance(entry, issues);
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
    List<AssetManifestIssue> issues,
  ) {
    if (entry.origin.trim().isEmpty) {
      issues.add(_issue(entry.id, 'origin', 'Assets require origin.'));
    }
    if (entry.license.trim().isEmpty) {
      issues.add(_issue(entry.id, 'license', 'Assets require license.'));
    }
    if (entry.attribution.trim().isEmpty) {
      issues.add(
        _issue(entry.id, 'attribution', 'Assets require attribution.'),
      );
    }
  }

  static void _validatePath(
    AssetManifestEntry entry,
    AssetManifestPolicy policy,
    Set<String> existingAssetPaths,
    List<AssetManifestIssue> issues,
  ) {
    final path = entry.path.trim();
    final isExternal =
        path.startsWith('http://') || path.startsWith('https://');
    final hasTraversal =
        path.contains('..') || path.startsWith('/') || path.contains('\\');
    if (path.isEmpty ||
        isExternal ||
        hasTraversal ||
        !path.startsWith(policy.localPathPrefix)) {
      issues.add(
        _issue(
          entry.id,
          'path',
          'Asset path must be local under ${policy.localPathPrefix}.',
        ),
      );
      return;
    }

    if (entry.approved && !existingAssetPaths.contains(path)) {
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
          'Format must match path extension and policy.',
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

    if (entry.bytes > policy.maxBytes) {
      issues.add(
        _issue(entry.id, 'bytes', 'Asset byte size is outside policy.'),
      );
    }
  }

  static AssetManifestIssue _issue(String id, String field, String message) {
    return AssetManifestIssue(id: id, field: field, message: message);
  }
}
