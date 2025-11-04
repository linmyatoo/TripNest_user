// lib/src/features/profile/personal_data_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/theme/app_colors.dart';

class PersonalDataPage extends StatefulWidget {
  static const route = '/personal-data';
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final nameCtrl = TextEditingController(text: 'Harry');
  final emailCtrl = TextEditingController(text: 'harry3435@gmail.com');
  final phoneCtrl = TextEditingController(text: '83542015258');
  final dobCtrl = TextEditingController(text: 'November 24, 2000');

  final _picker = ImagePicker();
  File? _avatar; // local preview image
  static const int _maxBytes = 1024 * 1024; // 1 MB

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

    Future<File> _write(Uint8List data) async {
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
        return _write(encoded);
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
                      if (compressed != null)
                        setState(() => _avatar = compressed);
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
                      if (compressed != null)
                        setState(() => _avatar = compressed);
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

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatar != null
        ? FileImage(_avatar!)
        : const AssetImage('assets/images/avatar_jacob.jpg') as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Personal Data'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(radius: 52, backgroundImage: avatarProvider),
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
                          child:
                              Icon(Icons.edit, size: 18, color: Colors.white),
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
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'harry3435@gmail.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              hint: '83542015258',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              prefix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Text('+65', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const AppTextField(hint: ''),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Save Canges', // (keeping your Figma label)
              onPressed: () {
                // Navigate back to Profile page
                Navigator.pop(context);
                // Optionally show feedback
                // _snack('Profile updated (mock)');
              },
            ),
          ],
        ),
      ),
    );
  }
}
