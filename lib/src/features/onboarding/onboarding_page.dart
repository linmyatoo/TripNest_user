import 'package:flutter/material.dart';
import '../../core/widgets/primary_button.dart';

class OnboardingPage extends StatefulWidget {
  static const route = '/onboarding';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int page = 0;

  final slides = const [
    _Slide(
      bg: 'assets/images/onboarding_1.jpg',
      title: 'Collect Memories\nNot Things',
      subtitle: 'One app. Endless experiences.',
    ),
    _Slide(
      bg: 'assets/images/onboarding_2.jpg',
      title: 'Adventure is only a\nbooking away',
      subtitle: 'Life is made of moments\nBook yours today',
    ),
    _Slide(
      bg: 'assets/images/onboarding_3.jpg',
      title: 'Discover the world,\nOne event at a time',
      subtitle: 'From clicks to memories in minutes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: (i) => setState(() => page = i),
            itemCount: slides.length,
            itemBuilder: (_, i) {
              final s = slides[i];
              return _BackgroundSlide(s: s);
            },
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dots(count: slides.length, index: page),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () {
                    if (page < slides.length - 1) {
                      controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text("Haven't registered yet? ",
                        style: TextStyle(color: Colors.white)),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: const Text('Register Now',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String bg, title, subtitle;
  const _Slide({required this.bg, required this.title, required this.subtitle});
}

class _BackgroundSlide extends StatelessWidget {
  final _Slide s;
  const _BackgroundSlide({required this.s});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(s.bg, fit: BoxFit.cover),
        Container(
            decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black54],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        )),
        Positioned(
          left: 24,
          right: 24,
          bottom: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.25)),
              const SizedBox(height: 10),
              Text(s.subtitle,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count, index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
