# Auth and Role Mapping Report

## Scope

This report reviews the current Flutter authentication code and compares it
with the supplied Production `public.user` schema.

No SQL was executed. No database was modified. No user was created. No
password was changed. No policy or RPC was created.

## 1. How the Single User Logs In in the New Flutter Version

The login flow is:

1. `LoginScreen` collects a username and password.
2. `AuthProvider.login()` calls `DirectDatabaseAuthService.login()`.
3. `DirectDatabaseAuthService` calls Supabase Auth:
   `Supabase.instance.client.auth.signInWithPassword(...)`.
4. If Supabase returns a session, Flutter stores the Supabase access token in
   secure storage under `access_token`.
5. The app navigates to `DashboardScreen`.

The login screen does not query `public.user` and does not validate the old
FastAPI password hash.

## 2. Is Supabase Auth Actually Used?

Yes, in the Flutter code.

The current implementation uses:

- `signInWithPassword()` for login.
- `currentSession` for restoring the session.
- `auth.signOut()` for logout.
- `auth.currentUser` for current-user information.
- `auth.updateUser()` for username metadata and password updates.

Supabase must be initialized with:

- `SCA_SUPABASE_URL`
- `SCA_SUPABASE_ANON_KEY`

If either value is missing, login fails with a configuration error.

## 3. Source of Username

At login, the value comes from the text entered in the Login screen.

`DirectDatabaseAuthService._emailForLogin()` behaves as follows:

- If the entered value already contains `@`, it is passed to Supabase Auth as
  an email address.
- Otherwise, the app requires `SCA_USERNAME_EMAIL_DOMAIN` and converts the
  value to:

  `entered_username@configured_domain`

After login, the settings/user display reads:

- `user.userMetadata['username']`, if present.
- Otherwise `user.email`.

The username is not currently read from `public.user.username`.

## 4. Source of Role

The role is currently read from Supabase Auth user metadata:

`user.userMetadata['role'] ?? 'Viewer'`

Therefore:

- The role is not read from `public.user.role`.
- The fallback role is `Viewer`.
- There is no verified server-side role lookup in the current Flutter code.
- A client-visible metadata value must not be treated as a trusted authorization
  source for sensitive RPCs.

The UI translates these expected role strings:

- `Admin`
- `Data Entry`
- `Viewer`

## 5. Current Role of the Production User

The actual current role cannot be determined from the supplied information.

The Production schema only states that `public.user.role` is `USER-DEFINED`.
It does not provide:

- The underlying enum/type name.
- The enum values.
- The role value for the existing user row.
- A read-only mapping from that row to a Supabase Auth identity.

The old FastAPI code supports `Admin`, `Data Entry`, and `Viewer`, with Admin
also passing Data Entry checks. The actual Production role remains unverified.

## 6. Is `public.user` Linked to Supabase Auth?

No link is demonstrated.

The supplied `public.user` schema contains:

- `id integer`
- `username`
- `full_name`
- `role USER-DEFINED`
- `hashed_password`
- `is_active`
- timestamps
- `is_synced`

It does not contain a supplied `auth.users.id` UUID column or a declared
foreign key to `auth.users`.

The current Flutter code also does not perform a lookup joining an Auth user to
`public.user`. Therefore the relationship is currently **unknown and must be
verified read-only**.

## 7. Simplest Safe Approach for One User

The safest design is:

1. Keep the existing `public.user` row and its password/hash unchanged.
2. Do not put the old PBKDF2 hash or database password in Flutter.
3. Use one Supabase Auth identity for the emergency Flutter client.
4. Store the old application username as controlled Auth metadata or in a
   protected profile mapping, but do not let the client choose its role.
5. Make the role used by RPC authorization come from a trusted server-side
   mapping/claim, not arbitrary `user_metadata` supplied by the client.
6. Use the same logical role as the existing Production user after verifying
   that role read-only.
7. Keep the original FastAPI `public.user` row untouched so the existing system
   is not disrupted.

For a single user, a minimal protected mapping can associate one Supabase Auth
UUID with the existing `public.user.id` and role. The mapping mechanism must be
chosen only after confirming whether such a profile/mapping table already
exists. No such table was supplied in the current evidence.

## 8. Is a Supabase Auth User Already Present?

This cannot be determined from the current project files or the supplied
Production table schema.

The code is prepared to use an existing Supabase Auth user, but it does not
prove that one exists. The safe decision is:

- If a matching Auth user already exists, use that account and map it to the
  existing `public.user` row without changing the old row.
- If no matching Auth user exists, a Supabase Auth user will eventually need to
  be created through an approved administrative process. That creation has not
  been performed and must not reuse or expose the old hashed password directly.

No conclusion can be made that creation is required until the Auth user list is
checked read-only without exposing passwords or sensitive user data.

## 9. Required Future RLS/RPC Security for One User

Before enabling the direct client fully:

- RLS must remain enabled on all exposed public tables.
- Direct client table writes should remain denied.
- Sensitive writes must use `SECURITY DEFINER` RPCs with a safe
  `search_path`.
- Every write RPC must validate the authenticated Supabase identity and its
  trusted server-side role mapping.
- `Viewer` must be read-only.
- `Data Entry` may perform operational writes.
- `Admin` may perform administrative and Data Entry operations.
- RPCs must validate all input and preserve the old Backend transaction logic.
- RPC execution grants must be limited to the intended authenticated roles.
- The client must contain only the Supabase URL and public/anon client key.
- No database password, `service_role` key, JWT signing secret, or old
  password hash may be placed in Flutter.

## Final Status

- Supabase Auth is used by the new Flutter login code.
- The entered login is converted to an email when a username domain is
  configured.
- Current username display comes from Auth metadata/email.
- Current role display comes from Auth `user_metadata` with a `Viewer` fallback.
- The role is not currently sourced from `public.user`.
- A Production `public.user` to `auth.users` link is not proven.
- The actual role of the existing Production user is not proven.
- It is not known whether a matching Supabase Auth user already exists.
- No database or project files were changed other than this report.
