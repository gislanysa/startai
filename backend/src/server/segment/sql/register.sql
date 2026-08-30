-- register a new segment for startups and investors
INSERT INTO
    public.segment(name, description)
VALUES
    ($1, $2)
RETURNING
    id,
    name,
    description;
