import 'package:flutter/cupertino.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../lighting/lighting_service.dart';

/// The product's own picture when the provider has one, otherwise a generic
/// mark. It also stands in while the picture loads or if it fails.
class NearbyDeviceIcon extends StatelessWidget {
  const NearbyDeviceIcon({required this.device, required this.size, super.key});

  final NearbyDevice device;
  final double size;

  @override
  Widget build(BuildContext context) {
    final generic = Icon(
      CupertinoIcons.dot_radiowaves_left_right,
      size: size,
      color: context.palette.accentDeep,
    );
    final url = device.iconUrl;
    if (url == null) return generic;
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      frameBuilder: (_, image, frame, loadedAtOnce) =>
          frame == null && !loadedAtOnce ? generic : image,
      errorBuilder: (_, _, _) => generic,
    );
  }
}

/// The name a found device goes by until the user names it.
extension NearbyDeviceName on BuildContext {
  String nearbyDeviceName(NearbyDevice device, int index) =>
      device.name ?? l10n.nearbyDeviceNumbered(index + 1);
}
