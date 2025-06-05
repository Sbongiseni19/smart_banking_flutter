// lib/services/booking_data.dart

// Global list of bookings (in-memory)
List<Map<String, String>> bookings = [];

// Function to add a booking to the list
void addBooking(Map<String, String> booking) {
  bookings.add(booking);
}
