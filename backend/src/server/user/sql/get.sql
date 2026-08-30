-- select an user;
SELECT
    u.id,
    u.full_name,
    u.email,
    u.password_hash,
    u.created_at,
    u.is_active
FROM
    public.user_account AS u
WHERE
    u.id = $1;
