import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/block_model.dart';

class BlockProvider with ChangeNotifier {
  final FirebaseFirestore _db;

  // Add a constructor to allow injecting a Firestore instance for testing
  BlockProvider({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final Map<String, List<BlockModel>> _blocks = {};

  Future<List<BlockModel>> getBlocks(String userId) async {
    _blocks[userId] ??= [];
    final blocksQuery1 = await _db
          .collection('blocks')
          .where('blockerUserId', isEqualTo: userId)
          .get();
      final blocksQuery2 = await _db
          .collection('blocks')
          .where('blockedUserId', isEqualTo: userId)
          .get();

      for (var doc in blocksQuery1.docs) {
        _blocks[userId]!.add(BlockModel.fromJson(doc.data()));
      }
      for (var doc in blocksQuery2.docs) {
        _blocks[userId]!.add(BlockModel.fromJson(doc.data()));
      }
      return _blocks[userId]!;
  }
      

  Future<void> blockUser(String currentUser, String targetUser, String? matchId) async {
    try {
      final blockId = '${currentUser}_$targetUser';

      final block = BlockModel(
        id: blockId,
        blockerUserId: currentUser,
        blockedUserId: targetUser,
      );

      await _db.collection('blocks').doc(blockId).set(block.toJson());
      if (matchId != null) {
        await _db.collection('matches').doc(matchId).delete();
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }
}