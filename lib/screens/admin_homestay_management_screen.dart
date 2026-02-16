import 'package:flutter/material.dart';
import '../models/homestay_model.dart';

class AdminHomestayManagementScreen extends StatefulWidget {
  const AdminHomestayManagementScreen({super.key});

  @override
  State<AdminHomestayManagementScreen> createState() =>
      _AdminHomestayManagementScreenState();
}

class _AdminHomestayManagementScreenState
    extends State<AdminHomestayManagementScreen> {

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final rateController = TextEditingController();

  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestay Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Homestay Name'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: locationController,
              decoration:
                  const InputDecoration(labelText: 'Location (Address)'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Contact Number'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Rate (₹ per day)'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Latitude'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: lngController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Longitude'),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                ),
                onPressed: addHomestay,
                child: const Text(
                  'Add Homestay',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: HomestayData.homestays.length,
                itemBuilder: (context, index) {
                  final stay = HomestayData.homestays[index];

                  return Card(
                    child: ListTile(
                      title: Text(stay.name),
                      subtitle: Text(
                        '${stay.location}\n'
                        'Contact: ${stay.contact}\n'
                        'Rate: ₹${stay.rate.toStringAsFixed(0)} / day',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            HomestayData.homestays.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addHomestay() {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty ||
        latController.text.isEmpty ||
        lngController.text.isEmpty ||
        rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    try {
      final double latitude = double.parse(latController.text);
      final double longitude = double.parse(lngController.text);
      final double rate = double.parse(rateController.text);

      setState(() {
        HomestayData.homestays.add(
          Homestay(
            name: nameController.text,
            location: locationController.text,
            contact: contactController.text,
            lat: latitude,
            lng: longitude,
            rate: rate,
          ),
        );
      });

      nameController.clear();
      locationController.clear();
      contactController.clear();
      latController.clear();
      lngController.clear();
      rateController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homestay added successfully'),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid numeric values'),
        ),
      );
    }
  }
}