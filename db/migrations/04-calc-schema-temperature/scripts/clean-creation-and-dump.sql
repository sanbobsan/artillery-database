-- Чистое создание базы данных версии 04 с заполнением данными с нуля

-- Миграция с сохранением данных возможна, если использовать скрипты для миграций,
-- но в данном случае мы заполняем данные с нуля, поэтому создавать бд с нуля нагляднее и менее расходно

-- В одной транзакции выполняется несколько транзакций,
-- если хоть одна упадет, то ничего не выполнится

DO $$
BEGIN
    -- Блок pgSQL для создания таблиц
    BEGIN 
        -- Удаляем, если были до этого
        DROP TABLE IF EXISTS unit_conversions CASCADE;
        DROP TABLE IF EXISTS measurements CASCADE;
        DROP TABLE IF EXISTS measurements_buckets CASCADE;
        DROP TABLE IF EXISTS parameters CASCADE;
        DROP TABLE IF EXISTS units CASCADE;
        DROP TABLE IF EXISTS parameter_types CASCADE;
        DROP TABLE IF EXISTS equipment_types CASCADE;
        DROP TABLE IF EXISTS employees CASCADE;
        DROP TABLE IF EXISTS military_ranks CASCADE;

        DROP SEQUENCE IF EXISTS seq_military_ranks;
        DROP SEQUENCE IF EXISTS seq_employees;
        DROP SEQUENCE IF EXISTS seq_equipment_types;
        DROP SEQUENCE IF EXISTS seq_parameter_types;
        DROP SEQUENCE IF EXISTS seq_units;
        DROP SEQUENCE IF EXISTS seq_parameters;
        DROP SEQUENCE IF EXISTS seq_measurements_buckets;

        -- Счетчики
        CREATE SEQUENCE seq_military_ranks;
        CREATE SEQUENCE seq_employees;
        CREATE SEQUENCE seq_equipment_types;
        CREATE SEQUENCE seq_parameter_types;
        CREATE SEQUENCE seq_units;
        CREATE SEQUENCE seq_parameters;
        CREATE SEQUENCE seq_measurements_buckets;

        -- Звания
        CREATE TABLE military_ranks (
            id INT NOT NULL DEFAULT nextval('seq_military_ranks') PRIMARY KEY,
            title VARCHAR(100) NOT NULL UNIQUE
        );
        ALTER SEQUENCE seq_military_ranks OWNED BY military_ranks.id;

        -- Работники
        CREATE TABLE employees (
            id INT NOT NULL DEFAULT nextval('seq_employees') PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            surname VARCHAR(100) NOT NULL,
            rank_id INT REFERENCES military_ranks (id)
        );
        ALTER SEQUENCE seq_employees OWNED BY employees.id;

        -- Типы оборудования для измерений
        CREATE TABLE equipment_types (
            id INT NOT NULL DEFAULT nextval('seq_equipment_types') PRIMARY KEY,
            title VARCHAR(100) NOT NULL UNIQUE,
            abbreviation VARCHAR(20) NOT NULL UNIQUE
        );
        ALTER SEQUENCE seq_equipment_types OWNED BY equipment_types.id;

        -- Типы параметров, возможные параметры без единиц измерения
        CREATE TABLE parameter_types (
            id INT NOT NULL DEFAULT nextval('seq_parameter_types') PRIMARY KEY,
            title VARCHAR(100) NOT NULL UNIQUE
        );
        ALTER SEQUENCE seq_parameter_types OWNED BY parameter_types.id;

        -- Единицы измерения
        CREATE TABLE units (
            id INT NOT NULL DEFAULT nextval('seq_units') PRIMARY KEY,
            title VARCHAR(100) NOT NULL UNIQUE,
            abbreviation VARCHAR(20) NOT NULL UNIQUE
        );
        ALTER SEQUENCE seq_units OWNED BY units.id;

        -- Параметры с единицами измерения, не хранит измерения
        CREATE TABLE parameters (
            id INT NOT NULL DEFAULT nextval('seq_parameters') PRIMARY KEY,
            parameter_type_id INT NOT NULL REFERENCES parameter_types (id),
            unit_id INT NOT NULL REFERENCES units (id),
            default_value DECIMAL(10, 0) NULL,
            min_value DECIMAL(10, 0) NULL,
            max_value DECIMAL(10, 0) NULL
        );
        ALTER SEQUENCE seq_parameters OWNED BY parameters.id;

        -- Пачки измерений
        CREATE TABLE measurements_buckets (
            id INT NOT NULL DEFAULT nextval('seq_measurements_buckets') PRIMARY KEY,
            employee_id INT NOT NULL REFERENCES employees (id)
        );
        ALTER SEQUENCE seq_measurements_buckets OWNED BY measurements_buckets.id;

        -- Измерения.
        CREATE TABLE measurements (
            measurements_bucket_id INT NOT NULL REFERENCES measurements_buckets (id),
            equipment_type_id INT NOT NULL REFERENCES equipment_types (id),
            parameter_id INT NOT NULL REFERENCES parameters (id),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            "value" DECIMAL(10, 0) NOT NULL,
            PRIMARY KEY (measurements_bucket_id, parameter_id)
        );

        -- Таблица перевода единиц измерения.
        CREATE TABLE unit_conversions (
            from_unit_id INT NOT NULL REFERENCES units (id),
            to_unit_id INT NOT NULL REFERENCES units (id),
            from_value DECIMAL(10, 0),
            to_value DECIMAL(10, 0),
            PRIMARY KEY (from_unit_id, to_unit_id)
        );
        COMMIT; -- Делаем коммит, таким образом выделяем транзакцию
    END; -- Блок закончился

    -- Блок pgSQL для создания расчетных таблиц
    BEGIN
        CREATE SCHEMA IF NOT EXISTS calc;
        DROP TABLE IF EXISTS calc.temperature_correction CASCADE;

        CREATE TABLE calc.temperature_correction (
            temperature DECIMAL(3, 1) PRIMARY KEY,
            correction DECIMAL(2, 1) NOT NULL
        );
        -- Данные этих таблиц зашиты в базу данных, поэтому их изменение считаются миграцией
        INSERT INTO calc.temperature_correction (temperature, correction) 
        VALUES
            (0, 0.0),
            (5, 0.5),
            (10, 1.0),
            (15, 1.0),
            (20, 1.5),
            (25, 2.0),
            (30, 3.5),
            (40, 4.5)
        ON CONFLICT (temperature) DO NOTHING;
        COMMIT; -- Делаем коммит, таким образом выделяем транзакцию
    END; -- Блок закончился

    BEGIN -- Блок pgSQL для заполнениями данными таблиц, которые лежат в схеме public
          -- Разделение на справочники и меняющиеся данные пока что мнимое

            -- ================== ОЧИСТКА ==================

            TRUNCATE TABLE military_ranks, employees, equipment_types, parameter_types,
                units, parameters, unit_conversions, measurements_buckets, measurements
                CASCADE;

            PERFORM setval('seq_military_ranks', 1, false);
            PERFORM setval('seq_employees', 1, false);
            PERFORM setval('seq_equipment_types', 1, false);
            PERFORM setval('seq_parameter_types', 1, false);
            PERFORM setval('seq_units', 1, false);
            PERFORM setval('seq_parameters', 1, false);
            PERFORM setval('seq_measurements_buckets', 1, false);

            -- ================== ЗАШИТЫЕ СПРАВОЧНИКИ ==================

            -- Воинские звания
            INSERT INTO military_ranks (title)
            VALUES ('Рядовой'),
                ('Ефрейтор'),
                ('Младший сержант'),
                ('Сержант'),
                ('Старший сержант'),
                ('Старшина'),
                ('Прапорщик'),
                ('Старший прапорщик'),
                ('Младший лейтенант'),
                ('Лейтенант'),
                ('Старший лейтенант'),
                ('Капитан'),
                ('Майор'),
                ('Подполковник'),
                ('Полковник');

            -- Оборудование
            INSERT INTO equipment_types (title, abbreviation)
            VALUES ('Десантный метеокомплект', 'ДМК'),
                ('Ветровое ружье', 'ВР');

            -- Типы параметров
            INSERT INTO parameter_types (title)
            VALUES ('Высота метеопоста'),
                ('Температура'),
                ('Давление'),
                ('Направление ветра'),
                ('Скорость ветра'),
                ('Дальность сноса пуль');

            -- Единицы измерения
            INSERT INTO units (title, abbreviation)
            VALUES ('Метр', 'м'),
                ('1/10 градуса по Цельсию', '*C/10'),
                ('Миллиметр ртутного столба', 'мм рт. ст.'),
                ('Деление угломера', 'дел. угл.'),
                ('Метр в секунду', 'м/с'),
                ('Градус по Цельсию', '*C');

            -- Параметры: связка типа и единицы измерения, значения по умолчанию, допуски
            INSERT INTO parameters (parameter_type_id, unit_id, default_value, min_value, max_value)
            VALUES (1, 1, 100, NULL, NULL), -- Высота: метры
                (2, 2, 150, -580, 580), -- Температура: 1/10 градуса
                (3, 3, 750, 500, 900), -- Давление: мм рт. ст.
                (4, 4, 0, 0, 59), -- Направление ветра: деления угломера
                (5, 5, 0, 0, 15), -- Скорость ветра: м/с
                (6, 1, 0, 0, 150); -- Дальность сноса пуль: тоже метры

            -- Конвертация единиц измерения
            INSERT INTO unit_conversions (from_unit_id, to_unit_id, from_value, to_value)
            VALUES (2, 6, 10, 1); -- 1/10 градуса = 1 целый градус

            -- ================== РАБОЧИЕ ДАННЫЕ ==================

            -- Сотрудники
            INSERT INTO employees (name, surname, rank_id)
            VALUES ('Иван', 'Иванов', 1), -- Рядовой
                ('Петр', 'Петров', 2), -- Ефрейтор
                ('Алексей', 'Сидоров', 3), -- Младший сержант
                ('Иван', 'Смирнов', 4), -- Сержант
                ('Дмитрий', 'Козлов', 5), -- Старший сержант
                ('Николай', 'Егоров', 12), -- Капитан
                ('Андрей', 'Волков', 11), -- Старший лейтенант
                ('Сергей', 'Фролов', 10); -- Лейтенант

            -- Пачки измерений
            INSERT INTO measurements_buckets (employee_id)
            VALUES (1), -- Пачка 1: сотрудник 1
                (2), -- Пачка 2: сотрудник 2
                (3), -- Пачка 3: сотрудник 3
                (4), -- Пачка 4: сотрудник 4
                (5), -- Пачка 5: сотрудник 5
                (6), -- Пачка 6: сотрудник 6
                (7), -- Пачка 7: сотрудник 7
                (8); -- Пачка 8: сотрудник 8

            -- Измерения.
            INSERT INTO measurements (
                measurements_bucket_id,
                equipment_type_id,
                parameter_id,
                "value"
            )
            VALUES
                -- Пачка 1 (ДМК, сотрудник 1)
                (1, 1, 1, 101), -- Высота: 101 м
                (1, 1, 2, 250), -- Температура: 25.0 *C (250 десятых)
                (1, 1, 3, 751), -- Давление: 751 мм рт. ст.
                (1, 1, 4, 45), -- Направление ветра: 45 дел. угл.
                (1, 1, 5, 6), -- Скорость ветра: 6 м/с
                -- Пачка 2 (ДМК, сотрудник 2)
                (2, 1, 1, 97), -- Высота: 97 м
                (2, 1, 2, 121), -- Температура: 12.1 *C (121 десятая)
                (2, 1, 3, 748), -- Давление: 748 мм рт. ст.
                (2, 1, 4, 12), -- Направление ветра: 12 дел. угл.
                (2, 1, 5, 4), -- Скорость ветра: 4 м/с
                -- Пачка 3 (Ветровое ружье, сотрудник 3)
                (3, 2, 1, 60), -- Высота: 60 м
                (3, 2, 2, -100), -- Температура: -10.0 *C (-100 десятых)
                (3, 2, 3, 782), -- Давление: 782 мм рт. ст.
                (3, 2, 4, 30), -- Направление ветра: 30 дел. угл.
                (3, 2, 6, 88), -- Дальность сноса пуль: 88 м
                -- Пачка 4 (ДМК, сотрудник 4)
                (4, 1, 1, 140), -- Высота: 140 м
                (4, 1, 2, 310), -- Температура: 31.0 *C (310 десятых)
                (4, 1, 3, 739), -- Давление: 739 мм рт. ст.
                (4, 1, 4, 5), -- Направление ветра: 5 дел. угл.
                (4, 1, 5, 9), -- Скорость ветра: 9 м/с
                -- Пачка 5 (Ветровое ружье, сотрудник 5)
                (5, 2, 1, 95), -- Высота: 95 м
                (5, 2, 2, 42), -- Температура: 4.2 *C (42 десятых)
                (5, 2, 3, 762), -- Давление: 762 мм рт. ст.
                (5, 2, 4, 59), -- Направление ветра: 59 дел. угл.
                (5, 2, 6, 45), -- Дальность сноса пуль: 45 м
                -- Пачка 6 (Ветровое ружье, сотрудник 6)
                (6, 2, 1, 130), -- Высота: 130 м
                (6, 2, 2, -215), -- Температура: -21.5 *C (-215 десятых)
                (6, 2, 3, 803), -- Давление: 803 мм рт. ст.
                (6, 2, 4, 25), -- Направление ветра: 25 дел. угл.
                (6, 2, 6, 120), -- Дальность сноса пуль: 120 м
                -- Пачка 7 (ДМК, сотрудник 7)
                (7, 1, 1, 105), -- Высота: 105 м
                (7, 1, 2, 197), -- Температура: 19.7 *C (197 десятых)
                (7, 1, 3, 755), -- Давление: 755 мм рт. ст.
                (7, 1, 4, 0), -- Направление ветра: 0 дел. угл.
                (7, 1, 5, 2), -- Скорость ветра: 2 м/с
                -- Пачка 8 (ДМК, сотрудник 8)
                (8, 1, 1, 85), -- Высота: 85 м
                (8, 1, 2, 5), -- Температура: 0.5 *C (5 десятых)
                (8, 1, 3, 771), -- Давление: 771 мм рт. ст.
                (8, 1, 4, 17), -- Направление ветра: 17 дел. угл.
                (8, 1, 5, 11); -- Скорость ветра: 11 м/с
        COMMIT; -- Делаем коммит, таким образом выделяем транзакцию
    END; -- Блок pgSQL закончился

END $$;