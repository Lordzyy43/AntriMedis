time 12 juli 2026


• Executive Summary
  I reviewed the repository read-only. This is a Flutter patient mobile app for AntriMedis, a same-day clinic queueing system backed by
  Supabase. The core patient flow is: authenticate, complete profile, view today’s doctor schedules, take a queue number, track queue status in
  realtime, receive local/inbox notifications, cancel while waiting, and view queue history.

  The strongest part of the system is the backend design: queue invariants are mostly enforced in PostgreSQL through RPCs, RLS, state-machine
  triggers, read-model views, and realtime publication. The weakest areas are production hardening: very low automated test coverage, committed/
  demo credentials in docs/templates, local PIN storage using SharedPreferences + unsalted SHA-256, no FCM/background push path, and some
  scalability limits around Provider-driven global state, realtime fanout, and single-clinic assumptions in the UI.

  Architecture Overview
  The app follows a pragmatic feature-first Flutter structure:

  - App entrypoint initializes dotenv, Supabase, and local notifications in lib/main.dart:9.
  - Root composition uses MultiProvider in lib/app/antrimedis_app.dart:42.
  - Startup routing is gate-based rather than route-table based: splash, password recovery, auth state, profile completion, optional security
    gate, then patient shell.

  - State management is provider + ChangeNotifier.
  - Data access is repository-based, with repositories directly wrapping SupabaseClient.
  - Backend business logic is largely database-centric through Supabase RPCs and views.

  Core runtime gates:

  - _StartupGate decides splash, reset password, authenticated vs unauthenticated, onboarding, and login.
  - _ProfileGate loads the profile and enforces profile completion before entering the patient shell.
  - PatientShellPage uses an IndexedStack with tabs for home, queues, notifications, and account/profile.

  Backend integrations:

  - Supabase Auth: email/password, password reset, Google OAuth.
  - Supabase Postgres: tables, views, functions, RLS policies.
  - Supabase Realtime: queue tickets, sessions, events, schedules, notifications.
  - Supabase Storage: avatar upload through the avatars bucket.
  - Local notifications: flutter_local_notifications.
  - SharedPreferences: onboarding, theme mode, local PIN security setting.

  Folder Structure Analysis
  Top-level:

  - lib/: Flutter application source, 48 Dart files.
  - supabase/: migrations, patches, Supabase docs/config, 25 SQL migrations.
  - docs/: PRD, roadmap, queue business flow, project snapshot.
  - scripts/: Node smoke tests and seed helpers.
  - test/: minimal Flutter widget test.
  - android/, ios/, web/, windows/, macos/, linux/: Flutter platform shells.
  - assets/images/: app logos.

  lib/:

  - app/: root app composition and startup gates.
  - core/config/: colors, spacing, theme, Supabase config.
  - core/services/: notification service.
  - core/utils/: queue status helpers.
  - core/widgets/: shared cards, badges, empty states, banners.
  - features/auth/: auth repository, provider, login/reset UI.
  - features/clinic/: primary branch fetch.
  - features/notifications/: notification repository/provider/model.
  - features/onboarding/: splash, onboarding, security gate.
  - features/patient/: patient home, queue list, tracking, notifications UI, widgets.
  - features/profile/: profile repository/provider, completion/settings pages.
  - features/queue/: queue repository/provider/models.
  - features/settings/: app settings provider.

  One important repository-scope note: docs describe a React/Vite admin panel, but this repository does not contain that web admin source. The
  current repo appears to be the Flutter patient app plus Supabase backend assets and scripts.

  State Management Approach
  State management is provider with ChangeNotifier classes:

  - AuthProvider: Supabase session/auth state.
  - AppSettingsProvider: onboarding, theme, local PIN hash.
  - ClinicProvider: primary clinic branch.
  - ProfileProvider: patient profile and avatar.
  - QueueProvider: schedules, active ticket, ticket history, realtime subscriptions, local queue notifications.
  - NotificationProvider: inbox notifications and realtime refresh.

  This is simple and workable for an MVP. The main architectural limitation is that QueueProvider has accumulated several responsibilities: data
  loading, active ticket tracking, schedule feed subscriptions, notification side effects, error mapping, cancellation, history refresh, and
  realtime lifecycle management.

  Backend Integrations
  The Flutter client uses Supabase directly:

  - Schedule list: v_schedule_availability in lib/features/queue/data/queue_repository.dart:16.
  - Active/history tickets: v_queue_ticket_details.
  - Queue creation: RPC create_queue_ticket in lib/features/queue/data/queue_repository.dart:62.
  - Patient cancellation: RPC cancel_my_ticket in lib/features/queue/data/queue_repository.dart:96.
  - Realtime: ticket, session, queue event, doctor schedule, and notification channels.
  - Avatar: Supabase Storage avatars bucket.
  - Smoke/E2E validation: Node REST/RPC script in scripts/supabase-smoke-test.mjs.

  The SQL layer is robust for an MVP: normalized schema, indexes, RLS, hardened queue functions, session locking, quota checks, active-ticket
  checks, queue estimates, missed/recall flow, and close-session behavior.

  Authentication Flow
  Auth is Supabase Auth:

  - Email/password sign-in via signInWithPassword.
  - Registration via signUp with full_name metadata.
  - Password reset via resetPasswordForEmail.
  - Password recovery state handled through AuthChangeEvent.passwordRecovery.
  - Google OAuth through signInWithOAuth using antrimedis://login-callback/.

  Relevant code is in lib/features/auth/data/auth_repository.dart:15 and lib/features/auth/providers/auth_provider.dart:40.

  After auth:

  1. App loads the current Supabase user.
  2. Profile is fetched from profiles.
  3. If incomplete, user is sent to profile completion.
  4. If local app security is enabled, user must pass the local PIN gate.
  5. Patient shell loads clinic, queue, and notifications.

  Strengths

  - Clear product scope: same-day clinic queueing, not future booking.
  - Good separation between UI, provider state, repository data access, and backend logic.
  - Queue-critical business rules are enforced in database RPCs, not only in Flutter.
  - Supabase schema is normalized and prepared for doctors, branches, roles, events, notifications, and history.
  - Realtime is integrated into both schedule refresh and active queue tracking.
  - Patient UX covers the major expected states: no schedule, active queue, tracking, final status, cancellation, notifications, profile
    completion.

  - Documentation is unusually thorough for an MVP, especially queue lifecycle and QA flow.
  - .env and .env.local are ignored by git.

  Weaknesses

  - Automated tests are almost absent. There is only one widget test for AppErrorBanner in test/widget_test.dart:6.
  - The app uses manual gate-based navigation instead of a typed/declarative router; this will become harder as roles and deep links grow.
  - Provider classes, especially QueueProvider, are doing too much.
  - UI still contains single-clinic hardcoding such as Klinik Sehat Sentosa and 24 Jam.
  - Error handling often collapses exceptions into generic messages, making production debugging harder.
  - Local notification behavior depends on app activity/realtime events; it is not full production push.
  - No strong dependency injection boundary for testing repositories/providers.
  - Web admin code is referenced in docs but absent from this repo, so repo-local architecture is incomplete relative to the documented full
    product.

  Technical Debt

  - QueueProvider should be split into queue schedule state, active ticket tracking, notification side effects, and history/timeline state.
  - ProfileProvider and QueueProvider have fallback/error paths but limited tests around RLS failures, missing profiles, and status transitions.
  - No generated/typed Supabase schema contracts; JSON keys are manually parsed in models.
  - No repository interfaces or mock-friendly architecture.
  - Manual MaterialPageRoute navigation is scattered across pages.
  - Client-side date/time logic exists alongside backend Jakarta-time logic, which can drift if the device timezone differs.
  - SQL migrations are extensive and iterative; good for history, but the current effective schema is hard to understand without applying all
    migrations.

  - Demo/smoke-test operational credentials are embedded in documentation and .env.example.

  Security Risks

  - Demo credentials are committed in docs/templates: .env.example, supabase/README.md:44, and docs/current_project_snapshot.md:155. These
    should be treated as compromised if they point to a real Supabase project.

  - SUPABASE_SERVICE_ROLE_KEY is mentioned in .env.example; it is blank, but templates should strongly separate service-role usage from client
    app configuration.

  - .env is included as a Flutter asset in pubspec.yaml:70. The anon key is not a secret, but bundling environment files can encourage
    accidental leakage of non-client secrets.

  - Local PIN security uses SharedPreferences and SHA-256 with a static app prefix in lib/features/settings/providers/
    app_settings_provider.dart:73. This is not equivalent to secure storage, biometrics, or OS-backed keychain protection.

  - Avatar upload accepts client-provided image bytes/extensions but does not appear to enforce size/dimension validation client-side.
  - Public avatar URLs may be acceptable for MVP, but profile-photo privacy should be reviewed.
  - RLS appears thoughtfully used, and sensitive ticket views use security_invoker = true; still, final policy audit is necessary before real
    production use.

  Scalability Risks

  - Provider-based global state is fine for MVP but may become brittle with multi-role, multi-branch, background sync, and offline/restore
    requirements.

  - Realtime subscriptions are broad in places, especially schedule feed listening to all queue_sessions and doctor_schedules.
  - The UI assumes one primary branch; multi-branch selection is not implemented in the app.
  - Local notifications do not scale to reliable production notifications when the app is terminated; FCM/Edge Functions are needed.
  - Queue estimates are simple average-service-minute estimates, not historical/predictive.
  - Supabase direct-from-client architecture is efficient for MVP, but more complex workflows may eventually need Edge Functions or a service
    layer.

  - Manual JSON parsing can become fragile as backend views evolve.
  - No automated load/concurrency test around create_queue_ticket, despite this being the most race-sensitive feature.

  Code Quality Issues

  - Very low test coverage relative to business risk.
  - Some providers swallow exceptions silently during realtime refresh, which avoids bad UX but hides operational issues.
  - Hardcoded display values reduce configurability.
  - No centralized route model.
  - No formal app logging/analytics/error reporting.
  - Several large UI pages mix presentation, flow control, dialogs, and provider interaction.
  - The repo contains strong docs, but code-level tests do not encode most documented business rules.
  - ScheduleAvailability computes operational phase using device-local DateTime.now, while the backend uses Jakarta time.

  Top 10 Recommended Improvements

  1. Remove or rotate all committed demo credentials; move real QA credentials to a secure secret store.
  2. Stop bundling .env as a Flutter asset; use build-time defines or a client-only config file that cannot include service secrets.
  3. Replace local PIN hashing in SharedPreferences with flutter_secure_storage and preferably biometric/OS auth for real app locking.
  4. Add unit tests for queue models, friendly error mapping, QueueProvider, AuthProvider, and ProfileProvider.
  5. Add integration tests or repeatable Supabase test fixtures for queue state transitions: create, call, serving, missed, recall, skipped,
     cancelled, expired.

  6. Split QueueProvider into smaller state units or move toward Riverpod/BLoC for better lifecycle and testability.
  7. Introduce typed route management, such as go_router, especially for OAuth callback, password recovery, tracking detail, and future multi-
     role flows.

  8. Remove single-clinic hardcoding from Flutter UI and drive clinic identity/hours from backend configuration.
  9. Add production notification architecture: FCM device tokens, Edge Functions/database triggers, and notification delivery status.
  10. Perform a final Supabase security audit: RLS policies, view security_invoker, storage bucket policies, RPC grants, role checks, and
     realtime publication scope.

  No files were modified. I did not run flutter analyze or flutter test; this was a static architectural review.
