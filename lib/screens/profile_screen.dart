import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          TextButton(
            onPressed: _editProfile,
            child: const Text('Edytuj', style: TextStyle(color: AppTheme.accent)),
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
                      style: const TextStyle(
                        color: AppTheme.accent, fontSize: 42, fontWeight: FontWeight.bold))
                  : const Icon(Icons.person, size: 52, color: AppTheme.accent),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.accent, shape: BoxShape.circle),
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
        ]),
      ),
    );
  }

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
}

// ── Pomocnicze widgety ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppTheme.accent)));
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
      Icon(icon, color: AppTheme.accent, size: 20),
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
    ('mass', 'Budowa masy', Icons.trending_up),
    ('cut', 'Redukcja', Icons.local_fire_department),
    ('strength', 'Siła', Icons.fitness_center),
    ('cardio', 'Kondycja', Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
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
            color: sel ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppTheme.accent : Colors.white10, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(g.$3, color: sel ? AppTheme.accent : AppTheme.textSecond, size: 18),
            const SizedBox(width: 8),
            Text(g.$2, style: TextStyle(
              color: sel ? AppTheme.accent : AppTheme.textSecond,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13)),
          ]),
        ),
      );
    }).toList(),
  );
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
    else { status = 'Otyłość'; color = AppTheme.accent; }

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
          _BmiRange(label: '< 18.5', desc: 'Niedowaga', active: bmi < 18.5, color: const Color(0xFF42A5F5)),
          _BmiRange(label: '18.5–24.9', desc: 'Prawidłowa', active: bmi >= 18.5 && bmi < 25, color: AppTheme.success),
          _BmiRange(label: '25–29.9', desc: 'Nadwaga', active: bmi >= 25 && bmi < 30, color: AppTheme.warning),
          _BmiRange(label: '≥ 30', desc: 'Otyłość', active: bmi >= 30, color: AppTheme.accent),
        ])),
      ]),
    );
  }
}

class _BmiRange extends StatelessWidget {
  final String label, desc;
  final bool active;
  final Color color;
  const _BmiRange({required this.label, required this.desc, required this.active, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(
          color: active ? color : Colors.white12,
          shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label  $desc',
          style: TextStyle(
            color: active ? color : AppTheme.textSecond,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ]),
  );
}
