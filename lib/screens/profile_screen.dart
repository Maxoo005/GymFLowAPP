import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/nutrition_profile.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/nutrition_service.dart';
import '../services/workout_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileService get _ps => ProfileService.instance;

  @override
  Widget build(BuildContext context) {
    final profile = _ps.profile;
    final textTheme = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ustawienia',
            onPressed: _openSettings,
          ),
          TextButton(
            onPressed: _editProfile,
            child: Text('Edytuj', style: TextStyle(color: accent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 8),

          // ── Avatar ──────────────────────────────────
          GestureDetector(
            onTap: _editProfile,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.bgCard,
                child: profile.name.isNotEmpty
                  ? Text(profile.name[0].toUpperCase(),
                      style: TextStyle(
                        color: accent, fontSize: 42, fontWeight: FontWeight.bold))
                  : Icon(Icons.person, size: 52, color: accent),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(profile.name.isNotEmpty ? profile.name : 'Twój profil',
              style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(profile.name.isNotEmpty ? '' : 'Uzupełnij swoje dane',
              style: textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Dane osobowe ─────────────────────────────
          _SectionHeader('Dane osobowe'),
          const SizedBox(height: 10),
          _InfoTile(Icons.cake_outlined, 'Wiek',
              profile.age != null ? '${profile.age} lat' : 'Nie ustawiono'),
          _InfoTile(Icons.height, 'Wzrost',
              profile.heightCm != null ? '${profile.heightCm!.toInt()} cm' : 'Nie ustawiono'),
          _InfoTile(Icons.monitor_weight_outlined, 'Waga',
              profile.weightKg != null ? '${profile.weightKg} kg' : 'Nie ustawiono'),
          const SizedBox(height: 24),

          // ── Cel treningowy ────────────────────────────
          _SectionHeader('Cel treningowy'),
          const SizedBox(height: 10),
          _GoalDisplay(current: profile.goal, onChanged: (g) async {
            profile.goal = g;
            await _ps.save(profile);
            if (mounted) setState(() {});
          }),
          const SizedBox(height: 24),

          // ── BMI ───────────────────────────────────────
          if (profile.heightCm != null && profile.weightKg != null) ...[
            _SectionHeader('Wskaźnik BMI'),
            const SizedBox(height: 10),
            _BmiCard(height: profile.heightCm!, weight: profile.weightKg!),
            const SizedBox(height: 24),
          ],

          // ── Kalkulator kalorii ────────────────────────
          _SectionHeader('Kalkulator żywieniowy'),
          const SizedBox(height: 10),
          _NutritionCard(
            profile: profile,
            onQuestionnaireCompleted: () => setState(() {}),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Edycja profilu ────────────────────────────────────────────
  Future<void> _editProfile() async {
    final profile = _ps.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final ageCtrl = TextEditingController(text: profile.age?.toString() ?? '');
    final heightCtrl = TextEditingController(text: profile.heightCm?.toInt().toString() ?? '');
    final weightCtrl = TextEditingController(text: profile.weightKg?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Edytuj profil', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Imię i nazwisko',
                  prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wiek',
                  suffixText: 'lat', prefixIcon: Icon(Icons.cake_outlined)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wzrost',
                  suffixText: 'cm', prefixIcon: Icon(Icons.height)))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Waga',
                suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight_outlined))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              profile.name = nameCtrl.text.trim();
              profile.age = int.tryParse(ageCtrl.text);
              profile.heightCm = double.tryParse(heightCtrl.text);
              profile.weightKg = double.tryParse(weightCtrl.text);
              await _ps.save(profile);
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          )),
        ]),
      ),
    );
  }

  // ── Ustawienia ────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _SettingsSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Ustawienia – połączone z SettingsService
