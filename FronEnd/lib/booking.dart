import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:stripe_payment/stripe_payment.dart';

class BookingPage extends StatefulWidget {
  final String listingId;
  final double price;

  BookingPage({required this.listingId, required this.price});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  Future<void> createBooking() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select dates.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://YOUR_BACKEND_URL/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': 'USER_ID', // Replace with actual user ID from SharedPreferences
          'listingId': widget.listingId,
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate!.toIso8601String(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final clientSecret = data['clientSecret'];

        // Start Stripe Payment
        final paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest(),
        );

        final paymentIntentResult = await StripePayment.confirmPaymentIntent(
          PaymentIntent(
            clientSecret: clientSecret,
            paymentMethodId: paymentMethod.id,
          ),
        );

        if (paymentIntentResult.status == 'succeeded') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment successful!")),
          );
        }
      } else {
        throw Exception(data['error']);
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create booking.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Listing")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Select Dates"),
                  ElevatedButton(
                    onPressed: () async {
                      DateTimeRange? dateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (dateRange != null) {
                        setState(() {
                          startDate = dateRange.start;
                          endDate = dateRange.end;
                        });
                      }
                    },
                    child: Text("Select Dates"),
                  ),
                  ElevatedButton(
                    onPressed: createBooking,
                    child: Text("Pay Now"),
                  ),
                ],
              ),
            ),
    );
  }
}
