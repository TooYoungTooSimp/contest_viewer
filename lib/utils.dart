import 'package:flutter/widgets.dart';

extension WidgetPadding on Widget {
  Widget pad1(double p) => Padding(
        padding: EdgeInsets.all(p),
        child: this,
      );

  Widget pad2(double v, double h) => Padding(
        padding: EdgeInsets.symmetric(vertical: v, horizontal: h),
        child: this,
      );

  Widget pad4(double left, double top, double right, double bottom) => Padding(
        padding: EdgeInsets.fromLTRB(left, top, right, bottom),
        child: this,
      );
}

extension IntFormat on int {
  String toSignedString() => (this < 0 ? "-" : "+") + abs().toString();
}