// ═══════════════════════════════════════════════════════════════

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  static const _accentColors = [
    Color(0xFFE94560), // czerwony (domyślny)
    Color(0xFF6C63FF), // fioletowy
    Color(0xFF00BCD4), // cyjan
    Color(0xFF4CAF50), // zielony
    Color(0xFFFF9800), // pomarańczowy
    Color(0xFFE91E63), // różowy
    Color(0xFF2196F3), // niebieski
    Color(0xFF795548), // brązowy
  ];

  static const _themeOptions = [
    (ThemeMode.dark,   'Ciemny',    Icons.dark_mode_outlined),
    (ThemeMode.light,  'Jasny',     Icons.light_mode_outlined),
    (ThemeMode.system, 'Systemowy', Icons.settings_suggest_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (ctx, _) {
        final accent = s.accentColor;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (ctx2, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              Text('Ustawienia', style: Theme.of(ctx2).textTheme.titleLarge),
              const SizedBox(height: 24),

              // ── Kolor akcentu ─────────────────────────────
              _SettingsSection(
                icon: Icons.color_lens_outlined,
                title: 'Kolor akcentu',
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _accentColors.map((c) {
                      final selected = c.toARGB32() == accent.toARGB32();
                      return GestureDetector(
                        onTap: () => s.setAccentColor(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: selected
                                ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 10)]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Motyw ─────────────────────────────────────
              _SettingsSection(
                icon: Icons.dark_mode_outlined,
                title: 'Motyw aplikacji',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: _themeOptions.map((opt) {
                      final (mode, label, icon) = opt;
                      final selected = s.themeMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => s.setThemeMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: opt != _themeOptions.last ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? accent : Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                  color: selected ? Colors.white : AppTheme.textSecond,
                                  size: 20),
                                const SizedBox(height: 4),
                                Text(label,
                                  style: TextStyle(
                                    color: selected ? Colors.white : AppTheme.textSecond,
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Jednostki masy ────────────────────────────
              _SettingsSection(
                icon: Icons.scale_outlined,
                title: 'Jednostki masy',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    _UnitChip(label: 'kg', selected: s.units == 'kg',
                        accent: accent, onTap: () => s.setUnits('kg')),
                    const SizedBox(width: 10),
                    _UnitChip(label: 'lbs', selected: s.units == 'lbs',
                        accent: accent, onTap: () => s.setUnits('lbs')),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── Powiadomienia ─────────────────────────────
              _SettingsSection(
                icon: Icons.notifications_outlined,
                title: 'Powiadomienia',
                subtitle: s.notificationsEnabled
                    ? 'Włączone – alert po każdej przerwie'
                    : 'Wyłączone',
                trailing: Switch(
                  value: s.notificationsEnabled,
                  activeColor: accent,
                  onChanged: (v) => s.setNotificationsEnabled(v),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Sekcja ustawień ──────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? trailing;
  const _SettingsSection({required this.icon, required this.title,
      this.subtitle, this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          if (trailing != null) trailing!,
        ]),
        if (child != null) child!,
      ]),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _UnitChip({required this.label, required this.selected,
      required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? accent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppTheme.textSecond,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      )),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Pomocnicze widgety profilu
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary)));
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoTile(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
      Text(value, style: const TextStyle(color: AppTheme.textSecond)),
    ]),
  );
}

class _GoalDisplay extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _GoalDisplay({required this.current, required this.onChanged});

  static const _goals = [
    ('mass',     'Budowa masy', Icons.trending_up),
    ('cut',      'Redukcja',   Icons.local_fire_department),
    ('strength', 'Siła',       Icons.fitness_center),
    ('cardio',   'Kondycja',   Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: _goals.map((g) {
        final sel = g.$1 == current;
        return GestureDetector(
          onTap: () => onChanged(g.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: sel ? accent.withValues(alpha: 0.15) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? accent : Colors.white10, width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(g.$3, color: sel ? accent : AppTheme.textSecond, size: 18),
              const SizedBox(width: 8),
              Text(g.$2, style: TextStyle(
                color: sel ? accent : AppTheme.textSecond,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double height, weight;
  const _BmiCard({required this.height, required this.weight});

  @override
  Widget build(BuildContext context) {
    final bmi = weight / ((height / 100) * (height / 100));
    final String status;
    final Color color;
    if (bmi < 18.5) { status = 'Niedowaga'; color = const Color(0xFF42A5F5); }
    else if (bmi < 25) { status = 'Prawidłowa waga ✓'; color = AppTheme.success; }
    else if (bmi < 30) { status = 'Nadwaga'; color = AppTheme.warning; }
    else { status = 'Otyłość'; color = Theme.of(context).colorScheme.primary; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bmi.toStringAsFixed(1),
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: color)),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BmiRange(label: '< 18.5',   desc: 'Niedowaga',    active: bmi < 18.5,             color: const Color(0xFF42A5F5)),
          _BmiRange(label: '18.5–24.9',desc: 'Prawidłowa',   active: bmi >= 18.5 && bmi < 25, color: AppTheme.success),
          _BmiRange(label: '25–29.9',  desc: 'Nadwaga',      active: bmi >= 25 && bmi < 30,   color: AppTheme.warning),
          _BmiRange(label: '≥ 30',     desc: 'Otyłość',      active: bmi >= 30,               color: Theme.of(context).colorScheme.primary),
        ])),
      ]),
    );
  }
}

class _BmiRange extends StatelessWidget {
  final String label, desc;
  final bool active;
  final Color color;
  const _BmiRange({required this.label, required this.desc,
      required this.active, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(
          color: active ? color : AppTheme.border(context),
          shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label  $desc',
          style: TextStyle(
            color: active ? color : AppTheme.textSec(context),
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// Kalkulator żywieniowy
// ═══════════════════════════════════════════════════════════════

class _NutritionCard extends StatelessWidget {
  final dynamic profile; // UserProfile
  final VoidCallback onQuestionnaireCompleted;
  const _NutritionCard({required this.profile, required this.onQuestionnaireCompleted});

  // Mapowanie celu profilu → klucz w NutritionService
  String _mapGoal(String profileGoal) {
    switch (profileGoal) {
      case 'mass':     return 'bulk';
      case 'cut':      return 'cut';
      case 'strength': return 'strength';
      case 'cardio':   return 'cardio';
      default:         return 'bulk';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ns = NutritionService.instance;
    final nutritionProfile = ns.profile;
    final accent = Theme.of(context).colorScheme.primary;
    final hasData = profile.weightKg != null &&
        profile.heightCm != null &&
        profile.age != null;

    // Liczymy tygodniową objętość (średnia z 4 tyg.)
    final weeklyVol = WorkoutService.instance.monthlyVolume / 4.0;

    // Obliczenia
    NutritionResult? result;
    if (hasData) {
      final goal = _mapGoal(profile.goal);
      result = ns.calculate(
        nutritionProfile: nutritionProfile,
        weightKg: profile.weightKg!,
        heightCm: profile.heightCm!,
        age: profile.age!,
        goal: goal,
        weeklyVolumeKg: weeklyVol,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Nagłówek row ──────────────────────────────────
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.restaurant_menu, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Zapotrzebowanie kaloryczne',
                style: Theme.of(context).textTheme.titleSmall),
            Text(
              result != null
                  ? '${NutritionService.goalLabel(_mapGoal(profile.goal))}  •  ${NutritionService.activityLabel(nutritionProfile.activityLevel)}'
                  : 'Uzupełnij ankietę, aby obliczyć',
              style: TextStyle(color: AppTheme.textSec(context), fontSize: 11),
            ),
          ])),
          TextButton(
            onPressed: () => _openQuestionnaire(context),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(result == null ? 'Ankieta' : 'Aktualizuj',
                style: const TextStyle(fontSize: 12)),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Informacja o brakujących danych profilu ───────
        if (!hasData)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.subtleOverlay(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppTheme.textSec(context), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Uzupełnij wiek, wzrost i wagę w edycji profilu, by wyliczyć kalorie.',
                style: TextStyle(color: AppTheme.textSec(context), fontSize: 12),
              )),
            ]),
          )

        // ── Wyniki ────────────────────────────────────────
        else if (result != null) ...[
          // Duże liczby kalorii
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${result.calories}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  height: 1.0,
                )),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text('kcal/dzień',
                  style: TextStyle(color: AppTheme.textSec(context), fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 4),
          Center(child: Text(
            'BMR: ${result.bmr.round()} kcal  •  TDEE: ${result.tdee.round()} kcal',
            style: TextStyle(color: AppTheme.textSec(context), fontSize: 11),
          )),
          const SizedBox(height: 18),

          // Makro paski
          _MacroBar(
            label: 'Białko',
            grams: result.protein,
            fraction: result.protein * 4 / result.calories,
            color: const Color(0xFF42A5F5),
          ),
          const SizedBox(height: 10),
          _MacroBar(
            label: 'Węglowodany',
            grams: result.carbs,
            fraction: result.carbs * 4 / result.calories,
            color: const Color(0xFFFFA726),
          ),
          const SizedBox(height: 10),
          _MacroBar(
            label: 'Tłuszcz',
            grams: result.fat,
            fraction: result.fat * 9 / result.calories,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 14),

          // Objętość treningowa info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.fitness_center, color: accent, size: 15),
              const SizedBox(width: 8),
              Text(
                'Śr. objętość treningowa: ${weeklyVol.toStringAsFixed(0)} kg/tydz.',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  void _openQuestionnaire(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NutritionQuestionnaireSheet(
        onSaved: onQuestionnaireCompleted,
      ),
    );
  }
}

// ── Pasek makroskładnika ─────────────────────────────────────

class _MacroBar extends StatelessWidget {
  final String label;
  final int grams;
  final double fraction;
  final Color color;
  const _MacroBar({required this.label, required this.grams,
      required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
        const Spacer(),
        Text('$grams g',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        Text('($pct%)',
            style: TextStyle(color: AppTheme.textSec(context), fontSize: 11)),
      ]),
      const SizedBox(height: 5),
      LayoutBuilder(builder: (ctx, constraints) {
        return Stack(children: [
          Container(
            height: 8, width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: AppTheme.subtleOverlay(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]);
      }),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Ankieta żywieniowa (2 kroki)
// ═══════════════════════════════════════════════════════════════

class _NutritionQuestionnaireSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _NutritionQuestionnaireSheet({required this.onSaved});

  @override
  State<_NutritionQuestionnaireSheet> createState() =>
      _NutritionQuestionnaireSheetState();
}

class _NutritionQuestionnaireSheetState
    extends State<_NutritionQuestionnaireSheet> {
  int _step = 0;
  final _profile = NutritionProfile(
    sex: NutritionService.instance.profile.sex,
    activityLevel: NutritionService.instance.profile.activityLevel,
  );

  static const _activities = [
    ('sedentary',  'Siedzący tryb życia', Icons.chair_outlined,
        'Mało lub brak ruchu – praca przy biurku'),
    ('light',      'Lekka aktywność', Icons.directions_walk,
        'Spacery, lekki sport 1-2 razy w tygodniu'),
    ('moderate',   'Umiarkowana', Icons.directions_bike,
        'Ćwiczenia 3-4 razy w tygodniu'),
    ('active',     'Aktywna', Icons.sports_handball,
        'Ciężkie treningi 5 razy w tygodniu'),
    ('veryActive', 'Bardzo aktywna', Icons.speed,
        'Codzienne intensywne treningi / praca fizyczna'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(children: [
          // Uchwyt
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border(context),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Pasek postępu
          Row(children: List.generate(2, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _step ? accent : AppTheme.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))),
          const SizedBox(height: 20),

          // Zawartość kroku
          Expanded(child: SingleChildScrollView(
            controller: scroll,
            child: _step == 0
                ? _buildSexStep(accent)
                : _buildActivityStep(accent),
          )),

          const SizedBox(height: 16),

          // Nawigacja
          Row(children: [
            if (_step > 0)
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Wstecz'),
              )),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _step == 0
                  ? () => setState(() => _step = 1)
                  : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_step == 0 ? 'Dalej' : 'Zapisz i oblicz'),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSexStep(Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Krok 1 z 2', style: TextStyle(
          color: AppTheme.textSec(context), fontSize: 12)),
      const SizedBox(height: 6),
      Text('Jaka jest Twoja płeć?',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text('Potrzebujemy tego do dokładniejszego obliczenia BMR.',
          style: TextStyle(color: AppTheme.textSec(context), fontSize: 13)),
      const SizedBox(height: 24),
      Row(children: [
        _SexTile(
          label: 'Mężczyzna',
          icon: Icons.male,
          selected: _profile.sex == 'male',
          accent: accent,
          onTap: () => setState(() => _profile.sex = 'male'),
        ),
        const SizedBox(width: 14),
        _SexTile(
          label: 'Kobieta',
          icon: Icons.female,
          selected: _profile.sex == 'female',
          accent: accent,
          onTap: () => setState(() => _profile.sex = 'female'),
        ),
      ]),
    ]);
  }

  Widget _buildActivityStep(Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Krok 2 z 2', style: TextStyle(
          color: AppTheme.textSec(context), fontSize: 12)),
      const SizedBox(height: 6),
      Text('Poziom aktywności fizycznej',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text('Uwzględnij aktywność poza siłownią (praca, spacery).',
          style: TextStyle(color: AppTheme.textSec(context), fontSize: 13)),
      const SizedBox(height: 20),
      ..._activities.map((a) {
        final sel = _profile.activityLevel == a.$1;
        return GestureDetector(
          onTap: () => setState(() => _profile.activityLevel = a.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: sel ? accent.withValues(alpha: 0.1) : AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? accent : AppTheme.border(context),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(a.$3, color: sel ? accent : AppTheme.textSec(context), size: 24),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.$2, style: TextStyle(
                  color: sel
                      ? accent
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                )),
                const SizedBox(height: 2),
                Text(a.$4, style: TextStyle(
                    color: AppTheme.textSec(context), fontSize: 12)),
              ])),
              if (sel)
                Icon(Icons.check_circle, color: accent, size: 20),
            ]),
          ),
        );
      }),
    ]);
  }

  Future<void> _save() async {
    await NutritionService.instance.save(_profile);
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }
}

// ── Kafelek płci ─────────────────────────────────────────────

class _SexTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _SexTile({required this.label, required this.icon, required this.selected,
      required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : AppTheme.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon, size: 44, color: selected ? accent : AppTheme.textSec(context)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(
            color: selected ? accent : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          )),
          if (selected) ...[
            const SizedBox(height: 6),
            Icon(Icons.check_circle, color: accent, size: 18),
          ],
        ]),
      ),
    ),
  );
}

