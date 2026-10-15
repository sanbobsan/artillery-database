-- Просмотр существующих метаданных

SELECT * FROM (
    -- Таблицы
    SELECT table_name AS name,
        CASE table_type
            WHEN 'BASE TABLE' then 'Таблица'
            ELSE table_type
        END AS type
    FROM information_schema.tables
    WHERE table_schema IN ('public', 'calc')

    UNION ALL
    -- Последовательности
    SELECT sequence_name AS name, 'Последовательность' AS type
    FROM information_schema.sequences
    WHERE sequence_schema = 'public'
);
