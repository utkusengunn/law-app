import 'package:flutter/material.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.wb_sunny_outlined,
    title: 'Bugün ne var, yakında ne olacak?',
    description:
        'Ana sayfa, günün duruşmalarını, görüşmelerini, işlerini ve yaklaşan '
        'ödemelerini tek bakışta gösterir.',
  ),
  _OnboardingSlide(
    icon: Icons.menu,
    title: 'Hızlı ekleme hep elinizin altında',
    description:
        'Sol üstteki menüden müvekkil, dosya, süre, duruşma, görüşme, iş ve '
        'ödeme ekleyebilirsiniz.',
  ),
  _OnboardingSlide(
    icon: Icons.payments_outlined,
    title: 'Ödemeleri esnek takip edin',
    description:
        'Tek seferde ya da taksitli plan kurarak kısmi tahsilatları kaydedin; '
        'kalan tutar ve gecikme otomatik hesaplanır.',
  ),
  _OnboardingSlide(
    icon: Icons.calendar_month_outlined,
    title: 'Takvimde hızlı filtreler',
    description:
        'Bugün, Yarın, Bu Hafta veya Bu Ay\'a tek dokunuşla geçip o aralıktaki '
        'tüm kayıtları görün.',
  ),
];

/// İlk girişte bir kez gösterilen, kısa ve animasyonlu tanıtım akışı.
/// Faz-2'ye ertelenen kapsamlı onboarding değil - sadece 4 ekranlık, hızla
/// geçilebilen bir "burada neler var" özeti.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Geç'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: _next,
                child: Text(isLast ? 'Başla' : 'İleri'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(slide.title),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: 0.7 + (0.3 * value),
              child: Opacity(opacity: value.clamp(0, 1), child: child),
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon,
                  size: 44, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14.5),
          ),
        ],
      ),
    );
  }
}
