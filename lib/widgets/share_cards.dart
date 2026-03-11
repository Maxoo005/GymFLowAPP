import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gymapp/theme/app_theme.dart';
import 'package:gymapp/models/workout.dart';
import 'package:gymapp/services/share_service.dart';

/// Piękny plakat do udostępnienia z informacji o planie treningowym
class PlanShareCard extends StatelessWidget {
  final WorkoutPlan plan;

  const PlanShareCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    // Obliczanie objętości
    int totalSets = 0;
    int totalExercises = plan.exercises.length;
    final Map<String, int> muscleGroups = {};

    for (var ex in plan.exercises) {
      totalSets += ex.entries.length;
      final muscleName = ex.muscleGroupName ?? 'Inne';
      muscleGroups[muscleName] = (muscleGroups[muscleName] ?? 0) + ex.entries.length;
    }

    final sortedMuscles = muscleGroups.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: 1080 / 3, // Prawdziwa rozdzielczość "Insta Story" będzie wielokrotnością tych wymiarów po pixelRatio=3
      height: 1920 / 3,
      decoration: const BoxDecoration(
        color: Color(0xFF10121A),
        image: DecorationImage(
          image: AssetImage('assets/images/mesh_bg.png'), // Użyjemy domyślnego noise mesh lub po prostu ładny kolor i gradient
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Stack(
        children: [
          // Background Gradient Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6A4DFF).withValues(alpha: 0.2), // Fioletowe podświetlenie
              ),
            ),
          ),
          // Backdrop filter blur na całości żeby zgubić twarde krawędzie
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, color: AppTheme.accent, size: 28),
                      SizedBox(width: 12),
                      Text("GYMLOOM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2)),
                    ],
                  ),
                  const Spacer(flex: 2),
                  const Text("MÓJ NOWY PLAN", style: TextStyle(color: AppTheme.textSecond, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 32),
                  
                  // Stats w ładnych bąbelkach
                  Row(
                    children: [
                      _StatBubble(title: "Ćwiczeń", value: totalExercises.toString(), icon: Icons.format_list_bulleted),
                      const SizedBox(width: 16),
                      _StatBubble(title: "Serii", value: totalSets.toString(), icon: Icons.repeat),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (plan.exercises.isNotEmpty) ...[
                    const Text("ĆWICZENIA:", style: TextStyle(color: AppTheme.textSecond, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ...plan.exercises.take(4).map((ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(ex.exerciseName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text("${ex.entries.length} serie", style: const TextStyle(color: AppTheme.accent, fontSize: 14)),
                        ],
                      ),
                    )),
                    if (plan.exercises.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("+ ${plan.exercises.length - 4} więcej...", style: const TextStyle(color: AppTheme.textSecond, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                  ],

                  const Spacer(flex: 2),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Center(
                      child: Text("Zbuduj własny na GymLoom", style: TextStyle(color: AppTheme.textSecond, fontSize: 14)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatBubble({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppTheme.textSecond, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// Piękny plakat Nowego Rekordu do udostępnienia
class RecordShareCard extends StatelessWidget {
  final String exerciseName;
  final double weight;
  final DateTime date;

  const RecordShareCard({
    super.key,
    required this.exerciseName,
    required this.weight,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080 / 3,
      height: 1920 / 3,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0A12), // Mega ciemny fiolet
      ),
      child: Stack(
        children: [
          // Tło (glow)
           Positioned(
            top: 200,
            left: -150,
            right: -150,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.4),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text("GYMLOOM", style: TextStyle(color: AppTheme.textSecond, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3)),
                  const Spacer(flex: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                    ),
                    child: const Text("🔥 NOWY REKORD!", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 32),
                  Text(exerciseName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1), style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold, height: 1)),
                      const SizedBox(width: 8),
                      const Text("kg", style: TextStyle(color: AppTheme.textSecond, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Text("${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}", style: const TextStyle(color: AppTheme.textSecond, fontSize: 16, letterSpacing: 2)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Dialog Wrapper pozwala na natychmiastowe pokazanie gotowej grafiki uzytkownikowi po czym wygenerowanie screena ukrytego RenderRepaintBoundary
class SharePreviewDialog extends StatefulWidget {
  final Widget cardWidget;
  final String shareFileName;

  const SharePreviewDialog({super.key, required this.cardWidget, required this.shareFileName});

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  void _share() async {
    setState(() => _isSharing = true);
    try {
      // Wykorzystaj boundary do wykonania ss i otwarcia okienka share_plus
      await ShareService.shareWidget(_globalKey, widget.shareFileName);
      if (mounted) {
        Navigator.pop(context); // Zamknij okienko po pomyślnym wysłaniu
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Widoczny na ekranie podgląd jest opakowany w Clippera z border radiusem (grafika sama w sobie ma ostre kąty bo idzie na insta)
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _globalKey,
                  child: widget.cardWidget,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isSharing 
              ? const CircularProgressIndicator(color: AppTheme.accent)
              : ElevatedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.ios_share),
                label: const Text("Udostępnij zrzut", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
               child: const Text("Anuluj", style: TextStyle(color: AppTheme.textSecond)),
            )
          ],
        ),
      ),
    );
  }
}
