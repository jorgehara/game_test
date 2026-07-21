// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../models/grid_position.dart';
import '../models/puzzle.dart';
import '../models/puzzle_piece.dart';
import '../services/puzzle_catalog_service.dart';
import '../services/puzzle_piece_generator.dart';
import '../services/puzzle_shuffler.dart';

typedef PuzzleCatalogLoader = List<Puzzle> Function();
typedef PuzzlePieceGeneratorFn = List<PuzzlePiece> Function(Puzzle puzzle);
typedef PuzzlePieceShufflerFn =
    List<PuzzlePiece> Function(List<PuzzlePiece> pieces, {required int seed});

enum PuzzleGameStatus { idle, ready, unavailable, completed }

class PuzzleGameProvider extends ChangeNotifier {
  PuzzleGameProvider({
    PuzzleCatalogLoader catalogLoader = PuzzleCatalogService.all,
    PuzzlePieceGeneratorFn generator = PuzzlePieceGenerator.generate,
    PuzzlePieceShufflerFn shuffler = PuzzleShuffler.shuffle,
    int seed = 1,
  }) : _catalogLoader = catalogLoader,
       _generator = generator,
       _shuffler = shuffler,
       _seed = seed;

  final PuzzleCatalogLoader _catalogLoader;
  final PuzzlePieceGeneratorFn _generator;
  final PuzzlePieceShufflerFn _shuffler;
  final int _seed;

  PuzzleGameStatus _status = PuzzleGameStatus.idle;
  Puzzle? _currentPuzzle;
  List<PuzzlePiece> _pieces = const [];
  final Map<String, GridPosition> _placedPositions = {};

  PuzzleGameStatus get status => _status;

  Puzzle? get currentPuzzle => _currentPuzzle;

  List<PuzzlePiece> get pieces => List.unmodifiable(_pieces);

  List<PuzzlePiece> get piecesInTray {
    return List.unmodifiable(
      _pieces.where((piece) => !_placedPositions.containsKey(piece.id)),
    );
  }

  Set<String> get placedPieceIds => Set.unmodifiable(_placedPositions.keys);

  Map<String, GridPosition> get placedPositions {
    return Map.unmodifiable(_placedPositions);
  }

  int get progressCount => _placedPositions.length;

  double get progressRatio {
    if (_pieces.isEmpty) {
      return 0;
    }

    return progressCount / _pieces.length;
  }

  bool get isCompleted => _status == PuzzleGameStatus.completed;

  List<Puzzle> get playablePuzzles {
    return List.unmodifiable(
      _catalogLoader().where((puzzle) => puzzle.grid.isSupportedForGeneration),
    );
  }

  bool start({required String puzzleId}) {
    final puzzle = _findPlayablePuzzle(puzzleId);
    if (puzzle == null) {
      _setUnavailable();
      notifyListeners();
      return false;
    }

    _startPuzzle(puzzle);
    notifyListeners();
    return true;
  }

  bool selectPuzzle(String puzzleId) => start(puzzleId: puzzleId);

  bool placePiece(String pieceId) {
    if (_currentPuzzle == null ||
        isCompleted ||
        _placedPositions.containsKey(pieceId)) {
      return false;
    }

    final piece = _pieceById(pieceId);
    if (piece == null) {
      return false;
    }

    _placedPositions[piece.id] = piece.correctPosition;
    if (_placedPositions.length == _pieces.length) {
      _status = PuzzleGameStatus.completed;
    } else {
      _status = PuzzleGameStatus.ready;
    }
    notifyListeners();
    return true;
  }

  bool attemptPlacement(String pieceId) => placePiece(pieceId);

  void reset() {
    final puzzle = _currentPuzzle;
    if (puzzle == null) {
      _status = PuzzleGameStatus.idle;
      _pieces = const [];
      _placedPositions.clear();
      notifyListeners();
      return;
    }

    _startPuzzle(puzzle);
    notifyListeners();
  }

  bool isPlaced(String pieceId) => _placedPositions.containsKey(pieceId);

  Puzzle? _findPlayablePuzzle(String puzzleId) {
    for (final puzzle in playablePuzzles) {
      if (puzzle.id == puzzleId) {
        return puzzle;
      }
    }

    return null;
  }

  void _startPuzzle(Puzzle puzzle) {
    final generatedPieces = _generator(puzzle);
    _currentPuzzle = puzzle;
    _pieces = _shuffler(generatedPieces, seed: _seed);
    _placedPositions.clear();
    _status = PuzzleGameStatus.ready;
  }

  void _setUnavailable() {
    _status = PuzzleGameStatus.unavailable;
    _currentPuzzle = null;
    _pieces = const [];
    _placedPositions.clear();
  }

  PuzzlePiece? _pieceById(String pieceId) {
    for (final piece in _pieces) {
      if (piece.id == pieceId) {
        return piece;
      }
    }

    return null;
  }
}
