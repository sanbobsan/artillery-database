-- DQL Data Query Language

SELECT
    m.id,
    m.created_at,
    u.name,
    u.surname,
    r.title AS rank,
    e.title AS equipment,
    p.station_height,
    p.temperature,
    p.pressure,
    p.wind_direction,
    p.wind_speed,
    p.bullet_drift_distance
FROM
    measurements m
    JOIN users u ON u.id = m.user_id
    JOIN ranks r ON r.id = u.rank_id
    JOIN parameters p ON p.id = m.parameters_id
    JOIN equipment_types e ON e.id = p.equipment_type_id;