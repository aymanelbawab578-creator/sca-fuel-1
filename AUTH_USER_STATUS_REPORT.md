# Auth User Status Report

## Scope and Safety

This is a read-only review of the project files and supplied schema/backups.

No SQL was executed. No user was created or modified. No password was changed.
No database write was performed. No password, password hash, service key, or
secret is included in this report.

## 1. Evidence of an Existing Supabase Auth User

No evidence of an existing Supabase Auth user was found in the project files.

The Flutter code is prepared to use Supabase Auth, but the repository does not
contain a persisted Auth session, Auth user UUID, or Auth email. The code only
reads the current Auth user at runtime after a successful login.

There is also no exported `auth.users` metadata in the supplied information.

Conclusion: an Auth user may exist in the Supabase project, but its existence
cannot be established from the project files available here.

## 2. Known Auth User ID or Email

No Supabase Auth user ID or email is known from the project.

The code contains no hard-coded Auth UUID or email. It obtains the email/user
at runtime from the Supabase Auth session.

No secret values were inspected or included.

## 3. Username-to-Email Domain

The new Flutter code supports the compile-time setting:

`SCA_USERNAME_EMAIL_DOMAIN`

It is read from `String.fromEnvironment()` in `lib/config/app_config.dart`.

No configured domain value was found in the project files. Therefore:

- A login value containing `@` is passed to Supabase Auth as an email.
- A username without `@` fails unless `SCA_USERNAME_EMAIL_DOMAIN` is supplied
  at runtime/build time.
- The repository does not reveal the actual domain used by Production.

## 4. Role of the Single Production User

The current Production role cannot be determined safely from the available
information.

The supplied Production schema only identifies `public.user.role` as
`USER-DEFINED`; it does not include the enum type definition or current role
rows.

Historical backup files contain role information, but they are explicitly not
Production evidence and must not be used to infer the current Production user.
They also contain more than one historical user, so they cannot identify the
single active user requested here.

The Flutter code currently uses this fallback behavior:

`user.userMetadata['role'] ?? 'Viewer'`

That is Auth metadata, not a verified read from `public.user.role`.

## 5. Missing Information Needed to Determine the Role

Only the following non-sensitive read-only metadata is needed:

- The actual `public.user.role` value for the intended user, with passwords and
  password hashes excluded.
- The role enum/type values, if needed to interpret the value.
- A non-sensitive identifier for the intended user, such as `public.user.id`
  and username.
- A verified mapping between that user and a Supabase Auth UUID, if one exists.

No password or password hash is needed.

## 6. Existing Mapping Between Supabase Auth and `public.user`

No mapping is present in the project code or supplied schema.

Evidence:

- `public.user` has an integer `id` and username fields.
- The supplied schema does not show an `auth.users.id` UUID column or foreign
  key.
- Flutter reads `Supabase.instance.client.auth.currentUser` and its metadata.
- Flutter does not join or query `public.user` for the current Auth identity.

Conclusion: no current mapping is demonstrated. The live database must be
checked read-only to determine whether an external profile/mapping table or
metadata convention exists.

## 7. Simplest Safe Next Step

For one user, the safest next step is:

1. Read-only verify whether a Supabase Auth account already exists, using only
   its non-sensitive UUID/email status.
2. Read-only verify the intended `public.user` username/id/role without selecting
   password or hashed-password columns.
3. If an Auth account already exists, map that Auth UUID to the existing logical
   user without changing the existing `public.user` row.
4. If no Auth account exists, create one later through an approved Auth admin
   process, without copying the old password hash into Flutter and without
   deleting or changing the existing `public.user` row.
5. Put the trusted role mapping behind server-controlled Auth claims or a
   protected mapping mechanism. Do not authorize RPCs from client-editable
   `user_metadata`.
6. Keep Flutter configured with only the Supabase URL and public/anon client
   key.

No step above has been executed.

## Final Status

- Supabase Auth integration exists in Flutter code.
- No Auth user ID or email is known from the project.
- `SCA_USERNAME_EMAIL_DOMAIN` exists as a configuration hook, but no value is
  configured in the repository.
- The current Production role is not determinable from the provided data.
- Historical backups are not valid evidence of current Production user state.
- No Auth-to-`public.user` mapping is demonstrated.
- No database, user, password, policy, RPC, or project file was modified other
  than this report.
