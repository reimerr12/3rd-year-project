import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/marketplace_provider.dart';

const _statusTabs = [
  ('all', 'সব'),
  ('pending', 'অপেক্ষমাণ'),
  ('confirmed', 'নিশ্চিত'),
  ('shipped', 'পাঠানো'),
  ('delivered', 'পৌঁছানো'),
  ('cancelled', 'বাতিল'),
];

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketplaceProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final orders = state.orders;

    final filtered = _selectedStatus == 'all'
        ? orders
        : orders.where((o) => o.status == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('আমার অর্ডার',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: state.isOrdersLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
                _buildStatusTabs(orders),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty(orders.isEmpty)
                      : RefreshIndicator(
                          color: AppTheme.primaryGreen,
                          onRefresh: () => notifier.loadOrders(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _OrderCard(
                              order: filtered[i],
                              onCancel: () =>
                                  notifier.cancelOrder(filtered[i].id),
                              onDismiss: filtered[i].status == 'cancelled'
                                  ? () => notifier.removeOrder(filtered[i].id)
                                  : null,
                              onReorder: () async {
                                await notifier.reorder(filtered[i]);
                                if (context.mounted) {
                                  Navigator.pushNamed(context, AppRouter.cart);
                                }
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusTabs(List<OrderEntry> orders) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statusTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (key, label) = _statusTabs[i];
                final isSelected = _selectedStatus == key;
                final count = key == 'all'
                    ? orders.length
                    : orders.where((o) => o.status == key).length;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            )),
                        if (count > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppTheme.primaryGreen
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$count',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool noOrdersAtAll) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            noOrdersAtAll
                ? 'এখনো কোনো অর্ডার নেই'
                : 'এই বিভাগে কোনো অর্ডার নেই',
            style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          ),
          if (noOrdersAtAll) ...[
            const SizedBox(height: 6),
            Text('বাজার থেকে পণ্য কিনলে এখানে দেখা যাবে',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.market),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('বাজারে যান'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderEntry order;
  final VoidCallback onCancel;
  final VoidCallback onReorder;
  final VoidCallback? onDismiss;

  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.onReorder,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Status header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: order.statusColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(order.statusIcon, color: order.statusColor, size: 16),
                const SizedBox(width: 6),
                Text(order.statusBn,
                    style: TextStyle(
                        color: order.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                if (onDismiss == null) ...[
                  const Spacer(),
                  Text(_shortId(order.id),
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ],
            ),
          ),

          // ── Product row ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: order.product.primaryImage != null
                      ? Image.network(
                          order.product.primaryImage!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.quantity} ${order.product.unit} × ৳${order.product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.payment_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _paymentLabel(order.paymentMethod),
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right column: price + action button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '৳${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (order.status == 'delivered' ||
                        order.status == 'cancelled')
                      _ActionButton(
                          label: 'আবার কিনুন',
                          color: AppTheme.primaryGreen,
                          onTap: onReorder),
                    if (order.status == 'pending')
                      _ActionButton(
                        label: 'বাতিল করুন',
                        color: Colors.red.shade600,
                        borderColor: Colors.red.shade200,
                        bgColor: Colors.red.shade50,
                        onTap: () => _confirmCancel(context),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (order.status != 'cancelled') _buildProgressTracker(order.status),
        ],
      ),
    );

    if (onDismiss != null) {
      return Dismissible(
        key: ValueKey(order.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              Icon(Icons.delete_outline, color: Colors.red.shade400, size: 26),
        ),
        child: card,
      );
    }
    return card;
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('অর্ডার বাতিল করবেন?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${order.product.title} এর অর্ডারটি বাতিল করতে চান?',
            style: TextStyle(color: Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('না', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status) {
    const steps = ['pending', 'confirmed', 'shipped', 'delivered'];
    const labels = ['অপেক্ষা', 'নিশ্চিত', 'পাঠানো', 'পৌঁছানো'];
    const icons = [
      Icons.hourglass_empty_rounded,
      Icons.check_circle_outline_rounded,
      Icons.local_shipping_outlined,
      Icons.done_all_rounded,
    ];
    final current = steps.indexOf(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(color: Colors.grey.shade100, height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (i) {
              final done = i <= current;
              final active = i == current;

              final stepNode = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          done ? AppTheme.primaryGreen : Colors.grey.shade200,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(icons[i],
                        size: 14,
                        color: done ? Colors.white : Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          done ? AppTheme.primaryGreen : Colors.grey.shade400,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );

              if (i == steps.length - 1) return stepNode;

              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stepNode,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 13, bottom: 18),
                        child: Container(
                          height: 2,
                          color: i < current
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    final clean = id.replaceAll('-', '');
    final suffix = clean.length > 6 ? clean.substring(clean.length - 6) : clean;
    return '#${suffix.toUpperCase()}';
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'bkash':
        return 'বিকাশ';
      case 'sslcommerz':
        return 'SSLCommerz';
      case 'cash':
        return 'ক্যাশ অন ডেলিভারি';
      default:
        return method;
    }
  }

  Widget _imgFallback() => Container(
        width: 72,
        height: 72,
        color: Colors.grey.shade100,
        child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
      );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? borderColor;
  final Color? bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.borderColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor ?? color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
