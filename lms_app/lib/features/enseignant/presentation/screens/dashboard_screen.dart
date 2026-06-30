import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/dashboard/enseignant');  // ← corrigé, était '/dashboard'
  return response.data;
});
final graphTypeProvider = StateProvider<String>((ref) => 'bar');

// ── Design tokens ──
class _AppColors {
  static const bg = Color(0xFFF8F8F6);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB8B8B8);
  static const border = Color(0xFFF0F0EE);

  static const statBlue = Color(0xFFE8F1FB);
  static const statBlueText = Color(0xFF1A5FA8);
  static const statBlueAccent = Color(0xFF3B8DDD);

  static const statGreen = Color(0xFFE8F5EE);
  static const statGreenText = Color(0xFF1A6B3C);
  static const statGreenAccent = Color(0xFF2EA862);

  static const statAmber = Color(0xFFFAF0DC);
  static const statAmberText = Color(0xFF8A5A0A);
  static const statAmberAccent = Color(0xFFEA9F25);

  static const statPurple = Color(0xFFEEEDFE);
  static const statPurpleText = Color(0xFF4A3FB5);
  static const statPurpleAccent = Color(0xFF7F77DD);

  static const chartBlue = Color(0xFF3B8DDD);
  static const chartGreen = Color(0xFF2EA862);
  static const chartAmber = Color(0xFFEA9F25);
  static const chartPurple = Color(0xFF7F77DD);
  static const chartCoral = Color(0xFFD85A30);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Ouvre le bottom sheet de notifications ──
  void _openNotifSheet(List<Map<String, dynamic>> notifs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotifBottomSheet(notifs: notifs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final graphType = ref.watch(graphTypeProvider);

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: _AppColors.textPrimary,
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Color(0xFFE24B4A), size: 26),
                ),
                const SizedBox(height: 16),
                Text('Erreur de chargement',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Vérifiez votre connexion',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: _AppColors.textSecondary)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => ref.refresh(dashboardProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Réessayer',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          data: (data) {
            final stats = data['statsGlobales'];
            final histogramme =
                List<Map<String, dynamic>>.from(data['donneesHistogramme']);
            final topCours =
                List<Map<String, dynamic>>.from(data['topCours']);
            final courbeData =
                List<Map<String, dynamic>>.from(data['courbeData']);
            final activiteRecente =
                List<Map<String, dynamic>>.from(data['activiteRecente'] ?? []);
            final notifications =
                List<Map<String, dynamic>>.from(data['notifications'] ?? []);

            return RefreshIndicator(
              onRefresh: () async {
                _entryController.reset();
                await ref.refresh(dashboardProvider.future);
                _entryController.forward();
              },
              color: _AppColors.textPrimary,
              backgroundColor: Colors.white,
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Dashboard',
                                style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 26,
                                    color: _AppColors.textPrimary,
                                    fontStyle: FontStyle.italic),
                              ),
                              // Bouton notification → ouvre bottom sheet
                              GestureDetector(
                                onTap: () => _openNotifSheet(notifications),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _AppColors.border, width: 1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.notifications_outlined,
                                        size: 18,
                                        color: _AppColors.textPrimary,
                                      ),
                                      if (notifications.isNotEmpty)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE24B4A),
                                              shape: BoxShape.circle,
                                            ),
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

                        // ── Stat cards ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ColoredStatCard(
                                      label: 'Cours publiés',
                                      value: stats['totalPublies'].toString(),
                                      icon: Icons.play_circle_outline_rounded,
                                      bgColor: _AppColors.statBlue,
                                      textColor: _AppColors.statBlueText,
                                      accentColor: _AppColors.statBlueAccent,
                                      sparklineValues: const [3, 5, 4, 7, 6, 8, 9],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ColoredStatCard(
                                      label: 'Apprenants',
                                      value: stats['totalInscrits'].toString(),
                                      icon: Icons.people_outline_rounded,
                                      bgColor: _AppColors.statGreen,
                                      textColor: _AppColors.statGreenText,
                                      accentColor: _AppColors.statGreenAccent,
                                      sparklineValues: const [10, 14, 12, 18, 20, 22, 28],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ColoredStatCard(
                                      label: 'Brouillons',
                                      value: stats['totalBrouillons'].toString(),
                                      icon: Icons.edit_outlined,
                                      bgColor: _AppColors.statAmber,
                                      textColor: _AppColors.statAmberText,
                                      accentColor: _AppColors.statAmberAccent,
                                      sparklineValues: const [2, 3, 2, 4, 3, 5, 3],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ColoredStatCard(
                                      label: 'Complétion',
                                      value: '${stats['tauxCompletion']}%',
                                      icon: Icons.check_circle_outline_rounded,
                                      bgColor: _AppColors.statPurple,
                                      textColor: _AppColors.statPurpleText,
                                      accentColor: _AppColors.statPurpleAccent,
                                      sparklineValues: const [40, 50, 55, 60, 65, 72, 78],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Section Statistiques ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Statistiques',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _AppColors.textPrimary)),
                                      Text('Apprenants par cours',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color: _AppColors.textSecondary)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: _AppColors.bg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildGraphBtn(ref, 'bar', Icons.bar_chart),
                                        _buildGraphBtn(ref, 'donut', Icons.donut_large),
                                        _buildGraphBtn(ref, 'line', Icons.show_chart),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 190,
                                child: histogramme.isEmpty
                                    ? Center(
                                        child: Text('Aucune donnée',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                color: _AppColors.textTertiary)))
                                    : AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 350),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: ScaleTransition(
                                                scale: Tween(begin: 0.96, end: 1.0)
                                                    .animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: graphType == 'bar'
                                            ? _buildBarChart(histogramme,
                                                key: const ValueKey('bar'))
                                            : graphType == 'donut'
                                                ? _buildDonutChart(histogramme,
                                                    key: const ValueKey('donut'))
                                                : _buildLineChart(courbeData,
                                                    key: const ValueKey('line')),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Top cours ──
                        if (topCours.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Top cours',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _AppColors.textPrimary)),
                                Text('Voir tout',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: _AppColors.statBlueAccent,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...topCours.asMap().entries.map((entry) {
                            return _AnimatedListItem(
                              delay: entry.key * 70,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                                child: _buildTopCoursCard(entry.value, entry.key + 1),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        // ── Activité récente ──
                        if (activiteRecente.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Activité récente',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _AppColors.textPrimary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1FB),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${activiteRecente.length} nouveaux',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: _AppColors.statBlueText,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...activiteRecente.asMap().entries.map((entry) {
                            return _AnimatedListItem(
                              delay: entry.key * 50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                                child: _buildActiviteCard(entry.value),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGraphBtn(WidgetRef ref, String type, IconData icon) {
    final current = ref.watch(graphTypeProvider);
    final isActive = current == type;
    return GestureDetector(
      onTap: () => ref.read(graphTypeProvider.notifier).state = type,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Icon(icon,
            size: 16,
            color: isActive ? _AppColors.textPrimary : _AppColors.textTertiary),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, {Key? key}) {
    final chartColors = [
      _AppColors.chartBlue,
      _AppColors.chartGreen,
      _AppColors.chartAmber,
      _AppColors.chartPurple,
      _AppColors.chartCoral,
    ];
    final maxVal = data.fold(0.0,
            (max, d) => (d['inscrits'] as int).toDouble() > max
                ? (d['inscrits'] as int).toDouble()
                : max) +
        2;

    return BarChart(
      key: key,
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex]['titreCours']}\n${rod.toY.toInt()}',
                GoogleFonts.dmSans(fontSize: 11, color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox();
                final title = data[value.toInt()]['titreCours'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    title.length > 5 ? '${title.substring(0, 5)}…' : title,
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: _AppColors.textTertiary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: _AppColors.textTertiary),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: _AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final color = chartColors[entry.key % chartColors.length];
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['inscrits'] as int).toDouble(),
                color: color,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonutChart(List<Map<String, dynamic>> data, {Key? key}) {
    final colors = [
      _AppColors.chartBlue,
      _AppColors.chartGreen,
      _AppColors.chartAmber,
      _AppColors.chartPurple,
      _AppColors.chartCoral,
    ];
    final total = data.fold(0, (sum, d) => sum + (d['inscrits'] as int));

    return Row(
      key: key,
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              sections: data.asMap().entries.map((entry) {
                final value = (entry.value['inscrits'] as int).toDouble();
                final percentage =
                    total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
                return PieChartSectionData(
                  color: colors[entry.key % colors.length],
                  value: value == 0 ? 0.1 : value,
                  title: '$percentage%',
                  radius: 42,
                  titleStyle: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value['titreCours'],
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: _AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.value['inscrits']}',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, {Key? key}) {
    if (data.isEmpty) {
      return Center(
        key: key,
        child: Text('Aucune donnée',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: _AppColors.textTertiary)),
      );
    }

    return LineChart(
      key: key,
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((spot) => LineTooltipItem(
                      '${data[spot.x.toInt()]['mois']}: ${spot.y.toInt()}',
                      GoogleFonts.dmSans(fontSize: 11, color: Colors.white),
                    ))
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: _AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox();
                final mois = data[value.toInt()]['mois'] as String;
                final parts = mois.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    parts.length > 1 ? parts[1] : mois,
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: _AppColors.textTertiary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: _AppColors.textTertiary),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(
                    e.key.toDouble(), (e.value['inscrits'] as int).toDouble()))
                .toList(),
            isCurved: true,
            color: _AppColors.chartBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: _AppColors.chartBlue,
                strokeWidth: 2.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _AppColors.chartBlue.withValues(alpha: 0.12),
                  _AppColors.chartBlue.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
      ),
    );
  }

  Widget _buildTopCoursCard(Map<String, dynamic> cours, int rank) {
    final rankData = [
      {'color': const Color(0xFFFAF0DC), 'text': const Color(0xFF8A5A0A), 'label': '🥇'},
      {'color': const Color(0xFFF1F0EE), 'text': const Color(0xFF5F5E5A), 'label': '🥈'},
      {'color': const Color(0xFFFAECE7), 'text': const Color(0xFF8A3A1A), 'label': '🥉'},
    ];
    final rd = rankData[rank - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: rd['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(rd['label'] as String,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cours['titreCours'],
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${cours['inscrits']} apprenants · ${cours['modules']} modules',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: _AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cours['statut'] == 'PUBLIE'
                  ? const Color(0xFFE8F5EE)
                  : const Color(0xFFFAF0DC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cours['statut'] == 'PUBLIE' ? 'Publié' : 'Brouillon',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cours['statut'] == 'PUBLIE'
                      ? _AppColors.statGreenText
                      : _AppColors.statAmberText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiviteCard(Map<String, dynamic> item) {
    final typeConfig = {
      'INSCRIPTION': {
        'icon': Icons.person_add_outlined,
        'bg': const Color(0xFFEEEDFE),
        'color': _AppColors.statPurpleText,
      },
      'COMPLETION': {
        'icon': Icons.check_circle_outline,
        'bg': const Color(0xFFE8F5EE),
        'color': _AppColors.statGreenText,
      },
      'NOUVEAU_COURS': {
        'icon': Icons.library_add_outlined,
        'bg': const Color(0xFFE8F1FB),
        'color': _AppColors.statBlueText,
      },
      'MODULE_COMPLETE': {
        'icon': Icons.menu_book_outlined,
        'bg': const Color(0xFFFAF0DC),
        'color': _AppColors.statAmberText,
      },
    };
    final type = item['type'] as String? ?? 'INSCRIPTION';
    final config = typeConfig[type] ?? typeConfig['INSCRIPTION']!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config['bg'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config['icon'] as IconData,
                size: 17, color: config['color'] as Color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['message'] ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(item['titreCours'] ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: _AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item['temps'] ?? '',
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: _AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Colored stat card with mini sparkline ──
class _ColoredStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color accentColor;
  final List<double> sparklineValues;

  const _ColoredStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.accentColor,
    required this.sparklineValues,
  });

  @override
  State<_ColoredStatCard> createState() => _ColoredStatCardState();
}

class _ColoredStatCardState extends State<_ColoredStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _countAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _animatedValue(double progress) {
    final raw = widget.value
        .replaceAll('%', '')
        .replaceAll(RegExp(r'[^0-9]'), '');
    final target = int.tryParse(raw) ?? 0;
    final current = (target * progress).round();
    return widget.value.contains('%') ? '$current%' : current.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(widget.icon, size: 16, color: widget.accentColor),
              ),
              SizedBox(
                width: 44,
                height: 24,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: widget.sparklineValues,
                    color: widget.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _countAnim,
            builder: (context, _) => Text(
              _animatedValue(_countAnim.value),
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                color: widget.textColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(widget.label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: widget.textColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ── Mini sparkline painter ──
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = ((i - 1) / (values.length - 1)) * size.width;
        final prevY =
            size.height - ((values[i - 1] - min) / range) * size.height;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// ── Animated list item ──
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedListItem({required this.child, required this.delay});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Notification Bottom Sheet ──
// S'affiche depuis le bas de l'écran via showModalBottomSheet
class _NotifBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> notifs;

  const _NotifBottomSheet({required this.notifs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Titre ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Notifications',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _AppColors.textPrimary)),
                        if (notifs.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${notifs.length}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _AppColors.statBlueText,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: _AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: _AppColors.border),

              // ── Corps scrollable ──
              Expanded(
                child: notifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _AppColors.bg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                  Icons.notifications_off_outlined,
                                  size: 24,
                                  color: _AppColors.textTertiary),
                            ),
                            const SizedBox(height: 12),
                            Text('Aucune notification',
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: _AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: _AppColors.border),
                        itemBuilder: (context, i) {
                          final notif = notifs[i];
                          final typeConfig = {
                            'INSCRIPTION': {
                              'icon': Icons.person_add_outlined,
                              'bg': const Color(0xFFEEEDFE),
                              'color': _AppColors.statPurpleText,
                            },
                            'COMPLETION': {
                              'icon': Icons.check_circle_outline,
                              'bg': const Color(0xFFE8F5EE),
                              'color': _AppColors.statGreenText,
                            },
                            'NOUVEAU_COURS': {
                              'icon': Icons.library_add_outlined,
                              'bg': const Color(0xFFE8F1FB),
                              'color': _AppColors.statBlueText,
                            },
                          };
                          final type =
                              notif['type'] as String? ?? 'INSCRIPTION';
                          final config =
                              typeConfig[type] ?? typeConfig['INSCRIPTION']!;
                          final isUnread = notif['lu'] == false;

                          return Container(
                            color: isUnread
                                ? _AppColors.bg
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: config['bg'] as Color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(config['icon'] as IconData,
                                      size: 18,
                                      color: config['color'] as Color),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(notif['message'] ?? '',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              fontWeight: isUnread
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                              color: _AppColors.textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text(notif['temps'] ?? '',
                                          style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: _AppColors.textTertiary)),
                                    ],
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(
                                        top: 6, left: 8),
                                    decoration: const BoxDecoration(
                                      color: _AppColors.statPurpleAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // ── Footer ──
              if (notifs.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Tout marquer comme lu',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}