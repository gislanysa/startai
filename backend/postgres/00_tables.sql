CREATE TABLE user_account (
    id uuid UNIQUE NOT NULL DEFAULT uuidv7(),
    full_name text NOT NULL,
    password_hash text NOT NULL,
    email text UNIQUE NOT NULL CHECK (email LIKE '%@%'),
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active boolean NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id)
);

CREATE TABLE segment (
    id uuid UNIQUE NOT NULL DEFAULT uuidv7(),
    name text NOT NULL,
    description text NOT NULL
);

CREATE TABLE startup (
    id uuid UNIQUE NOT NULL DEFAULT uuidv7(),
    segment_id uuid NOT NULL REFERENCES segment (id),
    name text NOT NULL,
    cnpj text UNIQUE NOT NULL CHECK (length(cnpj) = 14),
    description text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

CREATE TABLE startup_membership (
    user_id uuid REFERENCES user_account (id) ON DELETE CASCADE,
    startup_id uuid REFERENCES startup (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, startup_id)
);

CREATE TYPE investor_kind AS enum (
    'angel',
    'venture',
    'individual',
    'institutional'
);

CREATE TABLE investor (
    id uuid UNIQUE NOT NULL DEFAULT uuidv7(),
    user_id uuid REFERENCES user_account (id),
    segment_id uuid REFERENCES segment (id),
    kind investor_kind NOT NULL,
    public_profile boolean NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id)
);
