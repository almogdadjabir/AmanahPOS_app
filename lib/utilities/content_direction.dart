import 'dart:ui';

import 'package:intl/intl.dart' show Bidi;

/// Direction of a piece of user content (product name etc.) based on its
/// first strong directional character — independent of the app locale.
/// Arabic name in an English app → RTL; Latin name in the Arabic app → LTR.
extension ContentDirection on String {
  TextDirection get contentDirection =>
      Bidi.startsWithRtl(this) ? TextDirection.rtl : TextDirection.ltr;
}
