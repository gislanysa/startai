-- select an startup;
SELECT
    s.id,
    s.segment_id,
    s.name,
    s.cnpj,
    s.description,
    s.city,
    s.state,
    s.created_at
FROM
    public.startup AS s
WHERE
    s.id = $1;
