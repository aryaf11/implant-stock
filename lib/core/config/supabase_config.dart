/// إعدادات Supabase — من لوحة التحكم: Project Settings → API
///
/// ضع القيم هنا أو مرّرها عند البناء:
/// flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qdzoitiapchzulbyioya.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkem9pdGlhcGNoenVsYnlpb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3MDY5MjcsImV4cCI6MjA5NzI4MjkyN30.PpagxXcMtngAoS8-PK-qiILLbK_2ebIa1-iOThSEq3Q',
  );

  static const String stateTable = 'app_state';

  static bool get isConfigured {
    if (url.isEmpty || publishableKey.isEmpty) return false;
    if (url.contains('PASTE_YOUR') || publishableKey.contains('PASTE_YOUR')) {
      return false;
    }
    return url.startsWith('https://') && publishableKey.length > 20;
  }
}
