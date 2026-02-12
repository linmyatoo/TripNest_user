import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dropdown_form_field.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final keywordCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  String? mood;

  @override
  void dispose() {
    keywordCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxWidth = MediaQuery.of(context).size.width * 0.92;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(children: [
        // gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF1D4ED8),
                Color(0xFF1E3A8A),
              ],
            ),
          ),
        ),
        // decorative circles
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                const Icon(Icons.travel_explore, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Find Your Next Adventure',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search events by location, keyword, or mood',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                // Search card
                Container(
                  width: boxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location field
                      _buildSearchField(
                        controller: locationCtrl,
                        icon: Icons.location_on_outlined,
                        hint: 'Location (e.g., Bangkok, Chiang Mai)',
                        label: 'Where?',
                      ),
                      const SizedBox(height: 16),
                      // Keyword field
                      _buildSearchField(
                        controller: keywordCtrl,
                        icon: Icons.search,
                        hint: 'Search by title or description',
                        label: 'Description',
                      ),
                      const SizedBox(height: 16),
                      // Mood dropdown
                      const Text(
                        'Mood',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: WhiteDropdownFormField<String>(
                          value: mood,
                          hint: const Text('Select a mood'),
                          items: const [
                            DropdownMenuItem(value: 'relaxed', child: Text('🏖️ Relaxed')),
                            DropdownMenuItem(value: 'excited', child: Text('🤩 Excited')),
                            // DropdownMenuItem(value: 'chill', child: Text('🏖️ Chill')),
                            DropdownMenuItem(value: 'energetic', child: Text('⚡ Energetic')),
                            DropdownMenuItem(value: 'fun', child: Text('😸 Fun')),
                            DropdownMenuItem(value: 'adventure', child: Text('🏔️ Adventure')),
                            DropdownMenuItem(value: 'festival', child: Text('🎉 Festival')),
                            DropdownMenuItem(value: 'cultural', child: Text('🏛️ Cultural')),
                            DropdownMenuItem(value: 'romantic', child: Text('💕 Romantic')),
                          ],
                          onChanged: (v) => setState(() => mood = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Search button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _handleSearch,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Search Events',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick search chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildQuickChip('Workshop', Icons.work),
                    _buildQuickChip('Beach', Icons.beach_access),
                    _buildQuickChip('Music', Icons.music_note),
                    _buildQuickChip('Food', Icons.restaurant),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.muted),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color.fromARGB(179, 24, 65, 227)),
      label: Text(label, style: const TextStyle(color: Color.fromARGB(179, 18, 92, 204))),
      backgroundColor: Colors.white.withOpacity(0.2),
      side: BorderSide.none,
      onPressed: () {
        setState(() {
          keywordCtrl.text = label;
        });
      },
    );
  }

  void _handleSearch() {
    final query = {
      'location': locationCtrl.text.trim(),
      'keyword': keywordCtrl.text.trim(),
      'mood': mood,
    };
    Navigator.of(context).pushNamed(
      AppRoutes.searchResults,
      arguments: query,
    );
  }
}
