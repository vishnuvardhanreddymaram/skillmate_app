import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'search_filter_screen.dart';
import 'user_detail_screen.dart';
import 'ai_assistant_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUserModel;
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "Coding",
    "Design",
    "Music",
    "Marketing",
    "Languages",
    "Cooking",
    "Business",
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profile = await _firestoreService.getUserProfile(currentUser.uid);
      if (mounted) setState(() => _currentUserModel = profile);
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Discover Swaps", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchFilterScreen())),
              ),
            ],
          ),
          const SliverToBoxAdapter(
            child: DailySkillInsightCard(),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${_currentUserModel?.name ?? 'Skillmate'}!",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text("Find someone to exchange skills with today.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildCategoryFilter(),
                ],
              ),
            ),
          ),
          StreamBuilder<List<UserModel>>(
            stream: currentUser == null ? null : _firestoreService.getDiscoverFeed(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShimmerCard(),
                      childCount: 3,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == "All" 
                            ? "No users found nearby." 
                            : "No users found for '$_selectedCategory'.",
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final users = snapshot.data!.where((user) {
                if (_selectedCategory == "All") return true;
                
                final category = _selectedCategory.toLowerCase();
                final skillsHave = user.skillsHave.toLowerCase();
                final skillsWant = user.skillsWant.toLowerCase();

                // Smart logic for 'Coding' category
                if (_selectedCategory == "Coding") {
                  final codingKeywords = ["coding", "programming", "java", "python", "c", "c++", "dart", "flutter", "javascript", "developer"];
                  return codingKeywords.any((kw) => skillsHave.contains(kw) || skillsWant.contains(kw));
                }

                return skillsHave.contains(category) || skillsWant.contains(category);
              }).toList();

              if (users.isEmpty) {
                return SliverFillRemaining(child: Center(child: Text("No users found for '$_selectedCategory'.")));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return _buildPremiumCard(user);
                    },
                    childCount: users.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  void _sendSwapRequest(UserModel user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firestoreService.sendSwapRequest(
        fromUid: currentUser.uid,
        fromName: _currentUserModel?.name ?? "User",
        fromSkills: _currentUserModel?.skillsHave ?? "Skills",
        fromPhone: _currentUserModel?.phone,
        toUid: user.uid,
        toName: user.name,
        toSkills: user.skillsHave,
        toPhone: user.phone,
      );

      if (mounted) {
        _showSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final nav = Navigator.of(dialogContext);
        Future.delayed(const Duration(seconds: 2), () {
          if (nav.canPop()) nav.pop();
        });
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Lottie.network(
                  'https://lottie.host/57f6b986-e822-4a00-9831-29e19623e1f3/yE6hYF2v5i.json', // Rocket success
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              const Material(
                color: Colors.transparent,
                child: Text("Swap Request Sent! 🚀", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    backgroundImage: user.photoBase64 != null ? MemoryImage(base64Decode(user.photoBase64!)) : null,
                    child: user.photoBase64 == null ? const Icon(Icons.person, color: Color(0xFF6C63FF), size: 30) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user.bio, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Rating placeholder removed
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSkillRow("I CAN TEACH", user.skillsHave, Colors.green),
                  const SizedBox(height: 12),
                  _buildSkillRow("I WANT TO LEARN", user.skillsWant, Colors.orange),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(user: user))),
                          child: const Text("View Profile"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () => _sendSwapRequest(user),
                          child: const Text("Request Swap"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillRow(String label, String skills, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(skills, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class DailySkillInsightCard extends StatelessWidget {
  const DailySkillInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> insights = [
      {"tip": "Teaching others is the best way to master a skill yourself!", "author": "Pro Tip"},
      {"tip": "Check out the Java category to find experts for your next project.", "author": "Did you know?"},
      {"tip": "A complete profile gets 3x more swap requests. Update yours now!", "author": "Growth Hack"},
      {"tip": "Always meet in public places for your first skill swap session.", "author": "Safety First"},
    ];
    final insight = insights[DateTime.now().day % insights.length];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8E87FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  insight['author']!,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insight['tip']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
