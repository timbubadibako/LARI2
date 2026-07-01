/// Centralized application strings for easy maintenance and future localization.
class AppStrings {
  // SYSTEM & LOADING
  static const String loading = 'LOADING...';
  static const String initializing = 'INITIALIZING SYSTEM';
  static const String connecting = 'CONNECTING TO NEXUS...';
  static const String gpsRequired = 'GPS SIGNAL REQUIRED TO CONTINUE.';
  static const String networkOnline = 'NETWORK_ONLINE';
  static const String accessDenied = 'ACCESS_DENIED';
  static const String version = 'VERSION 1.0.0';
  
  // AUTHENTICATION
  static const String welcomeBack = 'WELCOME BACK.';
  static const String joinMovement = 'JOIN THE MOVEMENT.';
  static const String email = 'EMAIL ADDRESS';
  static const String password = 'PASSWORD';
  static const String name = 'FULL NAME';
  static const String login = 'LOG IN';
  static const String signup = 'SIGN UP';
  static const String forgotPassword = 'FORGOT PASSWORD?';
  static const String createAccount = 'CREATE NEW ACCOUNT';
  static const String alreadyHaveAccount = 'ALREADY HAVE AN ACCOUNT?';
  
  // HUD & ACTIONS
  static const String ready = 'READY';
  static const String start = 'START';
  static const String stop = 'STOP';
  static const String pause = 'PAUSE';
  static const String resume = 'RESUME';
  static const String finish = 'FINISH';
  static const String discard = 'DISCARD';
  // TODO(production): switch this back to HOLD 6S FINISH before release candidate.
  static const String holdToFinish = 'HOLD 3S FINISH';
  static const String syncInProgress = 'SYNCING_DATA...';

  // NAVIGATION & SECTIONS
  static const String socialRoom = 'SOCIAL_ROOM';
  static const String communityFeed = 'COMMUNITY_FEED';
  static const String runHistory = 'RUN_HISTORY';
  static const String runHistorySubtitle = 'PREVIOUS_SESSIONS';
  static const String profile = 'USER_PROFILE';
  static const String settings = 'SETTINGS';
  static const String dashboard = 'DASHBOARD';
  static const String leaderboard = 'LEADERBOARD';
  static const String adminPanel = 'SYSTEM_ADMIN_CONTROL';

  // WORKOUT / CONQUEST
  static const String runInProgress = 'RUN_IN_PROGRESS';
  static const String gridSyncActive = 'GRID_SYNC_ACTIVE';
  static const String territorySecured = 'TERRITORY_SECURED';
  static const String areaIntegrated = 'AREA_INTEGRATED_INTO_FACTION_GRID';
  static const String loopDetected = 'LOOP_DETECTED';
  static const String areaConquered = 'AREA_CONQUERED';
  static const String runCompleted = 'RUN_COMPLETED';
  static const String activeTracking = 'ACTIVE_TRACKING';
  static const String pocketModeOn = 'POCKET_MODE_ON';

  // SOCIAL & MULTIPLAYER
  static const String factionDominion = 'FACTION_DOMINION';
  static const String recentActivity = 'RECENT_ACTIVITY';
  static const String topRunners = 'TOP_RUNNERS';
  static const String globalGraffitiWall = 'GLOBAL_GRAFFITI_WALL';
  static const String noActivity = 'NO_FIELD_ACTIVITY_DETECTED';
  static const String awaitingUplink = 'AWAITING_RUNNER_SYNC...';
  
  // STATS & LABELS
  static const String distance = 'DISTANCE';
  static const String pace = 'PACE';
  static const String duration = 'DURATION';
  static const String calories = 'CALORIES';
  static const String level = 'LEVEL';
  static const String xp = 'XP';
  static const String areaSecured = 'AREA SECURED';

  // MODES
  static const String modeRogue = 'MODE: FREE_RUN';
  static const String modeGhost = 'MODE: GHOST_RUN';

  // BRANDING
  static const String copyright = '© 2026 STRIDE_IO';
  static const String appName = 'LARI';
}
