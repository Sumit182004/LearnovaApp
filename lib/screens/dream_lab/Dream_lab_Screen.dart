import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
class DreamLabScreen extends StatefulWidget {
  const DreamLabScreen({super.key});

  @override
  State<DreamLabScreen> createState() => _DreamLabScreenState();
}

class _DreamLabScreenState extends State<DreamLabScreen> {
  bool isChemistry = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff100B25),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildModeToggle(),
            Expanded(
              child: isChemistry
                  ? const ChemistryLab()
                  : const PhysicsLab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Dream Lab ✨",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xff211A45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              "🧪 Chemistry",
              isChemistry,
                  () {
                setState(() {
                  isChemistry = true;
                });
              },
            ),
          ),
          Expanded(
            child: _modeButton(
              "⚡ Physics",
              !isChemistry,
                  () {
                setState(() {
                  isChemistry = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
      String text,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [
              Color(0xff6C5CE7),
              Color(0xff9C4DFF),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/* ============================================================
                        CHEMISTRY LAB
   ============================================================ */

class ChemistryLab extends StatefulWidget {
  const ChemistryLab({super.key});

  @override
  State<ChemistryLab> createState() => _ChemistryLabState();
}

class _ChemistryLabState extends State<ChemistryLab>
    with TickerProviderStateMixin {
  final List<String> selectedChemicals = [];

  bool heaterOn = false;
  double temperature = 25;

  bool reactionRunning = false;

  String reactionStatus = "";
  String reactionEquation = "";
  String reactionType = "";
  String observation = "";
  String product = "";
  String animationType = "";

  late AnimationController reactionController;
  late AnimationController bubbleController;
  late AnimationController flameController;

  final Map<String, Map<String, String>> reactions = {
    "HCl+Mg": {
      "equation": "Mg + 2HCl → MgCl₂ + H₂",
      "type": "Gas Formation",
      "observation": "Bubbles of hydrogen gas are produced.",
      "product": "Magnesium chloride + Hydrogen gas",
      "animation": "gas",
    },

    "CuSO4+Zn": {
      "equation": "Zn + CuSO₄ → ZnSO₄ + Cu",
      "type": "Displacement Reaction",
      "observation": "Copper gets deposited on the zinc.",
      "product": "Zinc sulphate + Copper",
      "animation": "deposit",
    },

    "HCl+NaOH": {
      "equation": "HCl + NaOH → NaCl + H₂O",
      "type": "Neutralisation",
      "observation": "The acid and base combine to form salt and water.",
      "product": "Sodium chloride + Water",
      "animation": "neutralisation",
    },

    "Cl2+Na": {
      "equation": "2Na + Cl₂ → 2NaCl",
      "type": "Combination Reaction",
      "observation": "Sodium reacts with chlorine to form sodium chloride.",
      "product": "Sodium chloride",
      "animation": "flash",
    },

    "CuSO4+NaOH": {
      "equation": "CuSO₄ + 2NaOH → Cu(OH)₂ + Na₂SO₄",
      "type": "Precipitation Reaction",
      "observation": "A blue precipitate forms and settles at the bottom.",
      "product": "Copper hydroxide + Sodium sulphate",
      "animation": "precipitate",
    },
  };

  @override
  void initState() {
    super.initState();

    reactionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    flameController.repeat(reverse: true);
  }

  @override
  void dispose() {
    reactionController.dispose();
    bubbleController.dispose();
    flameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CHEMICAL HANDLING
  // ------------------------------------------------------------

  void addChemical(String chemical) {
    if (selectedChemicals.contains(chemical)) return;

    if (selectedChemicals.length >= 3) {
      setState(() {
        reactionStatus = "You can add up to 3 chemicals.";
      });
      return;
    }

    setState(() {
      selectedChemicals.add(chemical);

      reactionStatus = "";
      reactionEquation = "";
      reactionType = "";
      observation = "";
      product = "";
      reactionRunning = false;
    });
  }

  void removeChemical(String chemical) {
    setState(() {
      selectedChemicals.remove(chemical);

      reactionStatus = "";
      reactionEquation = "";
      reactionType = "";
      observation = "";
      product = "";
      reactionRunning = false;
      animationType = "";
    });

    reactionController.reset();
    bubbleController.reset();
  }

  String getReactionKey() {
    final values = [...selectedChemicals];
    values.sort();
    return values.join("+");
  }

  void startReaction() {
    if (selectedChemicals.length < 2) {
      setState(() {
        reactionStatus = "Add at least two chemicals first.";
        reactionRunning = false;
      });
      return;
    }

    final key = getReactionKey();
    final reaction = reactions[key];

    if (reaction == null) {
      setState(() {
        reactionStatus = "⚠ No reaction observed";
        reactionEquation = "";
        reactionType = "";
        observation =
        "No supported reaction was detected for this combination.";
        product = "";
        reactionRunning = false;
        animationType = "";
      });

      return;
    }

    setState(() {
      reactionStatus = "Reaction detected!";
      reactionEquation = reaction["equation"]!;
      reactionType = reaction["type"]!;
      observation = reaction["observation"]!;
      product = reaction["product"]!;
      animationType = reaction["animation"]!;
      reactionRunning = true;
    });

    reactionController.forward(from: 0);

    if (animationType == "gas") {
      bubbleController.repeat();
    } else {
      bubbleController.stop();
      bubbleController.reset();
    }
  }

  void resetLab() {
    setState(() {
      selectedChemicals.clear();

      heaterOn = false;
      temperature = 25;

      reactionRunning = false;

      reactionStatus = "";
      reactionEquation = "";
      reactionType = "";
      observation = "";
      product = "";
      animationType = "";
    });

    reactionController.reset();
    bubbleController.reset();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Chemistry Lab",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Choose chemicals, perform the experiment and observe the reaction.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // REACTION OPTIONS
          // ----------------------------------------------------

          const Text(
            "Choose a Reaction",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _buildReactionShortcuts(),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // HEATER + START REACTION
          // ----------------------------------------------------

          Row(
            children: [

              Expanded(
                child: _buildHeaterControl(),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildStartButton(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // EXPERIMENT AREA
          // ----------------------------------------------------

          _buildExperimentArea(),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // RESULT
          // ----------------------------------------------------

          if (reactionStatus.isNotEmpty) ...[
            _buildResult(),

            const SizedBox(height: 18),
          ],

          // ----------------------------------------------------
          // CHEMICAL DRAWER
          // ----------------------------------------------------

          const Text(
            "Chemical Drawer",
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Drag a chemical into the beaker.",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          _buildChemicalDrawer(),

          const SizedBox(height: 15),

          // RESET
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resetLab,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Experiment"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                  color: Colors.white.withOpacity(.15),
                ),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // REACTION SHORTCUTS
  // ------------------------------------------------------------

  Widget _buildReactionShortcuts() {
    final list = [
      ["Mg + HCl", "Gas Formation"],
      ["Zn + CuSO₄", "Displacement"],
      ["HCl + NaOH", "Neutralisation"],
      ["CuSO₄ + NaOH", "Precipitation"],
      ["Na + Cl₂", "Combination"],
    ];

    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, index) {
          final item = list[index];

          return GestureDetector(
            onTap: () {
              final chemicals =
              item[0].split(" + ");

              setState(() {
                selectedChemicals
                  ..clear()
                  ..addAll(chemicals);

                reactionStatus =
                "Chemicals placed. Press Start Reaction.";

                reactionEquation = "";
                reactionType = "";
                observation = "";
                product = "";
                reactionRunning = false;
                animationType = "";
              });

              reactionController.reset();
              bubbleController.reset();
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff211A45),
                    Color(0xff281B52),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: Colors.cyanAccent.withOpacity(.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    item[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    item[1],
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // HEATER
  // ------------------------------------------------------------

  Widget _buildHeaterControl() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xff211A45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: heaterOn
              ? Colors.orangeAccent.withOpacity(.7)
              : Colors.white.withOpacity(.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              AnimatedBuilder(
                animation: flameController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: heaterOn
                        ? 1 + flameController.value * .08
                        : 1,
                    child: Icon(
                      Icons.local_fire_department,
                      color: heaterOn
                          ? Colors.orangeAccent
                          : Colors.white38,
                      size: 28,
                    )
                        .animate(
                      target: heaterOn ? 1 : 0,
                    )
                        .scale(
                      begin: const Offset(.85, .85),
                      end: const Offset(1.15, 1.15),
                      duration: 450.ms,
                    )
                        .then()
                        .scale(
                      begin: const Offset(1.15, 1.15),
                      end: const Offset(.9, .9),
                      duration: 450.ms,
                      )
                    );

                },
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  "Heater",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Switch(
                value: heaterOn,
                activeColor: Colors.orangeAccent,
                onChanged: (value) {
                  setState(() {
                    heaterOn = value;

                    if (!value) {
                      temperature = 25;
                    }
                  });
                },
              ),
            ],
          ),

          if (heaterOn) ...[
            const SizedBox(height: 3),

            Text(
              "${temperature.toStringAsFixed(0)}°C",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: temperature,
              min: 25,
              max: 100,
              activeColor: Colors.orangeAccent,
              inactiveColor: Colors.white12,
              onChanged: (value) {
                setState(() {
                  temperature = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // START BUTTON
  // ------------------------------------------------------------

  Widget _buildStartButton() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff6C5CE7),
            Color(0xff9C4DFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(.25),
            blurRadius: 15,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: startReaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              Icons.local_fire_department,
              size: 24,
            ),

            SizedBox(height: 3),

            Text(
              "Start Reaction",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EXPERIMENT AREA
  // ------------------------------------------------------------

  Widget _buildExperimentArea() {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        addChemical(details.data);
      },

      builder: (
          context,
          candidateData,
          rejectedData,
          ) {
        final dragging = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                dragging
                    ? const Color(0xff30235E)
                    : const Color(0xff17112F),
                const Color(0xff0E0A20),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: dragging
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(.08),
              width: dragging ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [

              // BACKGROUND GLOW
              Positioned(
                bottom: 20,
                child: Container(
                  width: 210,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent
                            .withOpacity(.25),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // HEATER BELOW BEAKER
              Positioned(
                bottom: 18,
                child: AnimatedBuilder(
                  animation: flameController,
                  builder: (_, __) {
                    return Column(
                      children: [

                        if (heaterOn)
                          Transform.scale(
                            scale:
                            1 + flameController.value * .12,
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                              size: 42,
                            ),
                          ),

                        Container(
                          width: 190,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff34205F),
                                Color(0xff17102F),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(15),
                            border: Border.all(
                              color: heaterOn
                                  ? Colors.orangeAccent
                                  : Colors.white24,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              heaterOn
                                  ? "HEATER • ${temperature.toInt()}°C"
                                  : "HEATER OFF",
                              style: TextStyle(
                                color: heaterOn
                                    ? Colors.orangeAccent
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // BEAKER
              Positioned(
                top: 65,
                child: _buildBeaker(),
              ),

              // ANIMATION
              if (reactionRunning)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        reactionController,
                        bubbleController,
                      ]),
                      builder: (_, __) {
                        return CustomPaint(
                          painter: ReactionPainter(
                            progress:
                            reactionController.value,
                            bubbleProgress:
                            bubbleController.value,
                            type: animationType,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // DROP MESSAGE
              if (selectedChemicals.isEmpty)
                const Positioned(
                  top: 30,
                  child: Column(
                    children: [

                      Icon(
                        Icons.arrow_downward,
                        color: Colors.cyanAccent,
                        size: 24,
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Drag chemicals into the beaker",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // SELECTED CHEMICALS
              if (selectedChemicals.isNotEmpty)
                Positioned(
                  top: 28,
                  child: Wrap(
                    spacing: 6,
                    children: selectedChemicals.map(
                          (chemical) {
                        return GestureDetector(
                          onTap: () =>
                              removeChemical(chemical),
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                              _chemicalColor(chemical),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              chemical,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BEAKER
  // ------------------------------------------------------------

  Widget _buildBeaker() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.035),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(45),
          bottomRight: Radius.circular(45),
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(.65),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(.08),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [

          // LIQUID
          Positioned(
            bottom: 0,
            left: 4,
            right: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height:
              selectedChemicals.isEmpty ? 0 : 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _liquidColor().withOpacity(.35),
                    _liquidColor().withOpacity(.65),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          if (selectedChemicals.isEmpty)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Icon(
                  Icons.science_outlined,
                  color: Colors.white30,
                  size: 50,
                ),

                SizedBox(height: 8),

                Text(
                  "Empty Beaker",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

          if (selectedChemicals.isNotEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Icon(
                  Icons.science,
                  color: Colors.white70,
                  size: 35,
                ),

                const SizedBox(height: 10),

                Text(
                  reactionRunning
                      ? "Reaction in progress..."
                      : "Ready to react",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _liquidColor() {
    if (selectedChemicals.contains("CuSO₄")) {
      return Colors.blueAccent;
    }

    if (selectedChemicals.contains("HCl")) {
      return Colors.redAccent;
    }

    if (selectedChemicals.contains("NaOH")) {
      return Colors.greenAccent;
    }

    return Colors.cyanAccent;
  }

  // ------------------------------------------------------------
  // CHEMICAL DRAWER
  // ------------------------------------------------------------

  Widget _buildChemicalDrawer() {
    final chemicals = [
      ["Mg", "Magnesium"],
      ["HCl", "Hydrochloric Acid"],
      ["Zn", "Zinc"],
      ["CuSO₄", "Copper Sulphate"],
      ["NaOH", "Sodium Hydroxide"],
      ["Na", "Sodium"],
      ["Cl₂", "Chlorine"],
      ["O₂", "Oxygen"],
      ["H₂O", "Water"],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chemicals.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, index) {
        final chemical = chemicals[index];

        return Draggable<String>(
          data: chemical[0],

          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 100,
              child: _chemicalBottle(
                chemical[0],
                chemical[1],
                dragging: true,
              ),
            ),
          ),

          childWhenDragging: Opacity(
            opacity: .25,
            child: _chemicalBottle(
              chemical[0],
              chemical[1],
            ),
          ),

          child: _chemicalBottle(
            chemical[0],
            chemical[1],
          ),
        );
      },
    );
  }

  Widget _chemicalBottle(
      String symbol,
      String name, {
        bool dragging = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff211A45),
            Color(0xff181230),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _chemicalColor(symbol).withOpacity(.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            Icons.science,
            color: _chemicalColor(symbol),
            size: dragging ? 35 : 28,
          ),

          const SizedBox(height: 5),

          Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Color _chemicalColor(String chemical) {
    switch (chemical) {
      case "Mg":
        return Colors.grey;
      case "HCl":
        return Colors.redAccent;
      case "Zn":
        return Colors.blueGrey;
      case "CuSO₄":
        return Colors.blueAccent;
      case "NaOH":
        return Colors.greenAccent;
      case "Na":
        return Colors.orangeAccent;
      case "Cl₂":
        return Colors.green;
      case "O₂":
        return Colors.lightBlueAccent;
      case "H₂O":
        return Colors.cyanAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  // ------------------------------------------------------------
  // RESULT
  // ------------------------------------------------------------

  Widget _buildResult() {
    final success = reactionEquation.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xff14382D)
            : const Color(0xff351D2A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: success
              ? Colors.greenAccent.withOpacity(.5)
              : Colors.redAccent.withOpacity(.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            reactionStatus,
            style: TextStyle(
              color: success
                  ? Colors.greenAccent
                  : Colors.redAccent,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (success) ...[
            const SizedBox(height: 12),

            Text(
              reactionEquation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Reaction type: $reactionType",
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              observation,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Products: $product",
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),

            Text(
              observation,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ================================================================
// REACTION ANIMATION ENGINE
// ================================================================

class ReactionPainter extends CustomPainter {
  final double progress;
  final double bubbleProgress;
  final String type;

  ReactionPainter({
    required this.progress,
    required this.bubbleProgress,
    required this.type,
  });

  final Paint brush = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2 + 10,
    );

    switch (type) {
      case "gas":
        _drawGasReaction(canvas, center);
        break;

      case "deposit":
        _drawDisplacementReaction(canvas, center);
        break;

      case "neutralisation":
        _drawNeutralisation(canvas, center);
        break;

      case "precipitate":
        _drawPrecipitation(canvas, center);
        break;

      case "flash":
        _drawCombination(canvas, center);
        break;
    }
  }

  // ----------------------------------------------------------
  // Mg + HCl
  // Hydrogen gas bubbles
  // ----------------------------------------------------------

  void _drawGasReaction(
      Canvas canvas,
      Offset center,
      ) {
    final positions = [
      -55.0,
      -38.0,
      -20.0,
      0.0,
      20.0,
      38.0,
      55.0,
      -10.0,
      30.0,
    ];

    for (int i = 0; i < positions.length; i++) {
      final cycle =
          (bubbleProgress + i * .12) % 1;

      final x =
          center.dx + positions[i];

      final y =
          center.dy +
              65 -
              cycle * 150;

      final radius =
          4 + (i % 3) * 2;

      brush
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.cyanAccent.withOpacity(
          1 - cycle,
        );

      canvas.drawCircle(
        Offset(x, y),
        radius.toDouble(),
        brush,
      );
    }

    // bubbling glow
    brush
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent.withOpacity(.08);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 35),
      65,
      brush,
    );
  }

  // ----------------------------------------------------------
  // Zn + CuSO4
  // Copper deposition
  // ----------------------------------------------------------

  void _drawDisplacementReaction(
      Canvas canvas,
      Offset center,
      ) {
    final amount =
    (progress * 70).toInt();

    for (int i = 0; i < amount; i++) {
      final double column = (i % 10).toDouble();
      final double row = (i ~/ 10).toDouble();

      final x =
          center.dx -
              45 +
              column * 10.0;

      final y =
          center.dy +
              20 +
              row * 6;

      brush
        ..style = PaintingStyle.fill
        ..color = Colors.orangeAccent.withOpacity(.9);

      canvas.drawCircle(
        Offset(x, y),
        3,
        brush,
      );
    }

    // copper glow
    brush.color =
        Colors.orangeAccent.withOpacity(.12);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 40),
      55,
      brush,
    );
  }

  // ----------------------------------------------------------
  // HCl + NaOH
  // Neutralisation
  // ----------------------------------------------------------

  void _drawNeutralisation(
      Canvas canvas,
      Offset center,
      ) {
    final radius =
        15 + progress * 50;

    brush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color =
      Colors.purpleAccent.withOpacity(.7);

    canvas.drawCircle(
      center,
      radius,
      brush,
    );

    // acid particle
    final acidAngle =
        progress * pi * 4;

    final acid = Offset(
      center.dx +
          cos(acidAngle) * radius,
      center.dy +
          sin(acidAngle) * radius,
    );

    brush
      ..style = PaintingStyle.fill
      ..color = Colors.redAccent;

    canvas.drawCircle(
      acid,
      6,
      brush,
    );

    // base particle
    final baseAngle =
        acidAngle + pi;

    final base = Offset(
      center.dx +
          cos(baseAngle) * radius,
      center.dy +
          sin(baseAngle) * radius,
    );

    brush.color = Colors.greenAccent;

    canvas.drawCircle(
      base,
      6,
      brush,
    );

    // heat glow
    brush.color =
        Colors.orangeAccent.withOpacity(
          progress * .15,
        );

    canvas.drawCircle(
      center,
      radius * .55,
      brush,
    );
  }

  // ----------------------------------------------------------
  // CuSO4 + NaOH
  // Precipitation
  // ----------------------------------------------------------

  void _drawPrecipitation(
      Canvas canvas,
      Offset center,
      ) {
    final count =
    (progress * 80).toInt();

    for (int i = 0; i < count; i++) {
      final double column = (i % 16).toDouble();
      final double row = (i ~/ 16).toDouble();

      final x =
          center.dx -
              75 +
              column * 10;

      final startY =
          center.dy -
              70 +
              (i % 5) * 7;

      final y =
          startY +
              progress * 120;

      brush
        ..style = PaintingStyle.fill
        ..color =
        Colors.lightBlueAccent.withOpacity(.85);

      canvas.drawCircle(
        Offset(x, y),
        3 + (i % 3) * .5,
        brush,
      );
    }

    // settled precipitate
    if (progress > .65) {
      brush.color =
          Colors.lightBlueAccent.withOpacity(.75);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            center.dx,
            center.dy + 82,
          ),
          width: 135,
          height: 22,
        ),
        brush,
      );
    }
  }

  // ----------------------------------------------------------
  // Na + Cl2
  // Combination / flash
  // ----------------------------------------------------------

  void _drawCombination(
      Canvas canvas,
      Offset center,
      ) {
    final flash =
    sin(progress * pi);

    // central flash
    brush
      ..style = PaintingStyle.fill
      ..color =
      Colors.yellowAccent.withOpacity(
        .35 * flash,
      );

    canvas.drawCircle(
      center,
      25 + progress * 90,
      brush,
    );

    // expanding ring
    brush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color =
      Colors.orangeAccent.withOpacity(
        .9 * flash,
      );

    canvas.drawCircle(
      center,
      30 + progress * 80,
      brush,
    );

    // sparks
    for (int i = 0; i < 16; i++) {
      final angle =
          (i / 16) * pi * 2;

      final distance =
          30 + progress * 100;

      final point = Offset(
        center.dx +
            cos(angle) * distance,
        center.dy +
            sin(angle) * distance,
      );

      brush
        ..style = PaintingStyle.fill
        ..color =
        Colors.yellowAccent.withOpacity(
          .9 * flash,
        );

      canvas.drawCircle(
        point,
        2.5,
        brush,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant ReactionPainter oldDelegate,
      ) {
    return oldDelegate.progress != progress ||
        oldDelegate.bubbleProgress != bubbleProgress ||
        oldDelegate.type != type;
  }
}

/* ============================================================
                        PHYSICS LAB
   ============================================================ */

class PhysicsLab extends StatefulWidget {
  const PhysicsLab({super.key});

  @override
  State<PhysicsLab> createState() => _PhysicsLabState();
}

class _PhysicsLabState extends State<PhysicsLab>
    with SingleTickerProviderStateMixin {
  double velocity = 20;
  double angle = 45;
  double gravity = 9.8;

  bool running = false;

  late AnimationController experimentController;

  @override
  void initState() {
    super.initState();

    experimentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    experimentController.addListener(() {
      setState(() {});
    });

    experimentController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          running = false;
        });
      }
    });
  }

  @override
  void dispose() {
    experimentController.dispose();
    super.dispose();
  }

  void startExperiment() {
    setState(() {
      running = true;
    });

    experimentController.forward(from: 0);
  }

  void pauseExperiment() {
    experimentController.stop();

    setState(() {
      running = false;
    });
  }

  void resetExperiment() {
    experimentController.reset();

    setState(() {
      running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Physics Simulation Lab",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Change the variables and perform the experiment.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff191435),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(.08),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Projectile Motion",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ProjectilePainter(
                      velocity: velocity,
                      angle: angle,
                      gravity: gravity,
                      progress: experimentController.value,
                      running: running,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),

                const SizedBox(height: 10),

                _physicsSlider(
                  "Velocity",
                  velocity,
                  5,
                  40,
                  "m/s",
                      (value) {
                    setState(() {
                      velocity = value;
                    });
                  },
                ),

                _physicsSlider(
                  "Angle",
                  angle,
                  15,
                  75,
                  "°",
                      (value) {
                    setState(() {
                      angle = value;
                    });
                  },
                ),

                _physicsSlider(
                  "Gravity",
                  gravity,
                  1,
                  15,
                  "m/s²",
                      (value) {
                    setState(() {
                      gravity = value;
                    });
                  },
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: running
                            ? pauseExperiment
                            : startExperiment,
                        icon: Icon(
                          running
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          running
                              ? "Pause"
                              : "Start Experiment",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xff6C5CE7),
                          foregroundColor: Colors.white,
                          minimumSize:
                          const Size(double.infinity, 50),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    IconButton(
                      onPressed: resetExperiment,
                      style: IconButton.styleFrom(
                        backgroundColor:
                        Colors.white10,
                      ),
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                _buildResults(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "More Simulations",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _physicsCard(
            "Ohm's Law",
            "Explore voltage, current and resistance",
            Icons.bolt,
          ),

          _physicsCard(
            "Force & Motion",
            "Experiment with force and acceleration",
            Icons.speed,
          ),

          _physicsCard(
            "Reflection of Light",
            "Experiment with mirrors and light rays",
            Icons.light_mode,
          ),

          _physicsCard(
            "Electric Circuits",
            "Build and test an electric circuit",
            Icons.electrical_services,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final radians = angle * pi / 180;

    final timeOfFlight =
        (2 * velocity * sin(radians)) / gravity;

    final maxHeight =
        (velocity * velocity * sin(radians) * sin(radians)) /
            (2 * gravity);

    final range =
        (velocity * velocity * sin(2 * radians)) /
            gravity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Experiment Results",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Time of Flight: ${timeOfFlight.toStringAsFixed(2)} s",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          Text(
            "Maximum Height: ${maxHeight.toStringAsFixed(2)} m",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          Text(
            "Range: ${range.toStringAsFixed(2)} m",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _physicsSlider(
      String title,
      double value,
      double min,
      double max,
      String unit,
      ValueChanged<double> onChanged,
      ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            Text(
              "${value.toStringAsFixed(1)} $unit",
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _physicsCard(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xff211A45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.cyanAccent,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: Colors.white38,
        ),
      ),
    );
  }
}

/* ============================================================
                  PROJECTILE VISUALIZATION
   ============================================================ */

class ProjectilePainter extends CustomPainter {
  final double velocity;
  final double angle;
  final double gravity;
  final double progress;
  final bool running;

  ProjectilePainter({
    required this.velocity,
    required this.angle,
    required this.gravity,
    required this.progress,
    required this.running,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final groundY = size.height - 35;

    // Ground
    final groundPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(10, groundY),
      Offset(size.width - 10, groundY),
      groundPaint,
    );

    final radians = angle * pi / 180;

    // -----------------------------------------
    // Calculate actual projectile values
    // -----------------------------------------

    final totalTime =
        (2 * velocity * sin(radians)) / gravity;

    final range =
        (velocity * velocity * sin(2 * radians)) /
            gravity;

    // Scale the real-world range to screen
    final double scale = range > 0
        ? (size.width - 40) / range
        : 1;

    // -----------------------------------------
    // Draw predicted trajectory
    // -----------------------------------------

    final trajectoryPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    bool first = true;

    for (double t = 0; t <= totalTime; t += 0.03) {
      final xPhysics =
          velocity * cos(radians) * t;

      final yPhysics =
          velocity * sin(radians) * t -
              0.5 * gravity * t * t;

      final x =
          20 + xPhysics * scale;

      final y =
          groundY - yPhysics * scale;

      if (x > size.width - 10) {
        break;
      }

      if (y > groundY) {
        break;
      }

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      trajectoryPaint,
    );

    // -----------------------------------------
    // Calculate moving ball
    // -----------------------------------------

    double currentTime =
        totalTime * progress;

    final xPhysics =
        velocity * cos(radians) * currentTime;

    final yPhysics =
        velocity * sin(radians) * currentTime -
            0.5 *
                gravity *
                currentTime *
                currentTime;

    final ballX =
        20 + xPhysics * scale;

    final ballY =
        groundY - yPhysics * scale;

    // -----------------------------------------
    // Ball glow
    // -----------------------------------------

    final glowPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(.15);

    canvas.drawCircle(
      Offset(ballX, ballY),
      17,
      glowPaint,
    );

    // -----------------------------------------
    // Ball
    // -----------------------------------------

    final ballPaint = Paint()
      ..color = Colors.orangeAccent;

    canvas.drawCircle(
      Offset(ballX, ballY),
      9,
      ballPaint,
    );

    // -----------------------------------------
    // Start launcher
    // -----------------------------------------

    final launcherPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(20, groundY),
      Offset(
        20 + cos(radians) * 30,
        groundY - sin(radians) * 30,
      ),
      launcherPaint,
    );

    // -----------------------------------------
    // If not running, show "Ready"
    // -----------------------------------------

    if (!running && progress == 0) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: "Ready",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          20,
          groundY - 30,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant ProjectilePainter oldDelegate,
      ) {
    return oldDelegate.velocity != velocity ||
        oldDelegate.angle != angle ||
        oldDelegate.gravity != gravity ||
        oldDelegate.progress != progress ||
        oldDelegate.running != running;
  }
}