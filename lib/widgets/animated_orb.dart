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
          // Soft Purple Aura
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x668B5CF6),
                  Color(0x338B5CF6),
                  Colors.transparent,
                ],
                stops: [0.25, 0.65, 1],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(.95, .95),
                end: const Offset(1.08, 1.08),
                duration: 2500.ms,
              ),

          // Sparkles
          // Orbiting Sparkles
          const Positioned(
            top: 18,
            child: Sparkle(
              size: 10,
              duration: Duration(milliseconds: 1600),
            ),
          ),

          const Positioned(
            right: 22,
            top: 65,
            child: Sparkle(
              size: 8,
              duration: Duration(milliseconds: 2100),
            ),
          ),

          const Positioned(
            left: 18,
            bottom: 55,
            child: Sparkle(
              size: 11,
              duration: Duration(milliseconds: 1800),
            ),
          ),

          const Positioned(
            bottom: 22,
            right: 42,
            child: Sparkle(
              size: 9,
              duration: Duration(milliseconds: 2300),
            ),
          ),
          // Orb
          Image.asset(
            "assets/orb.png",
            width: 180,
          )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: -8,
                end: 8,
                duration: 4.seconds,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: 0,
                end: 1,
                duration: 20.seconds,
                curve: Curves.linear,
              ),
        ],
      ),
    );
  }
}

class Sparkle extends StatelessWidget {
  final double size;
  final Duration duration;

  const Sparkle({
    super.key,
    required this.size,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      color: Colors.white,
      size: size,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(
          begin: 0.3,
          end: 1,
          duration: duration,
        )
        .scale(
          begin: const Offset(.9, .9),
          end: const Offset(1.15, 1.15),
          duration: duration,
        );
  }
}