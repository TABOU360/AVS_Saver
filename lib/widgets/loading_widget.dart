import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  final LoadingType type;
  final bool showProgress;
  final double? progress;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.type = LoadingType.circular,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(effectiveColor),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            _buildLoadingMessage(theme),
          ],
          if (widget.showProgress && widget.progress != null) ...[
            const SizedBox(height: 12),
            _buildProgressBar(effectiveColor),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: widget.size / 10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            value: widget.showProgress ? widget.progress : null,
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: widget.size * 3,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
            value: widget.showProgress ? widget.progress : null,
          ),
        );

      case LoadingType.dots:
        return _buildDotsIndicator(color);

      case LoadingType.pulse:
        return _buildPulseIndicator(color);

      case LoadingType.wave:
        return _buildWaveIndicator(color);

      case LoadingType.spinner:
        return _buildSpinnerIndicator(color);
    }
  }

  Widget _buildDotsIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity =
                (0.4 + (0.6 * (1 - (value * 2 - 1).abs()))).clamp(0.0, 1.0);

            return Container(
              width: widget.size / 4,
              height: widget.size / 4,
              margin: EdgeInsets.symmetric(horizontal: widget.size / 20),
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final value = ((_controller.value * 4) - index).clamp(0.0, 1.0);
            final height =
                widget.size * (0.3 + 0.7 * (1 - (value * 2 - 1).abs()));

            return Container(
              width: widget.size / 8,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: widget.size / 40),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.size / 16),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpinnerIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: SpinnerPainter(color: color),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMessage(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.7 + 0.3 * _pulseAnimation.value,
          child: Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(Color color) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: widget.progress,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(widget.progress! * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  wave,
  spinner,
}

class SpinnerPainter extends CustomPainter {
  final Color color;

  SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width / 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const segments = 8;
    for (int i = 0; i < segments; i++) {
      final opacity = (i + 1) / segments;
      paint.color = color.withOpacity(opacity);

      final startAngle = (i * 2 * 3.14159) / segments;
      const sweepAngle = 3.14159 / segments;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - paint.strokeWidth / 2,
        ),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget de chargement avec skeleton
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final int itemCount;
  final double itemHeight;

  const SkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.itemCount = 3,
    this.itemHeight = 80,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLoading ? _buildSkeleton() : widget.child;
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      height: widget.itemHeight,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildSkeletonBox(60, 60, BorderRadius.circular(30)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSkeletonBox(
                    double.infinity, 16, BorderRadius.circular(4)),
                const SizedBox(height: 8),
                _buildSkeletonBox(200, 14, BorderRadius.circular(4)),
                const SizedBox(height: 8),
                _buildSkeletonBox(100, 12, BorderRadius.circular(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(
      double width, double height, BorderRadius borderRadius) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
