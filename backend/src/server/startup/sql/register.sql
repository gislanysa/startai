-- register a new startup on the database
INSERT INTO
    public.startup (
        segment_id,
        name,
        cnpj,
        description,
        city,
        state
    )
VALUES
    ($1, $2, $3, $4, $5, $6)
RETURNING
    id,
    segment_id,
    name,
    cnpj,
    description,
    city,
    state,
    created_at;
