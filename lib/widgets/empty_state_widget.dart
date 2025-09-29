import 'package:flutter/material.dart';

class EmptyStateWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final Color? color;
  final double iconSize;
  final EmptyStateType type;
  final Widget? customIcon;
  final List<Widget>? additionalActions;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.color,
    this.iconSize = 80,
    this.type = EmptyStateType.normal,
    this.customIcon,
    this.additionalActions,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? _getTypeColor(widget.type);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildContent(theme, effectiveColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône ou illustration personnalisée
            _buildIcon(color),
            const SizedBox(height: 24),

            // Titre
            _buildTitle(theme, color),
            const SizedBox(height: 12),

            // Message
            _buildMessage(theme),
            const SizedBox(height: 32),

            // Actions
            _buildActions(theme, color),

            // Actions additionnelles
            if (widget.additionalActions != null) ...[
              const SizedBox(height: 16),
              ...widget.additionalActions!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    if (widget.customIcon != null) {
      return widget.customIcon!;
    }

    switch (widget.type) {
      case EmptyStateType.search:
        return _buildSearchIcon(color);
      case EmptyStateType.error:
        return _buildErrorIcon(color);
      case EmptyStateType.noConnection:
        return _buildNoConnectionIcon(color);
      case EmptyStateType.maintenance:
        return _buildMaintenanceIcon(color);
      case EmptyStateType.success:
        return _buildSuccessIcon(color);
      default:
        return _buildDefaultIcon(color);
    }
  }

  Widget _buildDefaultIcon(Color color) {
    return Container(
      width: widget.iconSize,
      height: widget.iconSize,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon,
        size: widget.iconSize * 0.6,
        color: color.withOpacity(0.7),
      ),
    );
  }

  Widget _buildSearchIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.search_off,
          size: widget.iconSize * 0.6,
          color: color.withOpacity(0.7),
        ),
        Positioned(
          bottom: widget.iconSize * 0.1,
          right: widget.iconSize * 0.1,
          child: Container(
            width: widget.iconSize * 0.25,
            height: widget.iconSize * 0.25,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              Icons.close,
              size: widget.iconSize * 0.12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.error_outline,
          size: widget.iconSize * 0.6,
          color: Colors.red.shade400,
        ),
      ],
    );
  }

  Widget _buildNoConnectionIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.wifi_off,
          size: widget.iconSize * 0.6,
          color: Colors.orange.shade400,
        ),
      ],
    );
  }

  Widget _buildMaintenanceIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.build,
          size: widget.iconSize * 0.6,
          color: Colors.blue.shade400,
        ),
      ],
    );
  }

  Widget _buildSuccessIcon(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.check_circle_outline,
          size: widget.iconSize * 0.6,
          color: Colors.green.shade400,
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, Color color) {
    return Text(
      widget.title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: _getTypeColor(widget.type),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(ThemeData theme) {
    return Text(
      widget.message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade600,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(ThemeData theme, Color color) {
    final actions = <Widget>[];

    if (widget.actionText != null && widget.onAction != null) {
      actions.add(
        _buildPrimaryAction(theme, color),
      );
    }

    if (widget.secondaryActionText != null &&
        widget.onSecondaryAction != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 12));
      actions.add(
        _buildSecondaryAction(theme),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(children: actions);
  }

  Widget _buildPrimaryAction(ThemeData theme, Color color) {
    return ElevatedButton.icon(
      onPressed: widget.onAction,
      icon: Icon(_getActionIcon(), size: 20),
      label: Text(widget.actionText!),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildSecondaryAction(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: widget.onSecondaryAction,
      icon: Icon(_getSecondaryActionIcon(), size: 18),
      label: Text(widget.secondaryActionText!),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getTypeColor(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.search:
        return Colors.blue.shade600;
      case EmptyStateType.error:
        return Colors.red.shade600;
      case EmptyStateType.noConnection:
        return Colors.orange.shade600;
      case EmptyStateType.maintenance:
        return Colors.blue.shade600;
      case EmptyStateType.success:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getActionIcon() {
    switch (widget.type) {
      case EmptyStateType.search:
        return Icons.refresh;
      case EmptyStateType.error:
        return Icons.refresh;
      case EmptyStateType.noConnection:
        return Icons.wifi;
      case EmptyStateType.maintenance:
        return Icons.refresh;
      default:
        return Icons.add;
    }
  }

  IconData _getSecondaryActionIcon() {
    switch (widget.type) {
      case EmptyStateType.error:
        return Icons.support;
      case EmptyStateType.noConnection:
        return Icons.settings;
      default:
        return Icons.help_outline;
    }
  }
}

enum EmptyStateType {
  normal,
  search,
  error,
  noConnection,
  maintenance,
  success,
}

// Widget d'état vide pour listes spécifiques
class ListEmptyState extends StatelessWidget {
  final String itemType;
  final VoidCallback? onAdd;
  final bool canAdd;

  const ListEmptyState({
    super.key,
    required this.itemType,
    this.onAdd,
    this.canAdd = true,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: _getIconForType(itemType),
      title: 'Aucun $itemType',
      message:
          'Vous n\'avez pas encore de $itemType.\n${canAdd ? 'Commencez par en ajouter un.' : ''}',
      actionText: canAdd ? 'Ajouter un $itemType' : null,
      onAction: onAdd,
      color: _getColorForType(itemType),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bénéficiaire':
      case 'bénéficiaires':
        return Icons.people_outline;
      case 'avs':
        return Icons.medical_services_outlined;
      case 'mission':
      case 'missions':
        return Icons.assignment_outlined;
      case 'message':
      case 'messages':
        return Icons.chat_bubble_outline;
      case 'notification':
      case 'notifications':
        return Icons.notifications_outlined;
      default:
        return Icons.inbox_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'bénéficiaire':
      case 'bénéficiaires':
        return Colors.purple.shade600;
      case 'avs':
        return Colors.orange.shade600;
      case 'mission':
      case 'missions':
        return Colors.blue.shade600;
      case 'message':
      case 'messages':
        return Colors.teal.shade600;
      case 'notification':
      case 'notifications':
        return Colors.indigo.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
