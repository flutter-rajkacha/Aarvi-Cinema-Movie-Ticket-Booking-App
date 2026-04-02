import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class TicketSummaryScreen extends StatefulWidget {
  final String userName;
  final String movieName;
  final List<int> selectedSeats;
  final double ticketPrice;
  final String date;
  final String showTime;

  const TicketSummaryScreen({
    super.key,
    required this.userName,
    required this.movieName,
    required this.selectedSeats,
    required this.date,
    required this.showTime,
    required this.ticketPrice,
  });

  @override
  State<TicketSummaryScreen> createState() => _TicketSummaryScreenState();
}

class _TicketSummaryScreenState extends State<TicketSummaryScreen> {
  late Razorpay _razorpay;
  bool isPaymentSuccess = false; // ✅ Track payment status

  int get ticketNumber => DateTime.now().millisecondsSinceEpoch;

  double get totalPrice => widget.selectedSeats.length * widget.ticketPrice;
  final User? user = FirebaseAuth.instance.currentUser;
  late final String email = user?.email ?? "Guest";

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
  List<int> bookedSeats = [];
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("Bookings");

  void bookSeats() async {
    final now = DateTime.now();
    final expiryTime =
        now.add(const Duration(hours: 24)).millisecondsSinceEpoch;

    final bookingData = {
      "userEmail": email,
      "movieName": widget.movieName,
      "date": widget.date,
      "showTime": widget.showTime,
      "seats": widget.selectedSeats,
      "timestamp": ServerValue.timestamp,
      "expiresAt": expiryTime,
    };

    await dbRef
        .child(widget.movieName)
        .child(widget.date)
        .child(widget.showTime)
        .push()
        .set(bookingData);
  }

