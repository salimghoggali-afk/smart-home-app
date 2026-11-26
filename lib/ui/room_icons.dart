import 'package:material_ui/material_ui.dart';

IconData roomIcon(String type) {
  switch (type) {
    case 'bedroom':
      return Icons.bed_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'dining room':
      return Icons.dining_outlined;
    case 'bathroom':
      return Icons.bathtub_outlined;
    case 'toilet':
      return Icons.wc_outlined;
    case 'office':
      return Icons.desk_outlined;
    case 'hall':
    case 'entrance':
      return Icons.door_front_door_outlined;
    case 'corridor':
      return Icons.view_stream_outlined;
    case 'stairs':
      return Icons.stairs_outlined;
    case 'balcony':
      return Icons.balcony_outlined;
    case 'garage':
      return Icons.garage_outlined;
    case 'garden':
      return Icons.yard_outlined;
    default:
      return Icons.weekend_outlined;
  }
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
