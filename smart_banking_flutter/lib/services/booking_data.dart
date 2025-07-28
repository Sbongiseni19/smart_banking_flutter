class BookingData {
  static final BookingData _instance = BookingData._internal();
  factory BookingData() => _instance;

  BookingData._internal();

  final List<Map<String, String>> _appointments = [];

  List<Map<String, String>> get appointments => _appointments;

  void addBooking(Map<String, String> booking) {
    _appointments.add(booking);
  }

  void clearBookings() {
    _appointments.clear();
  }
}
