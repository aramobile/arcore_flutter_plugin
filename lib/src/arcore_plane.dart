import 'arcore_pose.dart';

class ArCorePlane {
  double extendX=0;
  double extendZ=0;

  late ArCorePose centerPose;
  late ArCorePlaneType type;

  ArCorePlane.fromMap(Map<dynamic, dynamic> map) {
    this.extendX = map["extendX"];
    this.extendZ = map["extendZ"];
    this.centerPose = ArCorePose.fromMap(map["centerPose"]);
    this.type = ArCorePlaneType.values[map["type"] ?? 0];
  }
}

enum ArCorePlaneType {
  HORIZONTAL_UPWARD_FACING,
  HORIZONTAL_DOWNWARD_FACING,
  VERTICAL,
}
