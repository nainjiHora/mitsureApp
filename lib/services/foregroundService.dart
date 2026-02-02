import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'taskService.dart';
@pragma('vm:entry-point')
void startCallback() {
  print("⚙️ START CALLBACK CALLED");
  FlutterForegroundTask.setTaskHandler(VisitTask());
}
