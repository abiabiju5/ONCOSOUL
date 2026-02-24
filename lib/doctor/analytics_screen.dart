import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

class DoctorAnalyticsScreen extends StatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  State<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends State<DoctorAnalyticsScreen> {
  static const Color _blue = Color(0xFF0D47A1);
  static const Color _bg = Color(0xFFF0F4FF);

  final _service = DoctorService();

  bool _loading = true;
  String? _error;

  List<AppointmentDataPoint> _weeklyPoints = [];
  double _completionRate = 0;
  List<MapEntry<String, int>> _topPatients = [];
  Map<String, int> _statusBreakdown = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.appointmentsPerDayPoints(7),
        _service.completionRate(),
        _service.topPatients(5),
        _service.fetchDashboardStats(),
      ]);
      setState(() {
        _weeklyPoints = results[0] as List<AppointmentDataPoint>;
        _completionRate = results[1] as double;
        _topPatients = results[2] as List<MapEntry<String, int>>;
        final stats = results[3] as Map<String, int>;
        _statusBreakdown = {
          'Pending': stats['pending'] ?? 0,
          'Completed': stats['completed'] ?? 0,
          'Cancelled': stats['cancelled'] ?? 0,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load analytics',
                          style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _blue,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Completion Rate ──────────────────────────────────
                      _sectionTitle('Completion Rate'),
                      const SizedBox(height: 10),
                      _completionCard(),
                      const SizedBox(height: 24),

                      // ── Status Breakdown ─────────────────────────────────
                      _sectionTitle('Appointment Status Breakdown'),
                      const SizedBox(height: 10),
                      _statusBreakdownCard(),
                      const SizedBox(height: 24),

                      // ── Weekly Trend ─────────────────────────────────────
                      _sectionTitle('Appointments — Last 7 Days'),
                      const SizedBox(height: 10),
                      _weeklyTrendCard(),
                      const SizedBox(height: 24),

                      // ── Top Patients ─────────────────────────────────────
                      _sectionTitle('Top Patients (by visits)'),
                      const SizedBox(height: 10),
                      _topPatientsCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800),
      );

  Widget _completionCard() {
    final pct = (_completionRate * 100).toStringAsFixed(1);
    return _card(
      child: Row(children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: _completionRate,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            Text('$pct%',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Appointments Completed',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
                '$pct% of all your appointments have been marked as completed.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 3),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBreakdownCard() {
    final colors = {
      'Pending': Colors.orange,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
    };
    final icons = {
      'Pending': Icons.hourglass_bottom_rounded,
      'Completed': Icons.check_circle_rounded,
      'Cancelled': Icons.cancel_rounded,
    };
    return _card(
      child: Column(
        children: _statusBreakdown.entries.map((e) {
          final color = colors[e.key] ?? Colors.blue;
          final icon = icons[e.key] ?? Icons.info_rounded;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(e.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.value.toString(),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _weeklyTrendCard() {
    if (_weeklyPoints.isEmpty) {
      return _card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No data for this period.',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    final maxVal = _weeklyPoints.map((p) => p.count).fold(0, (a, b) => a > b ? a : b);

    return _card(
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyPoints.map((point) {
                final fraction = maxVal == 0 ? 0.0 : point.count / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(point.count.toString(),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: fraction * 90 + (point.count > 0 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(point.label,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topPatientsCard() {
    if (_topPatients.isEmpty) {
      return _card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No patient data available.',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return _card(
      child: Column(
        children: _topPatients.asMap().entries.map((entry) {
          final idx = entry.key;
          final patient = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _blue.withAlpha(30),
                child: Text('${idx + 1}',
                    style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(patient.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
              ),
              Text('${patient.value} visit${patient.value == 1 ? '' : 's'}',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}