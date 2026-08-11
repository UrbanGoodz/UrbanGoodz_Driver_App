/// Urban Goodz Driver App — Operational Support Integration Seam
///
/// Provides a non-intrusive integration seam for driver operational assistance
/// and earnings/dispatch intelligence.
///
/// Persona mapping:
///   Driver Operational Support & Strategy -> SKYLAR (Executive AI Assistant)
///
/// Note: Does not inject intrusive UI into live navigation or active dispatch.
/// Exposes clean service hooks when driver operational support is requested.
library;

class DriverOperationalSupportSeam {
  const DriverOperationalSupportSeam();

  /// Persona assigned to driver operational support.
  static const String assignedPersonaKey = 'skylar';
  static const String assignedPersonaRole = 'Urban Goodz Chief of Staff & Driver Operations Partner';
  static const String openingPhrase = 'Good to see you. Let\'s check your operational metrics and route performance.';

  /// Returns true if driver operational support is active.
  bool get isAvailable => true;

  /// System prompt configuration for Driver Operational Support.
  Map<String, String> getPersonaConfig() => {
    'persona': assignedPersonaKey,
    'role': assignedPersonaRole,
    'tagline': 'Driver Operational Intelligence & Performance Support',
    'greeting': openingPhrase,
    'voice_id_env': 'SKYLAR_ELEVENLABS_VOICE_ID',
    'voice_name': 'Skylar Voice Live',
  };
}
