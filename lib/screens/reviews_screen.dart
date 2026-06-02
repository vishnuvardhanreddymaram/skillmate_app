import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewsScreen extends StatefulWidget {
  final String? targetUserId;
  final String? targetUserName;

  const ReviewsScreen({super.key, this.targetUserId, this.targetUserName});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  late final String _viewedUserId;
  bool _canWriteReview = false;

  @override
  void initState() {
    super.initState();
    _viewedUserId = widget.targetUserId ?? _currentUser?.uid ?? "";
    _checkCanWriteReview();
  }

  Future<void> _checkCanWriteReview() async {
    // A user can review another user only if they have an accepted swap request (a match)
    if (_currentUser == null || widget.targetUserId == null || widget.targetUserId == _currentUser.uid) {
      setState(() => _canWriteReview = false);
      return;
    }

    try {
      final matchesQuery1 = await FirebaseFirestore.instance
          .collection('requests')
          .where('fromUid', isEqualTo: _currentUser.uid)
          .where('toUid', isEqualTo: widget.targetUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final matchesQuery2 = await FirebaseFirestore.instance
          .collection('requests')
          .where('fromUid', isEqualTo: widget.targetUserId)
          .where('toUid', isEqualTo: _currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (mounted) {
        setState(() {
          _canWriteReview = matchesQuery1.docs.isNotEmpty || matchesQuery2.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Error checking review permission: $e");
    }
  }

  void _showAddReviewDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.rate_review, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Text("Review ${widget.targetUserName ?? 'User'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Rate your swap experience:", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    RatingBar.builder(
                      initialRating: 5,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (val) {
                        rating = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Comment",
                        hintText: "How was the skill sharing? What did you learn?",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Comment is required" : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => submitting = true);
                          try {
                            // Get current user profile for reviewer's name
                            final myDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
                            final myName = myDoc.data()?['name'] ?? 'SkillMate User';

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_viewedUserId)
                                .collection('reviews')
                                .add({
                              'reviewerUid': _currentUser.uid,
                              'reviewerName': myName,
                              'rating': rating,
                              'comment': commentController.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review submitted!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => submitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to submit review: $e')),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewedUserId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Invalid User Profile")));
    }

    final isOwnProfile = _currentUser != null && _viewedUserId == _currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(isOwnProfile ? "My Reviews" : "${widget.targetUserName ?? 'User'}'s Reviews", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: _canWriteReview
          ? FloatingActionButton.extended(
              onPressed: _showAddReviewDialog,
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.rate_review, color: Colors.white),
              label: const Text("Write a Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_viewedUserId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      isOwnProfile ? "No reviews yet" : "No reviews for this user yet",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwnProfile 
                          ? "Matches can write reviews here once you finish swapping skills!"
                          : "Be the first to review your skill sharing experience with them!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate aggregate rating
          double totalRating = 0;
          for (var doc in docs) {
            totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
          }
          final averageRating = totalRating / docs.length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Aggregate Rating Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text("out of 5", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBarIndicator(
                          rating: averageRating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 24.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Based on ${docs.length} review${docs.length > 1 ? 's' : ''}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "RECENT REVIEWS",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final review = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review['reviewerName'] ?? 'Anonymous Partner',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          RatingBarIndicator(
                            rating: (review['rating'] as num?)?.toDouble() ?? 5.0,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 16.0,
                            direction: Axis.horizontal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
