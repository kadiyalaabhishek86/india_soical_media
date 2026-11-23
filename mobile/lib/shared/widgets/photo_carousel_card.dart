import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'profile_image_view.dart';

class PhotoCarouselCard extends StatefulWidget {
  final List<String> images;
  final String displayName;
  final int? age;
  final String? gender;
  final String? stateName;
  final String? city;
  final VoidCallback? onEditPressed;
  final VoidCallback? onClosePressed;
  final bool isEditable;
  final double height;

  const PhotoCarouselCard({
    super.key,
    required this.images,
    required this.displayName,
    this.age,
    this.gender,
    this.stateName,
    this.city,
    this.onEditPressed,
    this.onClosePressed,
    this.isEditable = false,
    this.height = 360,
  });

  @override
  State<PhotoCarouselCard> createState() => _PhotoCarouselCardState();
}

class _PhotoCarouselCardState extends State<PhotoCarouselCard> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _displayImages {
    if (widget.images.isNotEmpty) {
      return widget.images.take(3).toList();
    }
    return ['']; // Fallback empty item
  }

  void _nextPhoto() {
    final total = _displayImages.length;
    if (total <= 1) return;
    final next = (_currentIndex + 1) % total;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevPhoto() {
    final total = _displayImages.length;
    if (total <= 1) return;
    final prev = (_currentIndex - 1 + total) % total;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _displayImages;
    final totalPhotos = 3; // Always show 3 indicator dashes like the target design

    final locationParts = [
      if (widget.city != null && widget.city!.isNotEmpty) widget.city,
      if (widget.stateName != null && widget.stateName!.isNotEmpty) widget.stateName,
    ].join(', ');

    final subtitleParts = [
      if (widget.gender != null && widget.gender != 'Prefer not to say') widget.gender,
      if (locationParts.isNotEmpty) locationParts,
      if (widget.gender == null && locationParts.isEmpty) 'Adult 18+',
    ].join(' • ');

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AaraColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AaraColors.champagne.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Photo PageView
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                final imgUrl = images[index];
                if (imgUrl.isEmpty) {
                  return Container(
                    color: const Color(0xFF161619),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: AaraColors.champagne.withOpacity(0.15),
                            child: Text(
                              widget.displayName.isNotEmpty
                                  ? widget.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AaraColors.champagneLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.isEditable)
                            TextButton.icon(
                              onPressed: widget.onEditPressed,
                              icon: const Icon(Icons.add_a_photo, size: 16, color: AaraColors.champagneLight),
                              label: const Text(
                                'Add 3 Profile Photos',
                                style: TextStyle(color: AaraColors.champagneLight, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ProfileImageView(
                  imageUrl: imgUrl,
                  fallbackInitial: widget.displayName,
                  width: double.infinity,
                  height: widget.height,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                );
              },
            ),

            // 2. Tap Left / Right to cycle photos
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _prevPhoto,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _nextPhoto,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),

            // 3. Top Story Indicator Bars (3 segments)
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                children: List.generate(totalPhotos, (index) {
                  final isActive = index == _currentIndex;
                  final hasPhoto = index < images.length && images[index].isNotEmpty;

                  return Expanded(
                    child: Container(
                      height: 3.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : (hasPhoto
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white.withOpacity(0.18)),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 4. Top Action Buttons (Close on left if modal, Edit on right if editable)
            Positioned(
              top: 24,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onClosePressed != null)
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: widget.onClosePressed,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.isEditable && widget.onEditPressed != null)
                    Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AaraColors.champagneLight, size: 20),
                        tooltip: 'Edit Profile & Photos',
                        onPressed: widget.onEditPressed,
                      ),
                    ),
                ],
              ),
            ),

            // 5. Bottom Dark Gradient Overlay with User Info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 40, 18, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x990A0A0C),
                      Color(0xF00A0A0C),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.age != null && widget.age! > 0
                                      ? '${widget.displayName}, ${widget.age}'
                                      : widget.displayName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: AaraColors.champagne,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitleParts.isNotEmpty ? subtitleParts : 'Adult 18+',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isEditable && widget.onEditPressed != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AaraColors.champagne.withOpacity(0.2),
                          foregroundColor: AaraColors.champagneLight,
                          side: const BorderSide(color: AaraColors.champagne, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: widget.onEditPressed,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
