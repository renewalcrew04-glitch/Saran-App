import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ✅ Needed for context.push
import '../../models/space_event_model.dart';
import 'package:intl/intl.dart';

class SpaceEventCard extends StatelessWidget {
  final SpaceEvent event;

  const SpaceEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Format Date
    final dateStr = "${DateFormat('MMM d').format(event.date)} • ${DateFormat('HH:mm').format(event.date)}";
    
    // Check if Online
    final isOnline = event.location.toLowerCase().contains("online") || 
                     (event.meetingLink != null && event.meetingLink!.isNotEmpty);

    // Check for Cover Image
    // ✅ Now valid because we updated the Model
    final hasImage = event.coverUrl != null && event.coverUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // ✅ FIXED: Use GoRouter 'push' instead of Navigator.pushNamed
        context.push('/space/details', extra: event);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(event.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage
                  ? Center(
                      child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade300),
                    )
                  : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  
                  // Title
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
                  
                  // LOCATION / ONLINE Logic
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.videocam_outlined : Icons.location_on_outlined, 
                        size: 14, 
                        color: Colors.grey.shade500
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isOnline ? "Online Event" : event.location,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 8),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${event.attendeesCount} joined',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
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