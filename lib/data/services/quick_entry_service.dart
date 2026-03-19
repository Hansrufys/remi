import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class QuickEntryService {
  final Ref ref;
  static const String _androidWidgetName = 'QuickCaptureWidget';
  static const String _iOSWidgetName = 'RemiWidget';

  QuickEntryService(this.ref);

  /// Updates widget statistics and the latest important thought
  Future<void> updateWidgetData({
    required int tasks,
    required int memories,
    String? latestMemory,
  }) async {
    try {
      // Save data for the widget to display
      await HomeWidget.saveWidgetData<int>('taskCount', tasks);
      await HomeWidget.saveWidgetData<int>('memoryCount', memories);
      
      if (latestMemory != null && latestMemory.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('latest_memory', latestMemory);
      } else {
        // Clear if no latest memory
        await HomeWidget.saveWidgetData<String>('latest_memory', '');
      }

      // Force widget update
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
      
      debugPrint('Widget updated: tasks=$tasks, memories=$memories');
    } catch (e) {
      debugPrint('Widget Update Error: $e');
    }
  }

  /// Sets up a listener for deep links from widgets
  void setupWidgetLinkListener(Function(Uri?) onLink) {
    // Check if app was launched from widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        debugPrint('App launched from widget: $uri');
        onLink(uri);
      }
    });
    
    // Listen for widget clicks while app is running
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        debugPrint('Widget clicked: $uri');
        onLink(uri);
      }
    });
  }
  
  /// Clear widget data (useful for debugging)
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<int>('taskCount', 0);
      await HomeWidget.saveWidgetData<int>('memoryCount', 0);
      await HomeWidget.saveWidgetData<String>('latest_memory', '');
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Widget Clear Error: $e');
    }
  }
}

final quickEntryProvider = Provider((ref) => QuickEntryService(ref));
