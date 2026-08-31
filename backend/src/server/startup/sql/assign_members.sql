-- Assign members to a startup
INSERT INTO
    public.startup_membership (startup_id, user_id)
SELECT
    $1 AS startup_id,
    unnest($2::uuid []) AS user_id ON conflict (startup_id, user_id) DO nothing
RETURNING
    user_id;
