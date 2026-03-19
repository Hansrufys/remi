# Widget Design: Apple Notes "Digital Paper" Focus

## Overview
A complete redesign of the Remi Home Screen widget to match the Apple Notes aesthetic, focusing on visual clarity and immediate memory recall.

## Visual Specifications
- **Background:** High-contrast Cream white (#F9F7F2) with a subtle border (#E5E3DE).
- **Corners:** 28dp (Match iOS/Premium Android feel).
- **Typography:** 
    - Title: "Remi" in Sans-Serif Medium, 14sp, Charcoal, top-left.
    - Content: **Centered** Focus Thought in Serif (e.g., Georgia or system serif if available), 18-20sp, Black.
- **Floating Action Button:**
    - Size: 48dp.
    - Style: Green Pulse Button (bioMint background, white icon).
    - Position: Bottom-right corner with 16dp margin.

## Data Flow
- `QuickEntryService` will expose a new method `setLatestMemory(String text)`.
- This string is stored in `SharedPreferences` (accessible by the native widget provider).
- The `MemoryExtractionUseCase` will trigger this update whenever a new `MemoryEntry` (specifically an 'Insight' or 'Data' about a person) is created.

## Interactive States
1. **Tap on Center Thought:** Deep link to the specific memory detail in the app.
2. **Tap on Pulse Button:** Launch directly into Voice Capture (already implemented via URI).

## Roadmap
1. [x] Research & Brainstorm visual style.
2. [ ] Update `QuickEntryService` and Isar-to-Widget sync logic.
3. [ ] Create `latest_memory` key handling in Kotlin.
4. [ ] Modify `quick_capture_widget.xml` layout (Paper/Apple Notes).
5. [ ] Update `QuickCaptureWidget.kt` to bind the new text data.
