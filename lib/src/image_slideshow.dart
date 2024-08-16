import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/src/indicator.dart';

class ImageSlideshow extends StatefulWidget {
  const ImageSlideshow({
    Key? key,
    required this.children,
    this.width = double.infinity,
    this.height = 200,
    this.initialPage = 0,
    this.indicatorColor,
    this.indicatorBackgroundColor = Colors.grey,
    this.onPageChanged,
    this.autoPlayInterval,
    this.isLoop = false,
    this.indicatorRadius = 3,
    this.indicatorPadding = 4,
    this.indicatorBottomPadding = 10,
    this.disableUserScrolling = false,
    this.overlayMode = false, // New property
  }) : super(key: key);

  final List<Widget> children;
  final double width;
  final double height;
  final int initialPage;
  final Color? indicatorColor;
  final Color? indicatorBackgroundColor;
  final ValueChanged<int>? onPageChanged;
  final int? autoPlayInterval;
  final bool isLoop;
  final double indicatorRadius;
  final double indicatorPadding;
  final double indicatorBottomPadding;
  final bool disableUserScrolling;
  final bool overlayMode; // New property

  @override
  ImageSlideshowState createState() => ImageSlideshowState();
}

class ImageSlideshowState extends State<ImageSlideshow> {
  late final ValueNotifier<int> _currentPageNotifier;
  late final PageController _pageController;
  late final ScrollBehavior _scrollBehavior;
  Timer? _timer;

  void _onPageChanged(int index) {
    _currentPageNotifier.value = index;
    if (widget.onPageChanged != null) {
      final correctIndex = index % widget.children.length;
      widget.onPageChanged!(correctIndex);
    }
  }

  void _autoPlayTimerStart() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: widget.autoPlayInterval!),
      (timer) {
        int nextPage;
        if (widget.isLoop) {
          nextPage = _currentPageNotifier.value + 1;
        } else {
          if (_currentPageNotifier.value < widget.children.length - 1) {
            nextPage = _currentPageNotifier.value + 1;
          } else {
            return;
          }
        }

        goToPage(nextPage);
      },
    );
  }

  void goToPage(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    }
  }

  void stopAutoPlay() {
    _timer?.cancel();
  }

  @override
  void initState() {
    _scrollBehavior = widget.disableUserScrolling
        ? const ScrollBehavior().copyWith(
            scrollbars: false,
            dragDevices: {},
          )
        : const ScrollBehavior().copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          );

    _pageController = PageController(
      initialPage: widget.initialPage,
    );

    _currentPageNotifier = ValueNotifier(widget.initialPage);

    if (widget.autoPlayInterval != null && widget.autoPlayInterval != 0) {
      _autoPlayTimerStart();
    }
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          if (widget.overlayMode)
            ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) {
                final nextIndex = (value + 1) % widget.children.length;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: widget.children[nextIndex], // Next page in the background
                    ),
                    PageView.builder(
                      scrollBehavior: _scrollBehavior,
                      onPageChanged: _onPageChanged,
                      itemCount: widget.isLoop ? null : widget.children.length,
                      controller: _pageController,
                      itemBuilder: (context, index) {
                        final correctIndex = index % widget.children.length;
                        return widget.children[correctIndex];
                      },
                    ),
                  ],
                );
              },
            )
          else
            PageView.builder(
              scrollBehavior: _scrollBehavior,
              onPageChanged: _onPageChanged,
              itemCount: widget.isLoop ? null : widget.children.length,
              controller: _pageController,
              itemBuilder: (context, index) {
                final correctIndex = index % widget.children.length;
                return widget.children[correctIndex];
              },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.indicatorBottomPadding,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) {
                return Indicator(
                  count: widget.children.length,
                  currentIndex: value % widget.children.length,
                  activeColor: widget.indicatorColor,
                  backgroundColor: widget.indicatorBackgroundColor,
                  radius: widget.indicatorRadius,
                  padding: widget.indicatorPadding,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

