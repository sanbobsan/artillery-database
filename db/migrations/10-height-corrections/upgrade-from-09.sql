-- ============================================================================
-- СКРИПТ МИГРАЦИИ 10: Таблицы для корректировок по высоте
-- ============================================================================

DO $$
BEGIN
    -- ========================================================================
    -- 1. Создание структур (Таблицы и связи)
    -- ========================================================================

    -- Таблица высот
    CREATE SEQUENCE IF NOT EXISTS calc.correction_heights_seq;
    CREATE TABLE calc.correction_heights (
        id INT PRIMARY KEY DEFAULT nextval('calc.correction_heights_seq'),
        height INT NOT NULL UNIQUE
    );
    ALTER SEQUENCE calc.correction_heights_seq OWNED BY calc.correction_heights.id;
    
    COMMENT ON TABLE calc.correction_heights IS 'Таблица стандартных высот';
    COMMENT ON COLUMN calc.correction_heights.id IS 'Уникальный код';
    COMMENT ON COLUMN calc.correction_heights.height IS 'Высота';

    -- Заголовки матриц
    CREATE SEQUENCE IF NOT EXISTS calc.correction_headers_seq;
    CREATE TABLE calc.correction_headers (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('calc.correction_headers_seq'),
        description TEXT NOT NULL,
        header_values INT[] NOT NULL
    );
    ALTER SEQUENCE calc.correction_headers_seq OWNED BY calc.correction_headers.id;
    
    COMMENT ON TABLE calc.correction_headers IS 'Заголовки для таблиц корректировок';
    COMMENT ON COLUMN calc.correction_headers.id IS 'Уникальный код';
    COMMENT ON COLUMN calc.correction_headers.description IS 'Описание';
    COMMENT ON COLUMN calc.correction_headers.header_values IS 'Массив значений заголовка';

    -- Справочник типов таблиц корректировок
    CREATE SEQUENCE IF NOT EXISTS calc.correction_types_seq;
    CREATE TABLE calc.correction_types (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('calc.correction_types_seq'),
        parent_id INT REFERENCES calc.correction_types(id) ON DELETE CASCADE,
        measurment_equipment_id INT REFERENCES reference.equipment_types(id) ON DELETE CASCADE, 
        header_id INT REFERENCES calc.correction_headers(id) ON DELETE SET NULL,
        description TEXT NOT NULL
    );
    ALTER SEQUENCE calc.correction_types_seq OWNED BY calc.correction_types.id;

    COMMENT ON TABLE calc.correction_types IS 'Справочник типов таблиц';
    COMMENT ON COLUMN calc.correction_types.id IS 'Уникальный код';
    COMMENT ON COLUMN calc.correction_types.parent_id IS 'Уникальный код родителя';
    COMMENT ON COLUMN calc.correction_types.measurment_equipment_id IS 'Тип оборудования';
    COMMENT ON COLUMN calc.correction_types.header_id IS 'Код заголовка';
    COMMENT ON COLUMN calc.correction_types.description IS 'Описание';

    -- Таблица корректировок
    CREATE SEQUENCE IF NOT EXISTS calc.corrections_seq;
    CREATE TABLE calc.corrections (
        id integer NOT NULL PRIMARY KEY DEFAULT nextval('calc.corrections_seq'),
        height_id integer NOT NULL REFERENCES calc.correction_heights(id) ON DELETE CASCADE,
        correction_type_id integer NOT NULL REFERENCES calc.correction_types(id) ON DELETE CASCADE,
        row_values integer[] NOT NULL
    );
    ALTER SEQUENCE calc.corrections_seq OWNED BY calc.corrections.id;

    COMMENT ON TABLE calc.corrections IS 'Универсальная таблица корректировок';
    COMMENT ON COLUMN calc.corrections.id IS 'Уникальный код';
    COMMENT ON COLUMN calc.corrections.height_id IS 'Код высоты';
    COMMENT ON COLUMN calc.corrections.correction_type_id IS 'Код типа таблиц';
    COMMENT ON COLUMN calc.corrections.row_values IS 'Массив значений корректировок';

    -- ========================================================================
    -- 2. Наполнение данными
    -- ========================================================================

    -- Высоты
    INSERT INTO calc.correction_heights(id, height)
    VALUES (1, 200), (2, 400), (3, 800), (4, 1200), (5, 1600), (6, 2000), (7, 2400), (8, 3000), (9, 4000)
    ON CONFLICT (id) DO NOTHING;

    -- Заголовки
    INSERT INTO calc.correction_headers(id, description, header_values)
    VALUES
    (1, 'Отклонения температур (Таблица 2)', array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), 
    (2, 'Дальность сноса пуль ВР (Таблица 3)', array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), 
    (3, 'Скорость приземного ветра ДМК (Таблица 3)', array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    ON CONFLICT (id) DO NOTHING;

    -- Типы корректировок
    INSERT INTO calc.correction_types(id, description, parent_id, measurment_equipment_id, header_id)
    VALUES
    (1, 'Таблица 2', NULL, NULL, NULL),
    (2, 'Таблица 3, скорость среднего ветра', NULL, NULL, NULL),
    (3, 'Таблица 3, направление среднего ветра', NULL, NULL, NULL),
    (4, 'Таблица 2, Положительные температуры', 1, NULL, 1),   
    (5, 'Таблица 2, Отрицательные температуры', 1, NULL, 1),
    (6, 'Таблица 3, Скорость среднего ветра (ВР)', 2, 2, 2),   
    (7, 'Таблица 3, Направление среднего ветра (ВР)', 3, 2, NULL), 
    (8, 'Таблица 3, Скорость среднего ветра (ДМК)', 2, 1, 3),  
    (9, 'Таблица 3, Направление среднего ветра (ДМК)', 3, 1, NULL)
    ON CONFLICT (id) DO NOTHING;

    -- Корректировки
    INSERT INTO calc.corrections(height_id, correction_type_id, row_values)
    VALUES
    -- Таблица 2, Отрицательные значения (correction_type_id = 5)
    (1, 5, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), 
    (2, 5, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]), 
    (3, 5, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), 
    (4, 5, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), 
    (5, 5, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]),
    (6, 5, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]),
    (7, 5, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]),
    (8, 5, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]),
    (9, 5, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]),
    
    -- Таблица 2, Положительные значения (correction_type_id = 4)
    (1, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 39, 49]), 
    (2, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 38, 48]), 
    (3, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 37, 46]), 
    (4, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 35, 44]), 
    (5, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 34, 42]),
    (6, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 32, 40]),
    (7, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 31, 38]),
    (8, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 30, 37]),
    (9, 4, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 27, 34]),
    
    -- Таблица 3, Скорость среднего ветра (ВР) (correction_type_id = 6)
    (1, 6, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), 
    (2, 6, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), 
    (3, 6, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]), 
    (4, 6, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]), 
    (5, 6, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]),
    (6, 6, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]),
    (7, 6, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]),
    (8, 6, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]),
    (9, 6, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]),
    
    -- Таблица 3, Скорость среднего ветра (ДМК) (correction_type_id = 8)
    (1, 8, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]), 
    (2, 8, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]), 
    (3, 8, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]), 
    (4, 8, array[5, 8, 11, 12, 13, 16, 19, 20, 23, 24, 26, 28, 30]), 
    (5, 8, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]),
    (6, 8, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]),
    (7, 8, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]),
    (8, 8, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]),
    (9, 8, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]),

    -- Таблица 3, Направление среднего ветра (ВР) (correction_type_id = 7) 
    (1, 7, array[0]), 
    (2, 7, array[100]), 
    (3, 7, array[200]), 
    (4, 7, array[200]), 
    (5, 7, array[300]),
    (6, 7, array[300]),
    (7, 7, array[300]),
    (8, 7, array[400]),
    (9, 7, array[400]),
    
    -- Таблица 3, Направление среднего ветра (ДМК) (correction_type_id = 9) 
    (1, 9, array[100]), 
    (2, 9, array[200]), 
    (3, 9, array[300]), 
    (4, 9, array[300]),
    (5, 9, array[400]),
    (6, 9, array[400]),
    (7, 9, array[400]),
    (8, 9, array[500]),
    (9, 9, array[500]);
    
    -- Синхронизация SEQUENCE
    PERFORM setval('calc.correction_heights_seq', (SELECT MAX(id) FROM calc.correction_heights));
    PERFORM setval('calc.correction_types_seq', (SELECT MAX(id) FROM calc.correction_types));
    PERFORM setval('calc.correction_headers_seq', (SELECT MAX(id) FROM calc.correction_headers));
    PERFORM setval('calc.corrections_seq', (SELECT MAX(id) FROM calc.corrections));

END $$;
