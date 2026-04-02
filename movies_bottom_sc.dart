import 'package:flutter/material.dart';

class MoviesBottomSc extends StatefulWidget {
  const MoviesBottomSc({super.key});

  @override
  State<MoviesBottomSc> createState() => _MoviesBottomScState();
}

class _MoviesBottomScState extends State<MoviesBottomSc> {
  List img = [
    'assets/lalo_movie_banner.jpg',
    'assets/hera_feri.jpg',
    'assets/humz_sath_sath_hai.jpg',
    'assets/solay_movie.jpg',
    'assets/tamil1.jpg',
    'assets/tamil2.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        itemCount: 6,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 270,
          crossAxisSpacing: 9,
        ),
        itemBuilder: (context, index) {
          return Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(img[index]),
                fit: BoxFit.cover,
              ),
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}
