class AppConfig {
    static const String supabaseUrl = String.fromEnvironment(
        'SCA_SUPABASE_URL',
        defaultValue: 'https://fzaoqefymkabsbgptrks.supabase.co',
    );
  static const String supabaseAnonKey =
            String.fromEnvironment(
        'SCA_SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_5I6F-pd75yZ5-0sty_VcRQ_F3wE0iZz',
    );
  static const String usernameEmailDomain =
            String.fromEnvironment(
        'SCA_USERNAME_EMAIL_DOMAIN',
        defaultValue: 'sca.local',
    );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}