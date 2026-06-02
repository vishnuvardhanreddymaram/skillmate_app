import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  List<Map<String, String>> _filteredFAQs = [];

  final List<String> _categories = ["All", "General", "Swapping", "Security", "Account"];

  final List<Map<String, String>> _faqs = [
    {
      "category": "Swapping",
      "question": "How do I request a swap?",
      "answer": "Go to the Discover feed, find a profile that teaches the skill you want, and click 'Request Swap'. You will match once they accept your request!"
    },
    {
      "category": "General",
      "question": "Is SkillMate free?",
      "answer": "Yes, basic skill swapping is completely free! We believe in peer-to-peer knowledge exchange without monetary transactions."
    },
    {
      "category": "Account",
      "question": "Can I edit my skills later?",
      "answer": "Absolutely! Go to your Profile screen, tap the 'Edit Profile' button, modify your teaching or learning skills, and hit Save."
    },
    {
      "category": "Security",
      "question": "How do I report someone?",
      "answer": "If you experience any issues or suspicious behavior, navigate to Settings -> Help & Support and choose 'Report an Issue' to submit a report to our administrators."
    },
    {
      "category": "Swapping",
      "question": "Where do lessons take place?",
      "answer": "You can coordinate with your partner to choose the platform that suits you best: online via Zoom, Google Meet, Skype, or in-person at a local cafe or library."
    },
    {
      "category": "Security",
      "question": "Is my phone number shared?",
      "answer": "By default, your phone number is private. In the chat, you can choose to explicitly share your contact details using the 'Share Phone' tool when you feel comfortable."
    }
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _faqs;
    _searchController.addListener(_filterFAQs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFAQs = _faqs.where((faq) {
        final matchesQuery = faq['question']!.toLowerCase().contains(query) ||
            faq['answer']!.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == "All" || faq['category'] == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("FAQ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search questions or keywords...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Category Selectors
          Container(
            height: 56,
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _filterFAQs();
                    },
                    selectedColor: const Color(0xFF6C63FF).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF6C63FF),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // FAQ List
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          "No results found",
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFAQs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.help_outline_rounded, color: Color(0xFF6C63FF), size: 20),
                            ),
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                                child: Text(
                                  faq['answer']!,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
