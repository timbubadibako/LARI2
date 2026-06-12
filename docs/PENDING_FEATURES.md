# LARI V3 - Pending Features & Unlinked UI

## UI Buttons (Requires Navigation/Screens)
1. **Profile Screen > Debug Button (Bug Icon):** Needs routing to a `DebugScreen` for viewing local logs, Hive state, and forcing API syncs.
2. **Profile Screen > Settings Button (Gear Icon):** Needs routing to a `SettingsScreen` for account management, UI preferences, and privacy toggles.
3. **Social Screen > Guild Button (Shield Icon):** Needs routing to a `GuildScreen` for managing faction details, inviting members, or leaving a guild.

## Controllers (Requires Go Backend API Integration)
1. **ProfileController:**
   - `updateDisplayName`: Needs implementation to call `PUT /profiles/:id`.
   - `updateProfile`: Needs implementation to sync full profile changes.
2. **AuthController:**
   - Forgot Password flow needs actual email dispatch logic.
3. **PresenceProvider:**
   - Implement WebSocket or heartbeat logic for live online status.