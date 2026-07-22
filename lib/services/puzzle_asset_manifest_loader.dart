import 'dart:convert';

import 'package:flutter/services.dart';

import 'asset_manifest_validator.dart';

class PuzzleAssetManifestLoader {
  const PuzzleAssetManifestLoader._();

  static const assetPath = 'assets/catalog/asset_licenses.json';

  static Future<List<AssetManifestEntry>> loadApproved({
    AssetBundle? bundle,
  }) async {
    final rawManifest = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(rawManifest) as List<Object?>;
    final entries = decoded
        .cast<Map<String, Object?>>()
        .map(AssetManifestEntry.fromJson)
        .where((entry) => entry.approved)
        .toList(growable: false);

    return AssetManifestValidator.sortedById(entries);
  }

  static Set<String> existingPathsFor(Iterable<AssetManifestEntry> entries) {
    return entries
        .expand((entry) => [entry.path, entry.thumbnailPath])
        .nonNulls
        .toSet();
  }
}
