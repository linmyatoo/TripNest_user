import 'package:flutter/material.dart';
import '../../core/widgets/dropdown_form_field.dart';
import '../../app_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final qCtrl = TextEditingController();
  DateTime? checkIn, checkOut;
  String? mood;

  @override
  Widget build(BuildContext context) {
    final boxWidth = MediaQuery.of(context).size.width * 0.92;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(children: [
        // blurred photo bg placeholder
        Container(
            decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/search_bg.jpg'), // or remove if not available
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          ),
        )),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: boxWidth,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.92),
                  borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Search Event',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Where are you interested...?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _dateButton('Check in', checkIn, () async {
                        final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: DateTime.now());
                        if (d != null) setState(() => checkIn = d);
                      })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _dateButton('Check out', checkOut, () async {
                        final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: DateTime.now());
                        if (d != null) setState(() => checkOut = d);
                      })),
                    ]),
                    const SizedBox(height: 12),
                    WhiteDropdownFormField<String>(
                      value: mood,
                      hint: const Text('MOOD'),
                      items: const [
                        DropdownMenuItem(value: 'chill', child: Text('Chill')),
                        DropdownMenuItem(
                            value: 'adventure', child: Text('Adventure')),
                        DropdownMenuItem(
                            value: 'festival', child: Text('Festival')),
                      ],
                      onChanged: (v) => setState(() => mood = v),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final query = {
                            'q': qCtrl.text,
                            'checkIn': checkIn?.toIso8601String(),
                            'checkOut': checkOut?.toIso8601String(),
                            'mood': mood,
                          };
                          Navigator.of(context).pushNamed(
                              AppRoutes.searchResults,
                              arguments: query);
                        },
                        child: const Text('Search'),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value == null
            ? label
            : '${value.year}-${value.month}-${value.day}'),
        const SizedBox(width: 8),
        const Icon(Icons.calendar_month_outlined),
      ]),
    );
  }
}
