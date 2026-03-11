
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';


/// Ekran onboardingu wyświetlany przy pierwszym uruchomieniu aplikacji.
/// Składa się z dwóch faz:
///   1. Formularz z imieniem, wzrostem i wagą (+ opcja "Pomiń")
///   2. Karuzela kafelków-tutorialowych opisujących funkcjonalności aplikacji
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // Faza: 0 = formularz profilu, 1 = tutorial
  int _phase = 0;

  // Kontrolery formularza
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Tutorial page controller
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Dane tutorialu ──────────────────────────────────────
  static final _tutorialPages = [
    _TutorialPage(
      icon: Icons.home_rounded,
      gradient: [Color(0xFFE94560), Color(0xFFFF6B6B)],
      title: '🏠 Ekran Główny',
      bullets: [
        '📊 Statusy dnia — od razu wiesz, czy dziś trenowałeś',
        '📅 Pasek tygodniowej aktywności — każdy dzień z ✓ to wygrany',
        '⚡ Szybki start treningu — jedno kliknięcie i ćwiczysz',
        '🏋️ Statystyki miesiąca: liczba treningów, czas, objętość (kg)',
      ],
    ),
    _TutorialPage(
      icon: Icons.fitness_center,
      gradient: [Color(0xFF6A4DFF), Color(0xFF8B7DFF)],
      title: '💪 Treningi & Plany',
      bullets: [
        '📝 Twórz spersonalizowane plany treningowe',
        '🎯 Ustaw serie, powtórzenia i ciężar z góry',
        '📈 Wykres objętości na grupę mięśniową w planie',
        '⏱ Wbudowany timer odpoczynku z powiadomieniami',
        '🔄 Pamięć ciężarów — apka podpowiada Ci wagi z ostatniego razu',
      ],
    ),
    _TutorialPage(
      icon: Icons.grid_view_rounded,
      gradient: [Color(0xFF00B4D8), Color(0xFF48CAE4)],
      title: '🗂 Baza Ćwiczeń',
      bullets: [
        '📚 Ponad 50 ćwiczeń z opisami i grupami mięśniowymi',
        '🔍 Filtrowanie po partii ciała — szybko znajdź to, czego szukasz',
        '➕ Możesz dodać własne ćwiczenia',
        '💡 Każde ćwiczenie ma opis techniki i cele mięśniowe',
      ],
    ),
    _TutorialPage(
      icon: Icons.bar_chart_rounded,
      gradient: [Color(0xFF2ECC71), Color(0xFF27AE60)],
      title: '📈 Postępy & Rekordy',
      bullets: [
        '🏆 Automatyczne śledzenie rekordów osobistych (PR)',
        '📊 Wykresy aktywności: tydzień / miesiąc / kwartał / rok',
        '💪 Rozkład treningów na partie ciała',
        '📸 Udostępnij swoje rekordy jako piękne plakaty (jak Spotify Wrapped!)',
      ],
    ),
    _TutorialPage(
      icon: Icons.person_rounded,
      gradient: [Color(0xFFFF9800), Color(0xFFFFB74D)],
      title: '👤 Profil & Odżywianie',
      bullets: [
        '🧮 Kalkulator BMR/TDEE — wylicza Twoje zapotrzebowanie kaloryczne',
        '🥩 Makroskładniki dopasowane do Twojego celu (masa/redukcja/siła)',
        '⚖️ Śledzenie wagi z wygładzaniem EWMA',
        '🎨 Personalizacja: motyw jasny/ciemny, kolor akcentu, jednostki',
      ],
    ),
  ];

  // ── Akcje ───────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());

    final profile = ProfileService.instance.profile;
    profile.name = name.isNotEmpty ? name : profile.name;
    if (height != null && height > 0) profile.heightCm = height;
    if (weight != null && weight > 0) profile.weightKg = weight;

    await ProfileService.instance.save(profile);
    _goToTutorial();
  }

  void _skipProfile() => _goToTutorial();

  void _goToTutorial() {
    _fadeCtrl.reverse().then((_) {
      setState(() => _phase = 1);
      _fadeCtrl.forward();
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onComplete();
  }

  // ── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _phase == 0 ? _buildProfilePhase(context) : _buildTutorialPhase(context),
      ),
    );
  }

  // ── FAZA 1: Formularz profilu ───────────────────────────
  Widget _buildProfilePhase(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logo + welcome
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [accent, accent.withValues(alpha: 0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 30),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fitness_center, size: 36, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Witaj w GymLoom!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Podaj swoje dane, żebyśmy mogli spersonalizować Twoje treningi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecond, fontSize: 14)),
              ),
              const SizedBox(height: 40),

              // Imię
              _buildLabel('Imię'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameCtrl,
                hint: 'np. Maks',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),

              // Wzrost
              _buildLabel('Wzrost (cm)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _heightCtrl,
                hint: 'np. 180',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Waga
              _buildLabel('Waga (kg)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _weightCtrl,
                hint: 'np. 75',
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),

              // Przyciski
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Dalej →',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _skipProfile,
                  child: const Text('Pomiń na razie',
                      style: TextStyle(color: AppTheme.textSecond, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.outfit(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecond.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppTheme.textSecond, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── FAZA 2: Tutorial ────────────────────────────────────
  Widget _buildTutorialPhase(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isLast = _currentPage == _tutorialPages.length - 1;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Nagłówek
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Przewodnik',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(isLast ? 'Zaczynamy! 🚀' : 'Pomiń',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Page indicator
          _buildPageIndicator(accent),
          const SizedBox(height: 16),

          // Páginas
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _tutorialPages.length,
              itemBuilder: (ctx, i) => _buildTutorialCard(_tutorialPages[i]),
            ),
          ),
          const SizedBox(height: 16),

          // Navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back
                _currentPage > 0
                    ? TextButton.icon(
                        onPressed: () => _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut),
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Wstecz'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.textSecond),
                      )
                    : const SizedBox(width: 100),
                // Next / Finish
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? _finishOnboarding
                        : () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                    ),
                    child: Text(isLast ? 'Zaczynamy! 🚀' : 'Dalej →',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tutorialPages.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildTutorialCard(_TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              page.gradient[0].withValues(alpha: 0.15),
              page.gradient[1].withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: page.gradient[0].withValues(alpha: 0.2),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: page.gradient),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient[0].withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(page.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              // Title
              Text(page.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),
              // Bullets
              ...page.bullets.map((bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 7, right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page.gradient[0],
                          ),
                        ),
                        Expanded(
                          child: Text(bullet,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.4,
                              )),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final List<String> bullets;

  const _TutorialPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.bullets,
  });
}
