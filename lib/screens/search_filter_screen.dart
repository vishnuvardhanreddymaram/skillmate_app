import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'user_detail_screen.dart';
import 'dart:convert';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    // For a demo/small app, we fetch all and filter in memory for speed
    // In a large app, we would use Algolia or specialized Firestore queries
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    
    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(query.toLowerCase());
        final skillMatch = user.skillsHave.toLowerCase().contains(query.toLowerCase()) || 
                          user.skillsWant.toLowerCase().contains(query.toLowerCase());
        return nameMatch || skillMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Find Skillmates", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by name or skill...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
          backgroundImage: user.photoBase64 != null ? MemoryImage(base64Decode(user.photoBase64!)) : null,
          child: user.photoBase64 == null ? const Icon(Icons.person, color: Color(0xFF6C63FF)) : null,
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Teaches: ${user.skillsHave}", style: const TextStyle(fontSize: 12, color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text("Wants: ${user.skillsWant}", style: const TextStyle(fontSize: 12, color: Colors.orange), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No matches found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Try searching for a different skill.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
