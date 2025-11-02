import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DifficultySlider extends StatefulWidget {
  final Function(String difficulty) onChanged;
  final String initialDifficulty;

  const DifficultySlider({
    super.key,
    required this.onChanged,
    this.initialDifficulty = 'Easy',
  });

  @override
  State<DifficultySlider> createState() => _DifficultySliderState();
}

class _DifficultySliderState extends State<DifficultySlider> {
  // The internal state tracks the specific segment (0-11) for smooth visuals.
  late int _currentSegment = 3;

  final List<String> _labels = ['Easy', 'Medium', 'Hard'];
  final int _totalSegments = 12;

  @override
  void initState() {
    super.initState();
    // Convert the initial string difficulty to a default segment index.
    _currentSegment = _segmentFromDifficulty(widget.initialDifficulty);
  }

  /// Helper function to map a difficulty string to a representative segment index.
  int _segmentFromDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Medium':
        return 7; // A central segment for Medium
      case 'Hard':
        return 11; // The last segment for Hard
      case 'Easy':
      default:
        return 3; // A central segment for Easy
    }
  }

  /// Helper function to map a segment index to a difficulty string.
  String _difficultyFromSegment(int segment) {
    if (segment >= 8) return 'Hard';
    if (segment >= 4) return 'Medium';
    return 'Easy';
  }

  /// Determines the color of a segment based on the current selection.
  Color _getSegmentColor(int segmentIndex) {
    if (segmentIndex <= _currentSegment) {
      return Theme.of(context).colorScheme.tertiary;
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }

  /// Updates the segment based on the tap or drag position.
  void _updateFromPosition(Offset localPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    const padding = 16.0;
    final containerWidth = box.size.width - (padding * 2);

    if (containerWidth <= 0) return;

    // Calculate which segment index was touched
    double relativeX = localPosition.dx - padding;
    int newSegment = (relativeX / (containerWidth / (_totalSegments - 1)))
        .round()
        .clamp(0, _totalSegments - 1);

    if (newSegment != _currentSegment) {
      // Get the difficulty category BEFORE updating the state.
      String oldDifficulty = _difficultyFromSegment(_currentSegment);
      String newDifficulty = _difficultyFromSegment(newSegment);

      // Update the state to visually move the slider.
      setState(() {
        _currentSegment = newSegment;
      });

      // Only notify the parent widget if the CATEGORY has changed.
      if (oldDifficulty != newDifficulty) {
        widget.onChanged(newDifficulty);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current difficulty level string for the labels.
    String currentDifficultyLabel = _difficultyFromSegment(_currentSegment);

    return Column(
      children: [
        // --- The Segmented Slider Bar ---
        GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _updateFromPosition(details.localPosition),
          onTapDown: (details) => _updateFromPosition(details.localPosition),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_totalSegments, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  height: 20,
                  width: 5,
                  decoration: BoxDecoration(
                    color: _getSegmentColor(index),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // --- The Labels Below the Slider ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _labels.map((label) {
            bool isSelected = currentDifficultyLabel == label;
            return Text(
              label,
              style: GoogleFonts.robotoCondensed(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.secondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
