import 'package:flutter/material.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  List<Map<String, dynamic>> appointments = [
    {
      "patient": {
        "name": "John Smith",
        "age": "52",
        "bloodGroup": "A+",
        "diagnosis": "Stage II Lung Cancer",
        "conditions": "Hypertension",
        "allergies": "Penicillin",
        "medications": "Amlodipine",
        "notes": "Patient responding well to chemotherapy.",
        "prescriptions": [],
        "reports": [],
      },
      "date": DateTime.now(),
      "time": const TimeOfDay(hour: 10, minute: 0),
      "status": "Pending",
    },
    {
      "patient": {
        "name": "Emily Johnson",
        "age": "45",
        "bloodGroup": "B+",
        "diagnosis": "Breast Cancer",
        "conditions": "Diabetes",
        "allergies": "None",
        "medications": "Metformin",
        "notes": "Monitoring blood sugar levels.",
        "prescriptions": [],
        "reports": [],
      },
      "date": DateTime.now().add(const Duration(days: 2)),
      "time": const TimeOfDay(hour: 14, minute: 30),
      "status": "Pending",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // 🔹 STATISTICS
  int get totalCount => appointments.length;
  int get todayCount =>
      appointments.where((a) => isSameDay(a["date"], DateTime.now())).length;
  int get completedCount =>
      appointments.where((a) => a["status"] == "Completed").length;
  int get cancelledCount =>
      appointments.where((a) => a["status"] == "Cancelled").length;
  int get pendingCount =>
      appointments.where((a) => a["status"] == "Pending").length;

  // 🔹 FILTER + SEARCH
  List<Map<String, dynamic>> getFilteredAppointments(String filter) {
    DateTime today = DateTime.now();
    List<Map<String, dynamic>> filtered;

    switch (filter) {
      case "Today":
        filtered = appointments
            .where((a) => isSameDay(a["date"], today) && a["status"] == "Pending")
            .toList();
        break;
      case "Upcoming":
        filtered = appointments
            .where((a) => a["date"].isAfter(today) && a["status"] == "Pending")
            .toList();
        break;
      case "Completed":
        filtered = appointments.where((a) => a["status"] == "Completed").toList();
        break;
      case "Cancelled":
        filtered = appointments.where((a) => a["status"] == "Cancelled").toList();
        break;
      default:
        filtered = appointments;
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((a) => a["patient"]["name"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void markAsCompleted(int index) {
    setState(() {
      appointments[index]["status"] = "Completed";
    });
  }

  void cancelAppointment(int index) {
    setState(() {
      appointments[index]["status"] = "Cancelled";
    });
  }

  Future<void> rescheduleAppointment(int index) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: appointments[index]["date"],
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (newDate == null) return;

    if (!mounted) return;
    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: appointments[index]["time"],
    );
    if (newTime == null) return;

    setState(() {
      appointments[index]["date"] = newDate;
      appointments[index]["time"] = newTime;
      appointments[index]["status"] = "Pending";
    });
  }

  Widget buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppointmentList(String filter) {
    final filtered = getFilteredAppointments(filter);

    if (filtered.isEmpty) {
      return const Center(child: Text("No appointments found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final appointment = filtered[index];
        final originalIndex = appointments.indexOf(appointment);
        final status = appointment["status"] as String;
        final date = appointment["date"] as DateTime;
        final time = appointment["time"] as TimeOfDay;
        final patient = appointment["patient"];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              // Navigation to patient details removed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View details for ${patient["name"]}')),
              );
            },
            leading: const Icon(Icons.event),
            title: Text(patient["name"]),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${date.day}/${date.month}/${date.year} at ${time.format(context)}"),
                const SizedBox(height: 4),
                Text(
                  "Status: $status",
                  style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: status == "Cancelled"
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "Complete") {
                        markAsCompleted(originalIndex);
                      } else if (value == "Reschedule") {
                        rescheduleAppointment(originalIndex);
                      } else if (value == "Cancel") {
                        cancelAppointment(originalIndex);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "Complete", child: Text("Mark as Completed")),
                      PopupMenuItem(value: "Reschedule", child: Text("Reschedule")),
                      PopupMenuItem(
                        value: "Cancel",
                        child: Text("Cancel", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointments"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Today"),
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔎 SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search patient...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // 🔹 STATISTICS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    buildStatCard("Total", totalCount, Colors.blue),
                    buildStatCard("Today", todayCount, Colors.orange),
                  ],
                ),
                Row(
                  children: [
                    buildStatCard("Pending", pendingCount, Colors.orange),
                    buildStatCard("Completed", completedCount, Colors.green),
                    buildStatCard("Cancelled", cancelledCount, Colors.red),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildAppointmentList("All"),
                buildAppointmentList("Today"),
                buildAppointmentList("Upcoming"),
                buildAppointmentList("Completed"),
                buildAppointmentList("Cancelled"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