  // ================== RAZORPAY PAYMENT ==================
  void openCheckout() {
    var options = {
      'key': 'rzp_test_SPPMAAXmI6eR37', // Replace with your test key
      'amount': (totalPrice * 100).toInt(),
      'name': 'AARVI CINEMA',
      'description': widget.movieName,
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      isPaymentSuccess = true;

    });
    bookSeats();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment Successful ✅")));


  }


  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment Failed ❌")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  // ================== PDF GENERATION ==================
  pw.Widget pdfTicketInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: "$label  ",
              style: pw.TextStyle(
                color: PdfColors.teal,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.TextSpan(
                text: value, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> generatePdf(BuildContext context) async {
    if (!isPaymentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete payment first")));
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 500,
              height: 250,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                children: [
                  /// LEFT SECTION
                  pw.Expanded(
                    flex: 2,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(20),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            widget.movieName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pdfTicketInfo("NAME", widget.userName),
                          pdfTicketInfo(
                              "SEATS", widget.selectedSeats.join(", ")),
                          pdfTicketInfo(
                              "PRICE", "Rs.${widget.ticketPrice.toStringAsFixed(0)}"),
                          pdfTicketInfo(
                              "TOTAL", "Rs.${totalPrice.toStringAsFixed(0)}"),
                          pw.Spacer(),
                          pw.Text(
                            "#$ticketNumber",
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// DASHED DIVIDER
                  pw.Container(
                    width: 1,
                    margin: const pw.EdgeInsets.symmetric(vertical: 20),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        15,
                            (index) => pw.Container(
                          width: 1,
                          height: 6,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ),

                  /// RIGHT SECTION
                  pw.Expanded(
                    flex: 3,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(20),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SizedBox(width: 10),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.teal,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  "AARVI CINEMA",
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 20),
                          pw.Center(
                            child: pw.Text(
                              widget.movieName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pdfTicketInfo("NAME", widget.userName),
                          pdfTicketInfo(
                              "SEATS", widget.selectedSeats.join(", ")),
                          pdfTicketInfo(
                              "PRICE", "Rs.${widget.ticketPrice.toStringAsFixed(0)}"),
                          pdfTicketInfo(
                              "TOTAL", "Rs.${totalPrice.toStringAsFixed(0)}"),
                          pw.Spacer(),
                          pw.Text(
                            "#$ticketNumber",
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ticket_$ticketNumber.pdf');

    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Ticket Summary"), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 20),
          uiTicket(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 🔹 Razorpay Pay Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text("Pay Now"),
                  onPressed: openCheckout,
                ),
                const SizedBox(height: 10),
                // 🔹 PDF Button (enabled only after payment)
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download & Open PDF",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaymentSuccess
                        ? Colors.teal
                        : Colors.grey,
                  ),
                  onPressed: isPaymentSuccess
                      ? () => generatePdf(context)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TICKET UI =================
  Widget uiTicket() {
    return Center(
      child: Container(
        width: 450,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// LEFT SECTION
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(35, 20, 35, 0),
                    child: Text(
                      widget.movieName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TicketInfo(label: "NAME  ", value: widget.userName),
                  const SizedBox(height: 5),
                  TicketInfo(
                      label: "SEATS  ",
                      value: widget.selectedSeats.join(", ")),
                  const SizedBox(height: 5),
                  TicketInfo(
                      label: "PRICE   ",
                      value: "Rs.${widget.ticketPrice.toStringAsFixed(0)}"),
                  const SizedBox(height: 5),
                  TicketInfo(
                      label: "TOTAL  ",
                      value: "Rs.${totalPrice.toStringAsFixed(0)}"),
                  const Spacer(),
                  Text(
                    "#$ticketNumber",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            /// DASHED DIVIDER
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxHeight = constraints.maxHeight;
                  const dashHeight = 6.0;
                  const dashSpace = 6.0;
                  final dashCount =
                  (boxHeight / (dashHeight + dashSpace)).floor();
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(dashCount, (_) {
                      return Container(
                        width: 1,
                        height: dashHeight,
                        color: Colors.grey,
                      );
                    }),
                  );
                },
              ),
            ),
            /// RIGHT SECTION
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8AB4A8),
                              width: 3,
                            ),
                            image: const DecorationImage(
                              image: AssetImage("assets/ticket_logo.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "AARVI CINEMA",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.movieName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TicketInfo(label: "NAME  ", value: widget.userName),
                          const SizedBox(height: 5),
                          TicketInfo(
                              label: "SEATS ",
                              value: widget.selectedSeats.join(", ")),
                          const SizedBox(height: 5),
                          TicketInfo(
                              label: "PRICE  ",
                              value: "Rs.${widget.ticketPrice.toStringAsFixed(0)}"),
                          const SizedBox(height: 5),
                          TicketInfo(
                              label: "TOTAL ",
                              value: "Rs.${totalPrice.toStringAsFixed(0)}"),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "#$ticketNumber",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TicketInfo Widget =================
class TicketInfo extends StatelessWidget {
  final String label;
  final String value;

  const TicketInfo({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// class TicketSummaryScreen extends StatefulWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   @override
//   State<TicketSummaryScreen> createState() => _TicketSummaryScreenState();
// }
//
// class _TicketSummaryScreenState extends State<TicketSummaryScreen> {
//
//   late Razorpay _razorpay;
//
//   bool isPaymentSuccess = false;
//
//   int get ticketNumber => DateTime.now().millisecondsSinceEpoch;
//
//   double get totalPrice =>
//       widget.bookedSeats.length * widget.ticketPrice;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _razorpay = Razorpay();
//
//     _razorpay.on(
//         Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(
//         Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(
//         Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }
//
//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }
//
//   // ================= PAYMENT =================
//
//   void openCheckout() {
//     var options = {
//       'key': 'rzp_test_xxxxxxxxx', // your test key
//       'amount': (totalPrice * 100).toInt(),
//       'name': 'AARVI CINEMA',
//       'description': widget.movieName,
//       'prefill': {
//         'contact': '9876543210',
//         'email': 'test@email.com'
//       }
//     };
//
//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//
//     setState(() {
//       isPaymentSuccess = true;
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Payment Successful ✅")),
//     );
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Payment Failed ❌")),
//     );
//   }
//
//   void _handleExternalWallet(ExternalWalletResponse response) {}
//
//   // ================= PDF =================
//
//   pw.Widget pdfTicketInfo(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.RichText(
//         text: pw.TextSpan(
//           children: [
//             pw.TextSpan(
//               text: "$label  ",
//               style: pw.TextStyle(
//                 color: PdfColors.teal,
//                 fontWeight: pw.FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//             pw.TextSpan(
//                 text: value,
//                 style: const pw.TextStyle(fontSize: 12)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> generatePdf() async {
//
//     if (!isPaymentSuccess) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please complete payment first")),
//       );
//       return;
//     }
//
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//
//           return pw.Center(
//             child: pw.Container(
//               width: 500,
//               height: 250,
//               decoration: pw.BoxDecoration(
//                 borderRadius: pw.BorderRadius.circular(16),
//                 border: pw.Border.all(color: PdfColors.grey300),
//               ),
//               child: pw.Row(
//                 children: [
//
//                   pw.Expanded(
//                     flex: 2,
//                     child: pw.Padding(
//                       padding: const pw.EdgeInsets.all(20),
//                       child: pw.Column(
//                         crossAxisAlignment:
//                         pw.CrossAxisAlignment.start,
//                         children: [
//
//                           pw.Text(
//                             widget.movieName.toUpperCase(),
//                             style: pw.TextStyle(
//                               fontSize: 18,
//                               fontWeight: pw.FontWeight.bold,
//                             ),
//                           ),
//
//                           pw.SizedBox(height: 15),
//
//                           pdfTicketInfo(
//                               "NAME", widget.userName),
//
//                           pdfTicketInfo(
//                               "SEATS",
//                               widget.bookedSeats.join(", ")),
//
//                           pdfTicketInfo(
//                               "PRICE",
//                               "₹${widget.ticketPrice}"),
//
//                           pdfTicketInfo(
//                               "TOTAL",
//                               "₹${totalPrice.toStringAsFixed(0)}"),
//
//                           pw.Spacer(),
//
//                           pw.Text(
//                             "#$ticketNumber",
//                             style: pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   pw.Expanded(
//                     flex: 3,
//                     child: pw.Padding(
//                       padding: const pw.EdgeInsets.all(20),
//                       child: pw.Column(
//                         crossAxisAlignment:
//                         pw.CrossAxisAlignment.start,
//                         children: [
//
//                           pw.Container(
//                             padding: const pw.EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 6),
//                             decoration: pw.BoxDecoration(
//                               color: PdfColors.teal,
//                               borderRadius:
//                               pw.BorderRadius.circular(4),
//                             ),
//                             child: pw.Text(
//                               "AARVI CINEMA",
//                               style: pw.TextStyle(
//                                 color: PdfColors.white,
//                                 fontWeight:
//                                 pw.FontWeight.bold,
//                               ),
//                             ),
//                           ),
//
//                           pw.SizedBox(height: 20),
//
//                           pdfTicketInfo(
//                               "NAME", widget.userName),
//
//                           pdfTicketInfo(
//                               "SEATS",
//                               widget.bookedSeats.join(", ")),
//
//                           pdfTicketInfo(
//                               "TOTAL",
//                               "₹${totalPrice.toStringAsFixed(0)}"),
//
//                           pw.Spacer(),
//
//                           pw.Text(
//                             "#$ticketNumber",
//                             style: pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//
//     final dir = await getApplicationDocumentsDirectory();
//
//     final file =
//     File('${dir.path}/ticket_$ticketNumber.pdf');
//
//     await file.writeAsBytes(bytes);
//
//     OpenFile.open(file.path);
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Ticket Summary"),
//         centerTitle: true,
//       ),
//
//       body: Column(
//         children: [
//
//           const SizedBox(height: 20),
//
//           uiTicket(),
//
//           const Spacer(),
//
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//
//                 /// PAYMENT BUTTON
//
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.payment),
//                   label: const Text("Pay Now"),
//                   onPressed: openCheckout,
//                 ),
//
//                 const SizedBox(height: 10),
//
//                 /// PDF BUTTON
//
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.picture_as_pdf),
//                   label: const Text("Download Ticket PDF"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: isPaymentSuccess
//                         ? Colors.teal
//                         : Colors.grey,
//                   ),
//                   onPressed: isPaymentSuccess
//                       ? generatePdf
//                       : null,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= TICKET UI =================
//
//   Widget uiTicket() {
//
//     return Center(
//       child: Container(
//         width: 450,
//         height: 200,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Colors.white,
//           boxShadow: const [
//             BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 8)
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           children: [
//
//             Text(
//               widget.movieName.toUpperCase(),
//               style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold),
//             ),
//
//             const SizedBox(height: 10),
//
//             Text("Name : ${widget.userName}"),
//
//             Text("Seats : ${widget.bookedSeats.join(", ")}"),
//
//             Text("Price : ₹${widget.ticketPrice}"),
//
//             Text("Total : ₹${totalPrice.toStringAsFixed(0)}"),
//
//             const Spacer(),
//
//             Text(
//               "#$ticketNumber",
//               style:
//               const TextStyle(color: Colors.grey),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

//aya sudhi
// ================= PDF GENERATOR =================
// Future<void> generatePdf(BuildContext context) async {
//   final pdf = pw.Document();
//
//   pdf.addPage(
//     pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       build: (pw.Context context) {
//         return pw.Center(
//           child: pw.Container(
//             width: 380,
//             padding: const pw.EdgeInsets.all(16),
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.grey),
//               borderRadius: pw.BorderRadius.circular(8),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Row(
//                   mainAxisAlignment:
//                   pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text(
//                       movieName.toLowerCase(),
//                       style: pw.TextStyle(
//                         fontSize: 18,
//                         fontWeight: pw.FontWeight.bold,
//                       ),
//                     ),
//                     pw.Container(
//                       padding:
//                       const pw.EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4),
//                       decoration: pw.BoxDecoration(
//                         color: PdfColors.blue,
//                         borderRadius:
//                         pw.BorderRadius.circular(4),
//                       ),
//                       child: pw.Text(
//                         "AARVI CINEMA",
//                         style: pw.TextStyle(
//                           color: PdfColors.white,
//                           fontWeight:
//                           pw.FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 12),
//                 pw.Divider(),
//                 pw.SizedBox(height: 12),
//                 pw.Column(
//                   crossAxisAlignment:
//                   pw.CrossAxisAlignment.start,
//                   children: [
//                     ticketItem("NAME", userName),
//                     ticketItem("SEATS",
//                         bookedSeats.join(", ")),
//                     ticketItem("PRICE",
//                         "₹${ticketPrice.toStringAsFixed(0)}"),
//                     ticketItem("TOTAL",
//                         "₹${totalPrice.toStringAsFixed(0)}"),
//                   ],
//                 ),
//                 pw.SizedBox(height: 16),
//                 pw.Divider(),
//                 pw.Align(
//                   alignment: pw.Alignment.center,
//                   child: pw.Text(
//                     "#$ticketNumber",
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       color: PdfColors.grey,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
//
//   final bytes = await pdf.save();
//   final dir = await getApplicationDocumentsDirectory();
//   final file =
//   File('${dir.path}/ticket_$ticketNumber.pdf');
//
//   await file.writeAsBytes(bytes);
//
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("PDF saved at: ${file.path}")),
//   );
//
//   OpenFile.open(file.path);
// }
// ================= PDF HELPER =================

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//
//   // 🔥 Admin base price (Firebase માંથી પણ લઈ શકો)
//   final double adminBasePrice = 100;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//   });
//
//   // ✅ Same ticket number everywhere
//   int get ticketNumber => DateTime.now().millisecondsSinceEpoch;
//
//   /// ✅ Row calculate (5 seats per row)
//   int getRowFromSeat(int seatNumber) {
//     return ((seatNumber - 1) ~/ 5) + 1;
//   }
//
//   /// ✅ Row wise price add
//   double getSeatPrice(int seatNumber) {
//     int row = getRowFromSeat(seatNumber);
//
//     Map<int, double> rowIncrement = {
//       1: 20,
//       2: 30,
//       3: 40,
//       4: 50,
//       5: 60,
//       6: 70,
//       7: 80,
//       8: 90,
//       9: 100,
//       10: 110,
//     };
//
//     return adminBasePrice + (rowIncrement[row] ?? 0);
//   }
//
//   /// ✅ Correct total calculation (Row Wise)
//   double get totalPrice {
//     double total = 0;
//     for (var seat in bookedSeats) {
//       total += getSeatPrice(seat);
//     }
//     return total;
//   }
//
//   // ================= PDF GENERATOR =================
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Container(
//               width: 380,
//               padding: const pw.EdgeInsets.all(16),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//
//                   /// HEADER
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         movieName.toUpperCase(),
//                         style: pw.TextStyle(
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.blue,
//                           borderRadius: pw.BorderRadius.circular(4),
//                         ),
//                         child: pw.Text(
//                           "AARVI CINEMA",
//                           style: pw.TextStyle(
//                             color: PdfColors.white,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 12),
//                   pw.Divider(),
//                   pw.SizedBox(height: 12),
//
//                   /// DETAILS
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("NAME", userName),
//                           ticketItem("SEATS", bookedSeats.join(", ")),
//                           ticketItem("DATE",
//                               DateTime.now().toString().split(" ")[0]),
//                         ],
//                       ),
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("PRICE TYPE",
//                               "Row Wise Pricing"),
//                           ticketItem("TOTAL",
//                               "₹${totalPrice.toStringAsFixed(0)}"),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 16),
//                   pw.Divider(),
//
//                   pw.Align(
//                     alignment: pw.Alignment.center,
//                     child: pw.Text(
//                       "#$ticketNumber",
//                       style: pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/ticket_$ticketNumber.pdf');
//
//     await file.writeAsBytes(bytes);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );
//
//     OpenFile.open(file.path);
//   }
//
//   pw.Widget ticketItem(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             title,
//             style: const pw.TextStyle(
//               fontSize: 9,
//               color: PdfColors.grey,
//             ),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(
//               fontSize: 12,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Ticket Summary"),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           uiTicket(),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Download & Open PDF"),
//               onPressed: () async {
//                 try {
//                   await generatePdf(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Error: $e")),
//                   );
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget uiTicket() {
//     return Container(
//       width: 360,
//       height: 170,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(movieName,
//                 style: const TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Text("Name: $userName"),
//             Text("Seats: ${bookedSeats.join(", ")}"),
//             Text("Pricing: Row Wise Applied"),
//             Text(
//                 "Total (${bookedSeats.length} seats): ₹${totalPrice.toStringAsFixed(0)}"),
//             const Spacer(),
//             Text(
//               "#$ticketNumber",
//               style: const TextStyle(fontSize: 10, color: Colors.grey),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//
//   // 🔥 Admin base price (Firebase માંથી પણ લઈ શકો)
//   final double adminBasePrice = 100;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//   });
//
//   // ✅ Same ticket number everywhere
//   int get ticketNumber => DateTime.now().millisecondsSinceEpoch;
//
//   /// ✅ Row calculate (5 seats per row)
//   int getRowFromSeat(int seatNumber) {
//     return ((seatNumber - 1) ~/ 5) + 1;
//   }
//
//   /// ✅ Row wise price add
//   double getSeatPrice(int seatNumber) {
//     int row = getRowFromSeat(seatNumber);
//
//     Map<int, double> rowIncrement = {
//       1: 20,
//       2: 30,
//       3: 40,
//       4: 50,
//       5: 60,
//       6: 70,
//       7: 80,
//       8: 90,
//       9: 100,
//       10: 110,
//     };
//
//     return adminBasePrice + (rowIncrement[row] ?? 0);
//   }
//
//   /// ✅ Correct total calculation (Row Wise)
//   double get totalPrice {
//     double total = 0;
//     for (var seat in bookedSeats) {
//       total += getSeatPrice(seat);
//     }
//     return total;
//   }
//
//   // ================= PDF GENERATOR =================
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Container(
//               width: 380,
//               padding: const pw.EdgeInsets.all(16),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//
//                   /// HEADER
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         movieName.toUpperCase(),
//                         style: pw.TextStyle(
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.blue,
//                           borderRadius: pw.BorderRadius.circular(4),
//                         ),
//                         child: pw.Text(
//                           "AARVI CINEMA",
//                           style: pw.TextStyle(
//                             color: PdfColors.white,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 12),
//                   pw.Divider(),
//                   pw.SizedBox(height: 12),
//
//                   /// DETAILS
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("NAME", userName),
//                           ticketItem("SEATS", bookedSeats.join(", ")),
//                           ticketItem("DATE",
//                               DateTime.now().toString().split(" ")[0]),
//                         ],
//                       ),
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("PRICE TYPE",
//                               "Row Wise Pricing"),
//                           ticketItem("TOTAL",
//                               "₹${totalPrice.toStringAsFixed(0)}"),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 16),
//                   pw.Divider(),
//
//                   pw.Align(
//                     alignment: pw.Alignment.center,
//                     child: pw.Text(
//                       "#$ticketNumber",
//                       style: pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/ticket_$ticketNumber.pdf');
//
//     await file.writeAsBytes(bytes);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );
//
//     OpenFile.open(file.path);
//   }
//
//   pw.Widget ticketItem(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             title,
//             style: const pw.TextStyle(
//               fontSize: 9,
//               color: PdfColors.grey,
//             ),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(
//               fontSize: 12,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Ticket Summary"),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           uiTicket(),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Download & Open PDF"),
//               onPressed: () async {
//                 try {
//                   await generatePdf(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Error: $e")),
//                   );
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget uiTicket() {
//     return Container(
//       width: 360,
//       height: 170,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(movieName,
//                 style: const TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Text("Name: $userName"),
//             Text("Seats: ${bookedSeats.join(", ")}"),
//             Text("Pricing: Row Wise Applied"),
//             Text(
//                 "Total (${bookedSeats.length} seats): ₹${totalPrice.toStringAsFixed(0)}"),
//             const Spacer(),
//             Text(
//               "#$ticketNumber",
//               style: const TextStyle(fontSize: 10, color: Colors.grey),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   double get totalPrice => bookedSeats.length * ticketPrice;
//
//   // ================= PDF GENERATOR =================
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//     final ticketNumber = DateTime.now().millisecondsSinceEpoch;
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Container(
//               width: 380,
//               padding: const pw.EdgeInsets.all(16),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//
//                   // Header
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         movieName.toUpperCase(),
//                         style: pw.TextStyle(
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.blue,
//                           borderRadius: pw.BorderRadius.circular(4),
//                         ),
//                         child: pw.Text(
//                           "AARVI CINEMA",
//                           style: pw.TextStyle(
//                             color: PdfColors.white,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 12),
//                   pw.Divider(borderStyle: pw.BorderStyle.dashed),
//                   pw.SizedBox(height: 12),
//
//                   // Details
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("NAME", userName),
//                           ticketItem("ROW", "9"),
//                           ticketItem("SEAT", bookedSeats.join(", ")),
//                           ticketItem("DATE", DateTime.now().toString().split(" ")[0]),
//                         ],
//                       ),
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("TIME", "16:25"),
//                           ticketItem("HALL", "3"),
//                           ticketItem("PRICE", "₹${ticketPrice.toStringAsFixed(0)}"),
//                           ticketItem("TOTAL", "₹${totalPrice.toStringAsFixed(0)}"),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 16),
//                   pw.Divider(),
//
//                   pw.Align(
//                     alignment: pw.Alignment.center,
//                     child: pw.Text(
//                       "#$ticketNumber",
//                       style: pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file =
//     File('${dir.path}/ticket_$ticketNumber.pdf');
//
//     await file.writeAsBytes(bytes);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );
//
//     OpenFile.open(file.path);
//   }
//
//   // PDF helper
//   pw.Widget ticketItem(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             title,
//             style: pw.TextStyle(
//               fontSize: 9,
//               color: PdfColors.grey,
//             ),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(
//               fontSize: 12,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Ticket Summary"),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           uiTicket(),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Download & Open PDF"),
//               onPressed: () async {
//                 try {
//                   await generatePdf(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Error: $e")),
//                   );
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Stylish UI Ticket
//   Widget uiTicket() {
//     return Container(
//       width: 360,
//       height: 170,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(movieName,
//                 style: const TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Text("Name: $userName"),
//             Text("Seats: ${bookedSeats.join(", ")}"),
//             Text("Price: ₹$ticketPrice"),
//             Text("Total: ₹$totalPrice"),
//             const Spacer(),
//             Text(
//               "#${DateTime.now().millisecondsSinceEpoch}",
//               style: const TextStyle(fontSize: 10, color: Colors.grey),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   double get totalPrice => bookedSeats.length * ticketPrice;
//
//   // ================= PDF =================
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (_) => pw.Center(child: pdfTicket()),
//       ),
//     );
//
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//       '${dir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.pdf',
//     );
//
//     await file.writeAsBytes(await pdf.save());
//     OpenFile.open(file.path);
//   }
//
//   pw.Widget pdfTicket() {
//     return pw.Container(
//       width: 420,
//       height: 180,
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.grey),
//         borderRadius: pw.BorderRadius.circular(6),
//       ),
//       child: pw.Row(
//         children: [
//           pdfTicketSide(),
//           pw.Container(
//             width: 1,
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 right: pw.BorderSide(
//                   color: PdfColors.grey,
//                   style: pw.BorderStyle.dashed,
//                 ),
//               ),
//             ),
//           ),
//           pdfTicketSide(isRight: true),
//         ],
//       ),
//     );
//   }
//
//   pw.Widget pdfTicketSide({bool isRight = false}) {
//     return pw.Expanded(
//       child: pw.Padding(
//         padding: const pw.EdgeInsets.all(12),
//         child: pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             if (isRight)
//               pw.Container(
//                 padding: const pw.EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 4,
//                 ),
//                 decoration: pw.BoxDecoration(
//                   color: PdfColors.lightBlue,
//                   borderRadius: pw.BorderRadius.circular(4),
//                 ),
//                 child: pw.Text(
//                   "★ CINEMA",
//                   style: pw.TextStyle(
//                     color: PdfColors.white,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),
//             pw.SizedBox(height: 6),
//             pw.Text(
//               "MOVIE",
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 6),
//             pdfRow("ROW", "9"),
//             pdfRow("SEAT", bookedSeats.join(", ")),
//             pdfRow("DATE", "7.23.2017"),
//             pdfRow("TIME", "16:25"),
//             pdfRow("HALL", "3"),
//             pdfRow("PRICE", "\$${ticketPrice.toStringAsFixed(0)}"),
//             pw.Spacer(),
//             pw.Text(
//               "#12345678",
//               style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   pw.Widget pdfRow(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 4),
//       child: pw.Row(
//         children: [
//           pw.SizedBox(
//             width: 45,
//             child: pw.Text(
//               title,
//               style: pw.TextStyle(
//                 fontSize: 9,
//                 color: PdfColors.lightBlue,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Ticket Summary")),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           uiTicket(),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Download Ticket"),
//               onPressed: () => generatePdf(context),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget uiTicket() {
//     return Container(
//       width: 360,
//       height: 210,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Row(
//         children: [
//           uiTicketSide(),
//           Container(
//             width: 1,
//             decoration: const BoxDecoration(
//               border: Border(
//                 right: BorderSide(color: Colors.grey, style: BorderStyle.solid),
//               ),
//             ),
//           ),
//           uiTicketSide(isRight: true),
//         ],
//       ),
//     );
//   }
//
//   Widget uiTicketSide({bool isRight = false}) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (isRight)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.lightBlue,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Text(
//                   "AARVI CINEMA",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 6),
//             const Text("MOVIE", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             uiRow("ROW", "9"),
//             uiRow("SEAT", bookedSeats.join(", ")),
//             uiRow("DATE", "7.23.2017"),
//             uiRow("TIME", "16:25"),
//             uiRow("HALL", "3"),
//             uiRow("PRICE", "\$${ticketPrice.toStringAsFixed(0)}"),
//             const Spacer(),
//             const Text(
//               "#12345678",
//               style: TextStyle(fontSize: 9, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget uiRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 45,
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 9,
//                 color: Colors.lightBlue,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   double get totalPrice => bookedSeats.length * ticketPrice;
//
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Container(
//               width: 360,
//               padding: const pw.EdgeInsets.all(16),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         movieName.toUpperCase(),
//                         style: pw.TextStyle(
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.blue,
//                           borderRadius: pw.BorderRadius.circular(4),
//                         ),
//                         child: pw.Text(
//                           "CINEMA",
//                           style: pw.TextStyle(
//                             color: PdfColors.white,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 12),
//                   pw.Divider(borderStyle: pw.BorderStyle.dashed),
//                   pw.SizedBox(height: 12),
//
//                   // Ticket details
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("NAME", userName),
//                           ticketItem("ROW", "9"),
//                           ticketItem("SEAT", bookedSeats.join(", ")),
//                           ticketItem("DATE", "23.07.2017"),
//                         ],
//                       ),
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           ticketItem("TIME", "16:25"),
//                           ticketItem("HALL", "3"),
//                           ticketItem(
//                             "PRICE",
//                             "₹${ticketPrice.toStringAsFixed(0)}",
//                           ),
//                           ticketItem(
//                             "TOTAL",
//                             "₹${totalPrice.toStringAsFixed(0)}",
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   pw.SizedBox(height: 16),
//                   pw.Divider(),
//
//                   // Ticket number
//                   pw.Align(
//                     alignment: pw.Alignment.center,
//                     child: pw.Text(
//                       "#${DateTime.now().millisecondsSinceEpoch}",
//                       style: pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//       '${dir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.pdf',
//     );
//
//     await file.writeAsBytes(bytes);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );
//
//     OpenFile.open(file.path);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Booking Summary"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Name: $userName"),
//             const SizedBox(height: 8),
//             Text("Movie: $movieName"),
//             const SizedBox(height: 8),
//             Text("Seats: ${bookedSeats.join(', ')}"),
//             const SizedBox(height: 8),
//             Text("Ticket Price: ₹$ticketPrice"),
//             const SizedBox(height: 8),
//             Text("Total Price: ₹$totalPrice"),
//             const SizedBox(height: 30),
//             Center(
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.picture_as_pdf),
//                 label: const Text("Download & Open PDF"),
//                 onPressed: () async {
//                   try {
//                     await generatePdf(context);
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Error: $e")),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Helper widget
// pw.Widget ticketItem(String title, String value) {
//   return pw.Padding(
//     padding: const pw.EdgeInsets.only(bottom: 6),
//     child: pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           title,
//           style: pw.TextStyle(
//             fontSize: 9,
//             color: PdfColors.grey,
//           ),
//         ),
//         pw.Text(
//           value,
//           style: pw.TextStyle(
//             fontSize: 12,
//             fontWeight: pw.FontWeight.bold,
//           ),
//         ),
//       ],
//     ),
//   );
// }

//
//
// //this code not using chatgpt
// import 'package:flutter/material.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   double get totalPrice => bookedSeats.length * ticketPrice;
//
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     // Simple PDF with plain text
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text("Movie: $movieName"),
//               pw.Text("Name: $userName"),
//               pw.Text("Booked Seats: ${bookedSeats.join(', ')}"),
//               pw.Text("Ticket Price: $ticketPrice"),
//               pw.Text("Total Price: $totalPrice"),
//             ],
//           );
//         },
//       ),
//     );
//
//     // Save PDF to device
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     await file.writeAsBytes(bytes);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );
//
//     // Open PDF automatically
//     OpenFile.open(file.path);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Booking Summary"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Name: $userName"),
//             SizedBox(height: 10),
//             Text("Movie: $movieName"),
//             SizedBox(height: 10),
//             Text("Booked Seats: ${bookedSeats.join(', ')}"),
//             SizedBox(height: 10),
//             Text("Ticket Price: $ticketPrice"),
//             SizedBox(height: 10),
//             Text("Total Price: $totalPrice"),
//             SizedBox(height: 30),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: () async {
//                   try {
//                     await generatePdf(context);
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Error saving PDF: $e")),
//                     );
//                   }
//                 },
//                 icon: Icon(Icons.picture_as_pdf),
//                 label: Text("Download & Open PDF"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// //orignal code
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
//
// class TicketSummaryScreen extends StatelessWidget {
//   final String userName;
//   final String movieName;
//   final List<int> bookedSeats;
//   final double ticketPrice;
//
//   const TicketSummaryScreen({
//     super.key,
//     required this.userName,
//     required this.movieName,
//     required this.bookedSeats,
//     this.ticketPrice = 150,
//   });
//
//   int get ticketNumber => DateTime.now().millisecondsSinceEpoch;
//
//   double get totalPrice => bookedSeats.length * ticketPrice;
//
//
//   pw.Widget pdfTicketInfo(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.RichText(
//         text: pw.TextSpan(
//           children: [
//             pw.TextSpan(
//               text: "$label  ",
//               style: pw.TextStyle(
//                 color: PdfColors.teal,
//                 fontWeight: pw.FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//             pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 12)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Container(
//               width: 500,
//               height: 250,
//               decoration: pw.BoxDecoration(
//                 color: PdfColors.white,
//                 borderRadius: pw.BorderRadius.circular(16),
//                 border: pw.Border.all(color: PdfColors.grey300),
//               ),
//               child: pw.Row(
//                 children: [
//                   /// LEFT SECTION
//                   pw.Expanded(
//                     flex: 2,
//                     child: pw.Padding(
//                       padding: const pw.EdgeInsets.all(20),
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Text(
//                             movieName.toUpperCase(),
//                             style: pw.TextStyle(
//                               fontSize: 18,
//                               fontWeight: pw.FontWeight.bold,
//                             ),
//                           ),
//                           pw.SizedBox(height: 15),
//                           pdfTicketInfo("NAME", userName),
//                           pdfTicketInfo("SEATS", bookedSeats.join(", ")),
//                           pdfTicketInfo(
//                             "PRICE",
//                             "₹${ticketPrice.toStringAsFixed(0)}",
//                           ),
//                           pdfTicketInfo(
//                             "TOTAL",
//                             "₹${totalPrice.toStringAsFixed(0)}",
//                           ),
//                           pw.Spacer(),
//                           pw.Text(
//                             "#$ticketNumber",
//                             style: pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   /// DASHED DIVIDER
//                   pw.Container(
//                     width: 1,
//                     margin: const pw.EdgeInsets.symmetric(vertical: 20),
//                     child: pw.Column(
//                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                       children: List.generate(
//                         15,
//                             (index) => pw.Container(
//                           width: 1,
//                           height: 6,
//                           color: PdfColors.grey,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   /// RIGHT SECTION
//                   pw.Expanded(
//                     flex: 3,
//                     child: pw.Padding(
//                       padding: const pw.EdgeInsets.all(20),
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Row(
//                             children: [
//                               pw.SizedBox(width: 10),
//                               pw.Container(
//                                 padding: const pw.EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 6,
//                                 ),
//                                 decoration: pw.BoxDecoration(
//                                   color: PdfColors.teal,
//                                   borderRadius: pw.BorderRadius.circular(4),
//                                 ),
//                                 child: pw.Text(
//                                   "AARVI CINEMA",
//                                   style: pw.TextStyle(
//                                     color: PdfColors.white,
//                                     fontWeight: pw.FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           pw.SizedBox(height: 20),
//                           pw.Center(
//                             child: pw.Text(
//                               movieName.toUpperCase(),
//                               style: pw.TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           pw.SizedBox(height: 15),
//                           pdfTicketInfo("NAME", userName),
//                           pdfTicketInfo("SEATS", bookedSeats.join(", ")),
//                           pdfTicketInfo(
//                             "PRICE",
//                             "₹${ticketPrice.toStringAsFixed(0)}",
//                           ),
//                           pdfTicketInfo(
//                             "TOTAL",
//                             "₹${totalPrice.toStringAsFixed(0)}",
//                           ),
//                           pw.Spacer(),
//                           pw.Text(
//                             "#$ticketNumber",
//                             style: pw.TextStyle(
//                               fontSize: 10,
//                               color: PdfColors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//
//     final bytes = await pdf.save();
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/ticket_$ticketNumber.pdf');
//
//     await file.writeAsBytes(bytes);
//     OpenFile.open(file.path);
//   }
//
//   pw.Widget ticketItem(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 6),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             title,
//             style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
//           ),
//           pw.Text(
//             value,
//             style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Ticket Summary"), centerTitle: true),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//           uiTicket(),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Download & Open PDF"),
//               onPressed: () async {
//                 try {
//                   await generatePdf(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Error: $e")));
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UPDATED STYLISH UI =================
//   Widget uiTicket() {
//     return Center(
//       child: Container(
//         width: 450,
//         height: 240,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 8,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             /// LEFT SECTION
//             Expanded(
//               flex: 2,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(35, 20, 35, 0),
//                     child: Text(
//                       movieName.toUpperCase(),
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TicketInfo(label: "NAME  ", value: userName),
//                   SizedBox(height: 5),
//
//                   TicketInfo(label: "SEATS  ", value: bookedSeats.join(", ")),
//                   SizedBox(height: 5),
//
//                   TicketInfo(
//                     label: "PRICE   ",
//                     value: "₹${ticketPrice.toStringAsFixed(0)}",
//                   ),
//                   SizedBox(height: 5),
//
//                   TicketInfo(
//                     label: "TOTAL  ",
//                     value: "₹${totalPrice.toStringAsFixed(0)}",
//                   ),
//                   const Spacer(),
//                   Text(
//                     "#$ticketNumber",
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//
//             /// DASHED DIVIDER
//             Container(
//               width: 1,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final boxHeight = constraints.maxHeight;
//                   const dashHeight = 6.0;
//                   const dashSpace = 6.0;
//                   final dashCount = (boxHeight / (dashHeight + dashSpace))
//                       .floor();
//                   return Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: List.generate(dashCount, (_) {
//                       return Container(
//                         width: 1,
//                         height: dashHeight,
//                         color: Colors.grey,
//                       );
//                     }),
//                   );
//                 },
//               ),
//             ),
//
//             /// RIGHT SECTION
//             Expanded(
//               flex: 3,
//               child: Padding(
//                 padding: const EdgeInsets.all(15),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 50,
//                           height: 50,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Color(0xFF8AB4A8), // Outline color
//                               width: 3, // Stroke width
//                             ),
//                             image: DecorationImage(
//                               image: AssetImage("assets/ticket_logo.png"),
//                               // Your image
//                               fit: BoxFit.cover, // Makes image fill the circle
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.teal,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: const Text(
//                             "AARVI CINEMA",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                       ],
//                     ),
//                     SizedBox(height: 8),
//                     Center(
//                       child: Text(
//                         movieName.toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Center(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           TicketInfo(label: "NAME  ", value: userName),
//                           SizedBox(height: 5),
//                           TicketInfo(
//                             label: "SEATS ",
//                             value: bookedSeats.join(", "),
//                           ),
//                           SizedBox(height: 5),
//                           TicketInfo(
//                             label: "PRICE  ",
//                             value: "₹${ticketPrice.toStringAsFixed(0)}",
//                           ),
//                           SizedBox(height: 5),
//                           TicketInfo(
//                             label: "TOTAL ",
//                             value: "₹${totalPrice.toStringAsFixed(0)}",
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       "#$ticketNumber",
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ================= TicketInfo Widget =================
// class TicketInfo extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const TicketInfo({super.key, required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return RichText(
//       text: TextSpan(
//         style: const TextStyle(color: Colors.black, fontSize: 14),
//         children: [
//           TextSpan(
//             text: "$label ",
//             style: const TextStyle(
//               color: Colors.teal,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           TextSpan(text: value),
//         ],
//       ),
//     );
//   }
// }