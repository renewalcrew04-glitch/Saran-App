import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../utils/media_utils.dart';
import '../../models/space_event_model.dart';
import 'package:intl/intl.dart';

class SpaceEventCard extends StatelessWidget {
  final SpaceEvent event;

  const SpaceEventCard({super.key, required this.event});

  /// Cover URL with cache-busting so updated image shows after edit.
  static String _eventCoverUrl(SpaceEvent event) {
    final base = ApiConfig.networkImageUrl(event.coverUrl!) ?? event.coverUrl!;
    if (event.updatedAt != null) {
      return '$base${base.contains('?') ? '&' : '?'}v=${event.updatedAt!.millisecondsSinceEpoch}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MMM d, h:mm a').format(event.date);

    final isJoined = event.isJoined;

    return GestureDetector(
      onTap: () {
        context.push('/space/details', extra: event);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isJoined ? scheme.primary.withValues(alpha: 0.4) : scheme.outlineVariant,
            width: isJoined ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: event.coverUrl != null && event.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _eventCoverUrl(event),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                      placeholder: (_, __) => const ImageLoadingPlaceholder(width: double.infinity, height: 140),
                      errorWidget: (_, __, ___) => Center(child: Icon(Icons.image, size: 40, color: scheme.outline)),
                  )
                  : Center(child: Icon(Icons.image, size: 40, color: scheme.outline)),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: event.isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              event.isOnline ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isJoined) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                "Joined",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        event.isOnline ? Icons.link : Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.isOnline
                              ? (event.meetingLink != null && event.meetingLink!.isNotEmpty ? 'Online event' : 'Online')
                              : (event.location.isNotEmpty ? event.location : 'Offline – Address TBA'),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isJoined ? Icons.check_circle : Icons.people_outline,
                            size: 16,
                            color: isJoined ? Colors.black : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isJoined
                                ? 'You joined • ${event.attendeesCount}/${event.capacity} going'
                                : '${event.attendeesCount}/${event.capacity} joined',
                            style: TextStyle(
                              color: isJoined ? Colors.black87 : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: isJoined ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        event.price == 0 ? "Free" : "₹${event.price}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}