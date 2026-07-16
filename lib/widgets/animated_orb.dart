import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedOrb extends StatelessWidget {
  const AnimatedOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // Glow
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.45),
                  blurRadius: 90,
                  spreadRadius: 20,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(.92, .92),
                end: const Offset(1.08, 1.08),
                duration: 2500.ms,
              ),

          // Orb
         Image.asset(
           "assets/orb.png",
           width: 180,
         )
             .animate(onPlay: (c) => c.repeat())
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -8,
                end: 8,
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: 0,
                end: 1,
                duration: 20.seconds,
                curve: Curves.linear,
              )

        ],
      ),
    );
  }
}