class Homestay {
  final String name;
  final String location;
  final String contact;
  final double lat;
  final double lng;
  final double rate; // ✅ Added rate

  Homestay({
    required this.name,
    required this.location,
    required this.contact,
    required this.lat,
    required this.lng,
    required this.rate,
  });
}

class HomestayData {
  static List<Homestay> homestays = [
    Homestay(
      name: 'CareNest',
      location: 'City Cancer Hospital',
      contact: '9876543210',
      lat: 12.9716,
      lng: 77.5946,
      rate: 1200,
    ),
    Homestay(
      name: 'HopeStay',
      location: 'Apollo Oncology',
      contact: '9123456780',
      lat: 12.9352,
      lng: 77.6245,
      rate: 1500,
    ),
  ];
}