// lib/src/features/profile/personal_data_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class PersonalDataPage extends StatefulWidget {
  static const route = '/personal-data';
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();

  String? _selectedGender;

  final _picker = ImagePicker();
  File? _avatar; // local preview image
  String? _profileImageUrl; // profile image from API
  static const int _maxBytes = 1024 * 1024; // 1 MB

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId; // Store user ID for future use (e.g., updating profile)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get email from local storage since API doesn't return it
      final localData = await AuthService.getUserData();
      final savedEmail = await SecurityService.getSavedEmail();

      // Fetch profile using GET /api/profile/me
      final response = await AuthService.getProfileMe();
      final user = response['data'] ?? response['user'] ?? response;

      // Extract profile image URL
      String? imageUrl =
          user['profilePictureUrl'];

      print('=== PROFILE IMAGE DEBUG ===');
      print('Raw profilePictureUrl: ${user['profilePictureUrl']}');
      print('Raw profileImage: ${user['profileImage']}');
      print('Raw avatar: ${user['avatar']}');
      print('Selected imageUrl: $imageUrl');

      // Filter out placeholder URLs
      if (imageUrl != null &&
          (imageUrl.contains('placeholder') ||
              imageUrl.contains('via.placeholder'))) {
        print('Filtered out placeholder URL');
        imageUrl = null;
      }

      print('Final imageUrl: $imageUrl');
      print('===========================');

      // Debug email
      print('=== EMAIL DEBUG ===');
      print('API email: ${user['email']}');
      print('Local email: ${localData['email']}');
      print('Saved email: $savedEmail');
      print('===================');

      // Determine email - priority: API > saved credentials > local storage
      String? emailToUse = user['email'];
      if (emailToUse == null ||
          emailToUse.isEmpty ||
          emailToUse == 'unknown@user') {
        emailToUse = savedEmail;
      }
      if (emailToUse == null || emailToUse.isEmpty) {
        final localEmail = localData['email'];
        if (localEmail != null && localEmail != 'unknown@user') {
          emailToUse = localEmail;
        }
      }

      setState(() {
        _userId = user['userId'] ?? user['_id'];

        // Full Name
        nameCtrl.text =
            (user['fullName'] != null && user['fullName'] != 'Not Set')
                ? user['fullName']
                : (user['username'] ?? user['name'] ?? '');

        // Email (from API or saved credentials - read only)
        emailCtrl.text = emailToUse ?? '';

        // Phone
        phoneCtrl.text = (user['phone'] != null && user['phone'] != 'Not Set')
            ? user['phone']
            : (user['phone_number'] ?? '');

        // Gender
        final gender = user['gender'];
        if (gender != null &&
            gender != 'Not Set' &&
            gender.toString().isNotEmpty) {
          _selectedGender = gender;
        } else {
          _selectedGender = null;
        }

        // Date of Birth - parse and format without time
        if (user['dateOfBirth'] != null && user['dateOfBirth'] != 'Not Set') {
          dobCtrl.text = _formatDateString(user['dateOfBirth']);
        } else if (user['dob'] != null && user['dob'] != 'Not Set') {
          dobCtrl.text = _formatDateString(user['dob']);
        }

        // Profile Image
        _profileImageUrl = imageUrl;

        _isLoading = false;
      });
      print('Profile loaded for user ID: $_userId');
    } catch (e) {
      if (mounted) {
        _snack(
            'Error loading profile: ${e.toString().replaceAll('Exception: ', '')}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService.updateProfile(
        fullName: nameCtrl.text.isNotEmpty ? nameCtrl.text : null,
        phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
        gender: _selectedGender,
        dateOfBirth: dobCtrl.text.isNotEmpty ? dobCtrl.text : null,
        imageFilePath: _avatar?.path,
      );

      if (mounted) {
        _snack('Profile updated successfully!');
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 24, 11, 24),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
    );
    if (picked != null) {
      dobCtrl.text =
          '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
      setState(() {});
    }
  }

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];

  /// Format date string to "Month Day, Year" format without time
  String _formatDateString(String dateStr) {
    try {
      // Try to parse ISO format or other common formats
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        return '${_monthName(date.month)} ${date.day}, ${date.year}';
      }
      // If it's already in a readable format without time, return as is
      // But strip any time portion if present (after 'T' or space followed by numbers)
      final cleanDate = dateStr.split('T').first.split(' ').first;
      // If it looks like YYYY-MM-DD, parse and format
      final parts = cleanDate.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null &&
            month != null &&
            day != null &&
            month >= 1 &&
            month <= 12) {
          return '${_monthName(month)} $day, $year';
        }
      }
      return dateStr; // Return original if can't parse
    } catch (e) {
      return dateStr; // Return original on error
    }
  }

  // ---------- Image compression (≤ 1 MB), pure Dart ----------
  Future<File?> _ensureUnder1MB(File file) async {
    Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes <= _maxBytes) return file;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _snack('Couldn’t read that image. Please choose a different file.');
      return null;
    }

    int quality = 85;
    int width = decoded.width;
    int height = decoded.height;
    img.Image current = decoded;

    Future<File> write(Uint8List data) async {
      final dir = await getTemporaryDirectory();
      final path = p.join(
          dir.path, 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final out = File(path);
      await out.writeAsBytes(data, flush: true);
      return out;
    }

    while (true) {
      final encoded =
          Uint8List.fromList(img.encodeJpg(current, quality: quality));
      if (encoded.lengthInBytes <= _maxBytes) {
        return write(encoded);
      }

      if (quality > 50) {
        quality -= 10; // 85 -> 75 -> 65 -> 55 -> 50
      } else {
        // start downscaling in 85% steps
        final newW = (width * 0.85).round();
        final newH = (height * 0.85).round();
        if (newW < 500 || newH < 500) break; // keep a reasonable minimum
        width = newW;
        height = newH;
        current = img.copyResize(decoded,
            width: width,
            height: height,
            interpolation: img.Interpolation.average);
      }

      if (quality < 35 && (width < 600 || height < 600)) break; // safety
    }

    _snack('Couldn’t keep the photo under 1MB. Please choose a smaller one.');
    return null;
  }

  Future<void> _showAvatarPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('Change profile photo',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    final x = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 100,
                      maxWidth: 4096,
                    );
                    if (x != null) {
                      final compressed = await _ensureUnder1MB(File(x.path));
                      if (compressed != null) {
                        setState(() => _avatar = compressed);
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    final x = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 100,
                      maxWidth: 4096,
                    );
                    if (x != null) {
                      final compressed = await _ensureUnder1MB(File(x.path));
                      if (compressed != null) {
                        setState(() => _avatar = compressed);
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    // Priority: local file > API image > default asset
    if (_avatar != null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: Colors.grey[200],
        backgroundImage: FileImage(_avatar!),
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 104,
              height: 104,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image: $error');
            return CircleAvatar(
              radius: 52,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  const AssetImage('assets/images/avatar_jacob.jpg'),
            );
          },
        ),
      );
    } else {
      return CircleAvatar(
        radius: 52,
        backgroundColor: Colors.grey[200],
        backgroundImage: const AssetImage('assets/images/avatar_jacob.jpg'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Personal Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildAvatar(),
                        // Pencil button at bottom-right
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showAvatarPickerSheet,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.edit,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Full Name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(hint: 'Harry', controller: nameCtrl),
                  const SizedBox(height: 16),
                  const Text('Email',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'harry3435@gmail.com',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Phone Number',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: '83542015258',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:
                          Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('+65',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        VerticalDivider(width: 1, thickness: 1),
                        SizedBox(width: 4),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Date of Birth',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dobCtrl,
                    readOnly: true,
                    onTap: _pickDob,
                    decoration: const InputDecoration(
                      hintText: 'November 24, 2000',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Gender',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    hint: const Text('Select Gender'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? null : _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}
