import 'package:flutter/material.dart';

class MotoFixUi {
  static const bg = Color(0xFF06111F);
  static const bgDeep = Color(0xFF020B16);
  static const panel = Color(0xFF0D1A2B);
  static const panel2 = Color(0xFF13243A);
  static const orange = Color(0xFFFF8300);
  static const orange2 = Color(0xFFFFA21A);
  static const purple = Color(0xFF453A8F);
  static const green = Color(0xFF48C847);
  static const textSoft = Color(0xFFB8C4D3);

  static const gradient = LinearGradient(
    colors: [orange2, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration screenDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF06111F), Color(0xFF020A14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static BoxDecoration panelDecoration({double radius = 14}) {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static Widget page({
    PreferredSizeWidget? appBar,
    required Widget child,
    Widget? bottomNavigationBar,
  }) {
    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SizedBox.expand(
        child: DecoratedBox(decoration: screenDecoration(), child: child),
      ),
    );
  }

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      actions: actions,
    );
  }
}

class MotoFixButton extends StatelessWidget {
  const MotoFixButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      loading ? 'Chargement...' : label,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );

    final content = loading
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              labelText,
            ],
          )
        : icon == null
        ? labelText
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              labelText,
            ],
          );

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : MotoFixUi.gradient,
          color: onPressed == null ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

class MotoFixField extends StatefulWidget {
  const MotoFixField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;

  @override
  State<MotoFixField> createState() => _MotoFixFieldState();
}

class _MotoFixFieldState extends State<MotoFixField> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscure && !visible,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      minLines: widget.minLines,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFF8795A8), fontSize: 13),
        prefixIcon: widget.icon == null
            ? null
            : Icon(widget.icon, color: const Color(0xFFB7C2D2), size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFB7C2D2),
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF071322),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: _border(Colors.white24),
        enabledBorder: _border(Colors.white24),
        focusedBorder: _border(MotoFixUi.orange),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: large ? 210 : 126,
          height: large ? 118 : 76,
          child: const CustomPaint(painter: MotoLinePainter()),
        ),
        if (large) ...[
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 0.92,
              ),
              children: [
                TextSpan(text: 'Moto'),
                TextSpan(
                  text: 'Fix',
                  style: TextStyle(color: MotoFixUi.orange),
                ),
              ],
            ),
          ),
          const Text(
            'N I G E R',
            style: TextStyle(
              color: MotoFixUi.orange,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ] else
          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(text: 'MotoFix '),
                TextSpan(
                  text: 'Niger',
                  style: TextStyle(color: MotoFixUi.orange),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Taxi moto & depannage rapide',
          style: TextStyle(color: MotoFixUi.textSoft, fontSize: 13),
        ),
      ],
    );
  }
}

class MotoLinePainter extends CustomPainter {
  const MotoLinePainter({this.color = MotoFixUi.orange});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset pt(double x, double y) => Offset(x * size.width, y * size.height);

    canvas.drawLine(pt(0.05, 0.72), pt(0.42, 0.72), p);
    canvas.drawLine(pt(0.10, 0.62), pt(0.36, 0.62), p);
    canvas.drawLine(pt(0.16, 0.52), pt(0.32, 0.52), p);

    canvas.drawCircle(pt(0.34, 0.75), size.width * 0.13, p);
    canvas.drawCircle(pt(0.75, 0.75), size.width * 0.13, p);
    canvas.drawPath(
      Path()
        ..moveTo(pt(0.34, 0.75).dx, pt(0.34, 0.75).dy)
        ..lineTo(pt(0.50, 0.43).dx, pt(0.50, 0.43).dy)
        ..lineTo(pt(0.66, 0.75).dx, pt(0.66, 0.75).dy)
        ..lineTo(pt(0.46, 0.75).dx, pt(0.46, 0.75).dy)
        ..lineTo(pt(0.58, 0.52).dx, pt(0.58, 0.52).dy)
        ..lineTo(pt(0.75, 0.75).dx, pt(0.75, 0.75).dy),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(pt(0.47, 0.43).dx, pt(0.47, 0.43).dy)
        ..quadraticBezierTo(
          pt(0.56, 0.30).dx,
          pt(0.56, 0.30).dy,
          pt(0.71, 0.34).dx,
          pt(0.71, 0.34).dy,
        )
        ..lineTo(pt(0.79, 0.45).dx, pt(0.79, 0.45).dy),
      p,
    );
    canvas.drawLine(pt(0.69, 0.30), pt(0.80, 0.18), p);
    canvas.drawLine(pt(0.79, 0.18), pt(0.88, 0.20), p);
    canvas.drawCircle(pt(0.50, 0.32), size.width * 0.035, fill);
  }

  @override
  bool shouldRepaint(covariant MotoLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ScooterScene extends StatelessWidget {
  const ScooterScene({super.key, this.height = 150, this.taxi = true});

  final double height;
  final bool taxi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: ScooterScenePainter(taxi: taxi)),
    );
  }
}

