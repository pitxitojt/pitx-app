import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  const Carousel({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselView(
      itemExtent: double.infinity,
      children: List<Widget>.generate(10, (int index) {
        return Center(child: Text('Item $index'));
      }),
    );
  }
}
