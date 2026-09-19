-- DML Data Manipulation Language

INSERT INTO
    "ranks" ("title")
VALUES ('Рядовой'),
    ('Сержант'),
    ('Лейтенант'),
    ('Капитан')
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    "equipment_types" ("id", "title", "abbreviation")
VALUES (
        1,
        'Десантный метео комплект',
        'ДМК'
    ),
    (2, 'Ветровое ружье', 'ВР')
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    "users" ("name", "surname", "rank_id")
VALUES ('Иван', 'Иванов', 1),
    ('Петр', 'Петров', 2),
    ('Алексей', 'Сидоров', 3),
    ('Иван', 'Смирнов', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    "parameters" (
        "equipment_type_id",
        "station_height",
        "temperature",
        "pressure",
        "wind_direction",
        "wind_speed"
    )
VALUES (1, 101, 26.4, 762, 55, 8),
    (1, 105, 22.1, 734, 12, 3)
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    "parameters" (
        "equipment_type_id",
        "station_height",
        "temperature",
        "pressure",
        "wind_direction",
        "bullet_drift_distance"
    )
VALUES (2, 160, -10.0, 670, 12, 72)
ON CONFLICT (id) DO NOTHING;

INSERT INTO
    "measurements" ("user_id", "parameters_id")
VALUES (1, 1),
    (3, 2),
    (4, 3)
ON CONFLICT (id) DO NOTHING;