class ScooterScenePainter extends CustomPainter {
  const ScooterScenePainter({required this.taxi});

  final bool taxi;

  @override
  void paint(Canvas canvas, Size size) {
    final city = Paint()..color = const Color(0xFF24364A);
    for (final r in [
      Rect.fromLTWH(size.width * .20, size.height * .46, 20, 38),
      Rect.fromLTWH(size.width * .32, size.height * .30, 26, 60),
      Rect.fromLTWH(size.width * .47, size.height * .18, 34, 76),
      Rect.fromLTWH(size.width * .63, size.height * .42, 24, 42),
      Rect.fromLTWH(size.width * .75, size.height * .36, 22, 48),
    ]) {
      canvas.drawRect(r, city);
    }

    final orange = Paint()..color = taxi ? MotoFixUi.orange2 : MotoFixUi.purple;
    final dark = Paint()..color = const Color(0xFF263241);
    final white = Paint()..color = Colors.white;

    final baseY = size.height * .70;
    canvas.drawCircle(Offset(size.width * .40, baseY), 18, dark);
    canvas.drawCircle(Offset(size.width * .70, baseY), 18, dark);
    canvas.drawCircle(
      Offset(size.width * .40, baseY),
      10,
      Paint()..color = Colors.black54,
    );
    canvas.drawCircle(
      Offset(size.width * .70, baseY),
      10,
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .34, baseY - 42, size.width * .32, 38),
        const Radius.circular(22),
      ),
      orange,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .52, baseY - 38)
        ..lineTo(size.width * .62, baseY - 82)
        ..lineTo(size.width * .70, baseY - 42),
      orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .62, baseY - 92, 42, 20),
        const Radius.circular(12),
      ),
      white,
    );
    canvas.drawLine(
      Offset(size.width * .66, baseY - 79),
      Offset(size.width * .76, baseY - 96),
      Paint()
        ..color = MotoFixUi.orange2
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ScooterScenePainter oldDelegate) {
    return oldDelegate.taxi != taxi;
  }
}

class MapMockPainter extends CustomPainter {
  const MapMockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF172637);
    canvas.drawRect(Offset.zero & size, bg);

    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final major = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = -2; i < 8; i++) {
      final y = size.height * (i / 7);
      canvas.drawLine(Offset(0, y + 30), Offset(size.width, y - 35), minor);
    }
    for (var i = 0; i < 7; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x + 35, size.height), minor);
    }

    final whiteRoute = Path()
      ..moveTo(size.width * .20, size.height * .82)
      ..lineTo(size.width * .33, size.height * .72)
      ..lineTo(size.width * .25, size.height * .63)
      ..lineTo(size.width * .36, size.height * .52)
      ..lineTo(size.width * .43, size.height * .40);
    canvas.drawPath(whiteRoute, major..color = Colors.white);

    final orangeRoute = Path()
      ..moveTo(size.width * .43, size.height * .40)
      ..lineTo(size.width * .55, size.height * .34)
      ..lineTo(size.width * .59, size.height * .22)
      ..lineTo(size.width * .82, size.height * .15);
    canvas.drawPath(
      orangeRoute,
      Paint()
        ..color = MotoFixUi.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Demande envoyee', '02 Juin 2026 - 14:30', Icons.check_circle, true),
      ('Recherche en cours', 'Un chauffeur est en route', Icons.radar, true),
      (
        'Chauffeur trouve',
        'Issa - Immat : 1234 NN 75',
        Icons.engineering,
        true,
      ),
      ('En route vers vous', 'Arrivee dans 5 min', Icons.local_taxi, false),
      ('Arrive', 'Le chauffeur est arrive', Icons.flag, false),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(
            title: items[i].$1,
            subtitle: items[i].$2,
            icon: items[i].$3,
            done: items[i].$4,
            active: i == 3,
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.active,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? MotoFixUi.orange
        : done
        ? MotoFixUi.green
        : const Color(0xFF738196);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? MotoFixUi.green : Colors.white12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: MotoFixUi.textSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: color,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
