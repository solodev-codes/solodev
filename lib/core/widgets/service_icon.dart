import 'package:flutter/material.dart';

/// Maps the free-text `ServiceModel.iconName` chosen in the admin editor to a
/// Material icon.
///
/// The admin types any label they like, so unknown or empty values fall back to
/// a generic code glyph instead of failing or rendering nothing.
IconData serviceIconData(String name) {
  switch (name.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
    case 'flutter':
    case 'dart':
      return Icons.flutter_dash;
    case 'firebase':
    case 'cloud':
    case 'backend':
      return Icons.local_fire_department_rounded;
    case 'ai':
    case 'chatbot':
    case 'machinelearning':
    case 'ml':
      return Icons.smart_toy_rounded;
    case 'design':
    case 'ui':
    case 'ux':
    case 'uiux':
    case 'figma':
      return Icons.palette_rounded;
    case 'mobile':
    case 'android':
    case 'ios':
    case 'phone':
      return Icons.phone_iphone_rounded;
    case 'web':
    case 'website':
      return Icons.language_rounded;
    case 'database':
    case 'sql':
      return Icons.storage_rounded;
    case 'security':
    case 'auth':
      return Icons.security_rounded;
    case 'devops':
    case 'server':
      return Icons.dns_rounded;
    case 'api':
      return Icons.swap_horiz_rounded;
    case 'ecommerce':
    case 'shop':
    case 'store':
      return Icons.shopping_cart_rounded;
    case 'analytics':
    case 'chart':
    case 'charts':
      return Icons.insights_rounded;
    case 'camera':
    case 'photo':
    case 'image':
      return Icons.photo_camera_rounded;
    case 'video':
      return Icons.videocam_rounded;
    case 'support':
    case 'maintenance':
      return Icons.support_agent_rounded;
    case 'automation':
    case 'bot':
      return Icons.auto_awesome_rounded;
    case 'game':
    case 'gamedev':
      return Icons.sports_esports_rounded;
    case 'education':
    case 'training':
      return Icons.school_rounded;
    case 'code':
    case 'development':
    case 'programming':
    default:
      return Icons.code_rounded;
  }
}
