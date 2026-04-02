import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../model/review_model.dart';
import '../firebase/review_service.dart';

class ReviewScreen extends StatefulWidget {
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // final String currentUserId = "user_123";
  // final String currentUserName = "John Doe";
  final User? user = FirebaseAuth.instance.currentUser;

  String get currentUserId => user!.uid;

  String get currentUserName => user!.email ?? 'No Email';

  final ReviewService _reviewService = ReviewService();

  double _rating = 5;
  final TextEditingController _controller = TextEditingController();

  bool _hasUserReviewed(List<Review> reviews) {
    return reviews.any((r) => r.userId == currentUserId);
  }

  Future<void> _submitReview() async {
    if (_controller.text.isEmpty) return;

    await _reviewService.addReview(
      Review(
        userId: currentUserId,
        userName: currentUserName,
        rating: _rating,
        comment: _controller.text,
      ),
    );

    _controller.clear();
    _rating = 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reviews")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<List<Review>>(
          stream: _reviewService.getReviewsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data!;

            return Column(
              children: [
                /// ⭐ Review form (only once)
                if (!_hasUserReviewed(reviews)) ...[
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      _rating = rating;
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Write your review",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitReview,
                    child: Text("Submit Review"),
                  ),
                  Divider(height: 30),
                ],

                /// 📋 Reviews list
                Expanded(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            review.userName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RatingBarIndicator(
                                rating: review.rating,
                                itemBuilder: (context, _) =>
                                    Icon(Icons.star, color: Colors.amber),
                                itemCount: 5,
                                itemSize: 18,
                              ),
                              SizedBox(height: 4),
                              Text(review.comment),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
