CREATE TABLE IF NOT EXISTS auth.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email CITEXT,
  phone_encrypted BYTEA,
  account_status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth.roles (
  id SMALLSERIAL PRIMARY KEY,
  role_name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS auth.account_roles (
  account_id UUID NOT NULL REFERENCES auth.accounts(id) ON DELETE CASCADE,
  role_id SMALLINT NOT NULL REFERENCES auth.roles(id) ON DELETE RESTRICT,
  PRIMARY KEY (account_id, role_id)
);

CREATE TABLE IF NOT EXISTS auth.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES auth.accounts(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ
);

INSERT INTO auth.roles(role_name)
VALUES ('user'), ('driver'), ('mechanic'), ('admin')
ON CONFLICT (role_name) DO NOTHING;
