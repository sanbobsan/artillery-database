-- ============================================================================
-- СКРИПТ: Создание схем, таблиц (reference, public, calc) и заполнение
-- системных справочников и расчетных таблиц.
-- Версия базы данных: 05
-- ============================================================================

DO $$
BEGIN
    -- ========================================================================
    -- БЛОК 1: Создание схемы reference и справочных таблиц
    -- ========================================================================
    BEGIN
        CREATE SCHEMA IF NOT EXISTS reference;

        -- Удаление старых таблиц и последовательностей (с учетом возможного старого расположения в public)
        DROP TABLE IF EXISTS public.unit_conversions CASCADE;
        DROP TABLE IF EXISTS public.parameters CASCADE;
        DROP TABLE IF EXISTS public.units CASCADE;
        DROP TABLE IF EXISTS public.parameter_types CASCADE;
        DROP TABLE IF EXISTS public.equipment_types CASCADE;
        DROP TABLE IF EXISTS public.military_ranks CASCADE;

        DROP TABLE IF EXISTS reference.unit_conversions CASCADE;
        DROP TABLE IF EXISTS reference.parameters CASCADE;
        DROP TABLE IF EXISTS reference.units CASCADE;
        DROP TABLE IF EXISTS reference.parameter_types CASCADE;
        DROP TABLE IF EXISTS reference.equipment_types CASCADE;
        DROP TABLE IF EXISTS reference.military_ranks CASCADE;

        DROP SEQUENCE IF EXISTS public.seq_military_ranks CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_equipment_types CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_parameter_types CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_units CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_parameters CASCADE;

        DROP SEQUENCE IF EXISTS reference.seq_military_ranks CASCADE;
        DROP SEQUENCE IF EXISTS reference.seq_equipment_types CASCADE;
        DROP SEQUENCE IF EXISTS reference.seq_parameter_types CASCADE;
        DROP SEQUENCE IF EXISTS reference.seq_units CASCADE;
        DROP SEQUENCE IF EXISTS reference.seq_parameters CASCADE;

        -- Счетчики справочников
        CREATE SEQUENCE reference.seq_military_ranks;
        CREATE SEQUENCE reference.seq_equipment_types;
        CREATE SEQUENCE reference.seq_parameter_types;
        CREATE SEQUENCE reference.seq_units;
        CREATE SEQUENCE reference.seq_parameters;

        -- Звания
        CREATE TABLE reference.military_ranks (
            id INT NOT NULL DEFAULT nextval('reference.seq_military_ranks') PRIMARY KEY,
            title VARCHAR(255) NOT NULL UNIQUE
        );
        ALTER SEQUENCE reference.seq_military_ranks OWNED BY reference.military_ranks.id;

        -- Типы оборудования для измерений
        CREATE TABLE reference.equipment_types (
            id INT NOT NULL DEFAULT nextval('reference.seq_equipment_types') PRIMARY KEY,
            title VARCHAR(255) NOT NULL UNIQUE,
            abbreviation VARCHAR(255) NOT NULL UNIQUE
        );
        ALTER SEQUENCE reference.seq_equipment_types OWNED BY reference.equipment_types.id;

        -- Типы параметров
        CREATE TABLE reference.parameter_types (
            id INT NOT NULL DEFAULT nextval('reference.seq_parameter_types') PRIMARY KEY,
            title VARCHAR(255) NOT NULL UNIQUE
        );
        ALTER SEQUENCE reference.seq_parameter_types OWNED BY reference.parameter_types.id;

        -- Единицы измерения
        CREATE TABLE reference.units (
            id INT NOT NULL DEFAULT nextval('reference.seq_units') PRIMARY KEY,
            title VARCHAR(255) NOT NULL UNIQUE,
            abbreviation VARCHAR(255) NOT NULL UNIQUE
        );
        ALTER SEQUENCE reference.seq_units OWNED BY reference.units.id;

        -- Параметры с единицами измерения и допусками
        CREATE TABLE reference.parameters (
            id INT NOT NULL DEFAULT nextval('reference.seq_parameters') PRIMARY KEY,
            parameter_type_id INT NOT NULL REFERENCES reference.parameter_types (id),
            unit_id INT NOT NULL REFERENCES reference.units (id),
            default_value DECIMAL(10, 0) NULL,
            min_value DECIMAL(10, 0) NULL,
            max_value DECIMAL(10, 0) NULL
        );
        ALTER SEQUENCE reference.seq_parameters OWNED BY reference.parameters.id;

        -- Таблица перевода единиц измерения
        CREATE TABLE reference.unit_conversions (
            from_unit_id INT NOT NULL REFERENCES reference.units (id),
            to_unit_id INT NOT NULL REFERENCES reference.units (id),
            from_value DECIMAL(10, 0) NOT NULL,
            to_value DECIMAL(10, 0) NOT NULL,
            PRIMARY KEY (from_unit_id, to_unit_id)
        );

        -- Комментарии к схеме reference
        COMMENT ON TABLE reference.military_ranks IS 'Воинские звания';
        COMMENT ON COLUMN reference.military_ranks.id IS 'Идентификатор звания';
        COMMENT ON COLUMN reference.military_ranks.title IS 'Наименование звания';

        COMMENT ON TABLE reference.equipment_types IS 'Типы оборудования для измерений';
        COMMENT ON COLUMN reference.equipment_types.id IS 'Идентификатор типа оборудования';
        COMMENT ON COLUMN reference.equipment_types.title IS 'Наименование типа оборудования';
        COMMENT ON COLUMN reference.equipment_types.abbreviation IS 'Аббревиатура';

        COMMENT ON TABLE reference.parameter_types IS 'Типы параметров';
        COMMENT ON COLUMN reference.parameter_types.id IS 'Идентификатор типа параметра';
        COMMENT ON COLUMN reference.parameter_types.title IS 'Наименование типа параметра';

        COMMENT ON TABLE reference.units IS 'Единицы измерения';
        COMMENT ON COLUMN reference.units.id IS 'Идентификатор единицы измерения';
        COMMENT ON COLUMN reference.units.title IS 'Наименование единицы измерения';
        COMMENT ON COLUMN reference.units.abbreviation IS 'Аббревиатура';

        COMMENT ON TABLE reference.parameters IS 'Параметры с единицами измерения (не хранит измерения)';
        COMMENT ON COLUMN reference.parameters.id IS 'Идентификатор параметра';
        COMMENT ON COLUMN reference.parameters.parameter_type_id IS 'Ссылка на тип параметра';
        COMMENT ON COLUMN reference.parameters.unit_id IS 'Ссылка на единицу измерения';
        COMMENT ON COLUMN reference.parameters.default_value IS 'Значение по умолчанию';
        COMMENT ON COLUMN reference.parameters.min_value IS 'Минимально допустимое значение';
        COMMENT ON COLUMN reference.parameters.max_value IS 'Максимально допустимое значение';

        COMMENT ON TABLE reference.unit_conversions IS 'Перевод единиц измерения';
        COMMENT ON COLUMN reference.unit_conversions.from_unit_id IS 'Исходная единица измерения';
        COMMENT ON COLUMN reference.unit_conversions.to_unit_id IS 'Целевая единица измерения';
        COMMENT ON COLUMN reference.unit_conversions.from_value IS 'Значение в исходной единице';
        COMMENT ON COLUMN reference.unit_conversions.to_value IS 'Значение в целевой единице';
    END;

    -- ========================================================================
    -- БЛОК 2: Создание основных операционных таблиц в схеме public
    -- ========================================================================
    BEGIN
        DROP TABLE IF EXISTS public.measurements CASCADE;
        DROP TABLE IF EXISTS public.measurements_buckets CASCADE;
        DROP TABLE IF EXISTS public.measurement_batches CASCADE;
        DROP TABLE IF EXISTS public.employees CASCADE;

        DROP SEQUENCE IF EXISTS public.seq_employees CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_measurements_buckets CASCADE;
        DROP SEQUENCE IF EXISTS public.seq_measurement_batches CASCADE;

        CREATE SEQUENCE public.seq_employees;
        CREATE SEQUENCE public.seq_measurement_batches;

        -- Работники
        CREATE TABLE public.employees (
            id INT NOT NULL DEFAULT nextval('public.seq_employees') PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            surname VARCHAR(255) NOT NULL,
            rank_id INT REFERENCES reference.military_ranks (id)
        );
        ALTER SEQUENCE public.seq_employees OWNED BY public.employees.id;

        -- Серии (пачки) измерений (бывшая measurements_buckets)
        CREATE TABLE public.measurement_batches (
            id INT NOT NULL DEFAULT nextval('public.seq_measurement_batches') PRIMARY KEY,
            employee_id INT NOT NULL REFERENCES public.employees (id)
        );
        ALTER SEQUENCE public.seq_measurement_batches OWNED BY public.measurement_batches.id;

        -- Измерения
        CREATE TABLE public.measurements (
            measurement_batch_id INT NOT NULL REFERENCES public.measurement_batches (id),
            equipment_type_id INT NOT NULL REFERENCES reference.equipment_types (id),
            parameter_id INT NOT NULL REFERENCES reference.parameters (id),
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "value" DECIMAL(10, 0) NOT NULL,
            PRIMARY KEY (measurement_batch_id, parameter_id)
        );

        -- Комментарии к схеме public
        COMMENT ON TABLE public.employees IS 'Работники (военнослужащие)';
        COMMENT ON COLUMN public.employees.id IS 'Идентификатор работника';
        COMMENT ON COLUMN public.employees.name IS 'Имя';
        COMMENT ON COLUMN public.employees.surname IS 'Фамилия';
        COMMENT ON COLUMN public.employees.rank_id IS 'Ссылка на звание';

        COMMENT ON TABLE public.measurement_batches IS 'Серии (пачки) измерений';
        COMMENT ON COLUMN public.measurement_batches.id IS 'Идентификатор серии измерений';
        COMMENT ON COLUMN public.measurement_batches.employee_id IS 'Ссылка на работника, сделавшего замер';

        COMMENT ON TABLE public.measurements IS 'Измерения';
        COMMENT ON COLUMN public.measurements.measurement_batch_id IS 'Ссылка на серию (пачку) измерений';
        COMMENT ON COLUMN public.measurements.equipment_type_id IS 'Ссылка на тип оборудования';
        COMMENT ON COLUMN public.measurements.parameter_id IS 'Ссылка на параметр';
        COMMENT ON COLUMN public.measurements.created_at IS 'Дата и время создания измерения';
        COMMENT ON COLUMN public.measurements."value" IS 'Значение измерения';
    END;

    -- ========================================================================
    -- БЛОК 3: Создание схемы calc и расчетных таблиц
    -- ========================================================================
    BEGIN
        CREATE SCHEMA IF NOT EXISTS calc;
        DROP TABLE IF EXISTS calc.temperature_correction CASCADE;

        CREATE TABLE calc.temperature_correction (
            temperature DECIMAL(3, 1) PRIMARY KEY,
            correction DECIMAL(2, 1) NOT NULL
        );

        COMMENT ON TABLE calc.temperature_correction IS 'Температурные поправки';
        COMMENT ON COLUMN calc.temperature_correction.temperature IS 'Температура';
        COMMENT ON COLUMN calc.temperature_correction.correction IS 'Поправка';
    END;

    -- ========================================================================
    -- БЛОК 4: Заполнение справочных (reference) и расчетных (calc) таблиц
    -- ========================================================================
    BEGIN
        -- Очистка и сброс счетчиков справочников
        TRUNCATE TABLE
            reference.unit_conversions,
            reference.parameters,
            reference.units,
            reference.parameter_types,
            reference.equipment_types,
            reference.military_ranks,
            calc.temperature_correction
        CASCADE;

        PERFORM setval('reference.seq_military_ranks', 1, false);
        PERFORM setval('reference.seq_equipment_types', 1, false);
        PERFORM setval('reference.seq_parameter_types', 1, false);
        PERFORM setval('reference.seq_units', 1, false);
        PERFORM setval('reference.seq_parameters', 1, false);

        -- 1. Температурные поправки (calc)
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

        -- 2. Воинские звания (reference)
        INSERT INTO reference.military_ranks (title)
        VALUES
            ('Рядовой'),
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

        -- 3. Типы оборудования (reference)
        INSERT INTO reference.equipment_types (title, abbreviation)
        VALUES
            ('Десантный метеокомплект', 'ДМК'),
            ('Ветровое ружье', 'ВР');

        -- 4. Типы параметров (reference)
        INSERT INTO reference.parameter_types (title)
        VALUES
            ('Высота метеопоста'),
            ('Температура'),
            ('Давление'),
            ('Направление ветра'),
            ('Скорость ветра'),
            ('Дальность сноса пуль');

        -- 5. Единицы измерения (reference)
        INSERT INTO reference.units (title, abbreviation)
        VALUES
            ('Метр', 'м'),
            ('1/10 градуса по Цельсию', '*C/10'),
            ('Миллиметр ртутного столба', 'мм рт. ст.'),
            ('Деление угломера', 'дел. угл.'),
            ('Метр в секунду', 'м/с'),
            ('Градус по Цельсию', '*C');

        -- 6. Параметры (reference)
        INSERT INTO reference.parameters (parameter_type_id, unit_id, default_value, min_value, max_value)
        VALUES
            (1, 1, 100, NULL, NULL), -- Высота: метры
            (2, 2, 150, -580, 580),  -- Температура: 1/10 градуса
            (3, 3, 750, 500, 900),   -- Давление: мм рт. ст.
            (4, 4, 0, 0, 59),        -- Направление ветра: деления угломера
            (5, 5, 0, 0, 15),        -- Скорость ветра: м/с
            (6, 1, 0, 0, 150);       -- Дальность сноса пуль: метры

        -- 7. Конвертация единиц измерения (reference)
        INSERT INTO reference.unit_conversions (from_unit_id, to_unit_id, from_value, to_value)
        VALUES
            (2, 6, 10, 1); -- 10 десятых долей градуса = 1 целый градус
    END;

END $$;