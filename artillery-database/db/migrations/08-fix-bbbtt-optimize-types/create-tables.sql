-- ============================================================================
-- СКРИПТ: Создание БД с нуля (состояние на версию 08)
-- Объединяет структуры и данные версий 01-07 и исправления версии 08.
-- ============================================================================

DO $$
BEGIN
    -- ========================================================================
    -- БЛОК 1: Очистка и создание схем
    -- ========================================================================
    CREATE SCHEMA IF NOT EXISTS reference;
    CREATE SCHEMA IF NOT EXISTS calc;
    CREATE SCHEMA IF NOT EXISTS public;

    DROP TYPE IF EXISTS calc.interpolation_params CASCADE;
    DROP TYPE IF EXISTS calc.parameters_list CASCADE;

    DROP TABLE IF EXISTS public.measurements CASCADE;
    DROP TABLE IF EXISTS public.measurement_batches CASCADE;
    DROP TABLE IF EXISTS public.employees CASCADE;

    DROP TABLE IF EXISTS reference.unit_conversions CASCADE;
    DROP TABLE IF EXISTS reference.parameter_errors CASCADE;
    DROP TABLE IF EXISTS reference.parameters CASCADE;
    DROP TABLE IF EXISTS reference.units CASCADE;
    DROP TABLE IF EXISTS reference.parameter_types CASCADE;
    DROP TABLE IF EXISTS reference.equipment_types CASCADE;
    DROP TABLE IF EXISTS reference.military_ranks CASCADE;

    DROP TABLE IF EXISTS calc.temperature_correction CASCADE;
    DROP TABLE IF EXISTS calc.constants CASCADE;

    DROP SEQUENCE IF EXISTS public.seq_employees CASCADE;
    DROP SEQUENCE IF EXISTS public.seq_measurement_batches CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_military_ranks CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_equipment_types CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_parameter_types CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_units CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_parameters CASCADE;
    DROP SEQUENCE IF EXISTS reference.seq_parameter_errors CASCADE;

    -- ========================================================================
    -- БЛОК 2: Справочные таблицы (схема reference)
    -- ========================================================================
    CREATE SEQUENCE reference.seq_military_ranks;
    CREATE TABLE reference.military_ranks (
        id INT NOT NULL DEFAULT nextval('reference.seq_military_ranks') PRIMARY KEY,
        title VARCHAR(255) NOT NULL UNIQUE
    );
    ALTER SEQUENCE reference.seq_military_ranks OWNED BY reference.military_ranks.id;

    CREATE SEQUENCE reference.seq_equipment_types;
    CREATE TABLE reference.equipment_types (
        id INT NOT NULL DEFAULT nextval('reference.seq_equipment_types') PRIMARY KEY,
        title VARCHAR(255) NOT NULL UNIQUE,
        abbreviation VARCHAR(255) NOT NULL UNIQUE
    );
    ALTER SEQUENCE reference.seq_equipment_types OWNED BY reference.equipment_types.id;

    CREATE SEQUENCE reference.seq_parameter_types;
    CREATE TABLE reference.parameter_types (
        id INT NOT NULL DEFAULT nextval('reference.seq_parameter_types') PRIMARY KEY,
        title VARCHAR(255) NOT NULL UNIQUE
    );
    ALTER SEQUENCE reference.seq_parameter_types OWNED BY reference.parameter_types.id;

    CREATE SEQUENCE reference.seq_units;
    CREATE TABLE reference.units (
        id INT NOT NULL DEFAULT nextval('reference.seq_units') PRIMARY KEY,
        title VARCHAR(255) NOT NULL UNIQUE,
        abbreviation VARCHAR(255) NOT NULL UNIQUE
    );
    ALTER SEQUENCE reference.seq_units OWNED BY reference.units.id;

    CREATE SEQUENCE reference.seq_parameters;
    CREATE TABLE reference.parameters (
        id INT NOT NULL DEFAULT nextval('reference.seq_parameters') PRIMARY KEY,
        parameter_type_id INT NOT NULL REFERENCES reference.parameter_types (id),
        unit_id INT NOT NULL REFERENCES reference.units (id),
        default_value INTEGER NULL,
        min_value INTEGER NULL,
        max_value INTEGER NULL
    );
    ALTER SEQUENCE reference.seq_parameters OWNED BY reference.parameters.id;

    CREATE TABLE reference.unit_conversions (
        from_unit_id INT NOT NULL REFERENCES reference.units (id),
        to_unit_id INT NOT NULL REFERENCES reference.units (id),
        from_value INTEGER NOT NULL,
        to_value INTEGER NOT NULL,
        PRIMARY KEY (from_unit_id, to_unit_id)
    );

    CREATE SEQUENCE reference.seq_parameter_errors;
    CREATE TABLE reference.parameter_errors (
        id INT NOT NULL DEFAULT nextval('reference.seq_parameter_errors') PRIMARY KEY,
        parameter_id INT REFERENCES reference.parameters (id) ON DELETE CASCADE,
        error_message VARCHAR(255) NOT NULL
    );
    ALTER SEQUENCE reference.seq_parameter_errors OWNED BY reference.parameter_errors.id;

    -- ========================================================================
    -- БЛОК 3: Операционные таблицы (схема public)
    -- ========================================================================
    CREATE SEQUENCE public.seq_employees;
    CREATE TABLE public.employees (
        id INT NOT NULL DEFAULT nextval('public.seq_employees') PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        surname VARCHAR(255) NOT NULL,
        rank_id INT REFERENCES reference.military_ranks (id)
    );
    ALTER SEQUENCE public.seq_employees OWNED BY public.employees.id;

    CREATE SEQUENCE public.seq_measurement_batches;
    CREATE TABLE public.measurement_batches (
        id INT NOT NULL DEFAULT nextval('public.seq_measurement_batches') PRIMARY KEY,
        employee_id INT NOT NULL REFERENCES public.employees (id)
    );
    ALTER SEQUENCE public.seq_measurement_batches OWNED BY public.measurement_batches.id;

    CREATE TABLE public.measurements (
        measurement_batch_id INT NOT NULL REFERENCES public.measurement_batches (id),
        equipment_type_id INT NOT NULL REFERENCES reference.equipment_types (id),
        parameter_id INT NOT NULL REFERENCES reference.parameters (id),
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "value" INTEGER NOT NULL,
        PRIMARY KEY (measurement_batch_id, parameter_id)
    );

    -- ========================================================================
    -- БЛОК 4: Расчетные таблицы
    -- ========================================================================
    CREATE TABLE calc.temperature_correction (
        temperature SMALLINT PRIMARY KEY,
        correction SMALLINT NOT NULL
    );

    CREATE TABLE calc.constants (
        code VARCHAR(255) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        "value" NUMERIC(10, 2) NOT NULL,
        unit_id INT NULL REFERENCES reference.units (id)
    );

    -- ========================================================================
    -- БЛОК 5: Кастомные типы
    -- ========================================================================
    CREATE TYPE calc.interpolation_params AS (
        x0 NUMERIC, y0 NUMERIC, x1 NUMERIC, y1 NUMERIC
    );

    CREATE TYPE calc.parameters_list AS (
        equipment_type_id INT, height NUMERIC, temperature NUMERIC,
        pressure NUMERIC, wind_direction NUMERIC, wind_speed NUMERIC, bullet_drift NUMERIC
    );

    -- ========================================================================
    -- БЛОК 6: Функции расчетов и валидации
    -- ========================================================================
    CREATE OR REPLACE FUNCTION calc.get_temperature_interpolation_params(p_temperature NUMERIC)
    RETURNS calc.interpolation_params
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_adjusted_temp NUMERIC;
        v_result calc.interpolation_params;
    BEGIN
        SELECT GREATEST(MIN(temperature), LEAST(p_temperature, MAX(temperature))) INTO v_adjusted_temp FROM calc.temperature_correction;
        SELECT "lower".temperature, "lower".correction, "upper".temperature, "upper".correction INTO v_result.x0, v_result.y0, v_result.x1, v_result.y1
        FROM (SELECT temperature, correction FROM calc.temperature_correction WHERE temperature <= v_adjusted_temp ORDER BY temperature DESC LIMIT 1) "lower"
        CROSS JOIN (SELECT temperature, correction FROM calc.temperature_correction WHERE temperature >= v_adjusted_temp ORDER BY temperature ASC LIMIT 1) "upper";
        RETURN v_result;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calculate_interpolation(p_x NUMERIC, p_params calc.interpolation_params)
    RETURNS NUMERIC LANGUAGE plpgsql IMMUTABLE
    AS $func$
    BEGIN
        IF p_params.x1 = p_params.x0 THEN RETURN p_params.y0; END IF;
        RETURN ROUND(p_params.y0 + (p_x - p_params.x0) * (p_params.y1 - p_params.y0) / (p_params.x1 - p_params.x0), 2);
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calculate_temperature_correction(p_temperature NUMERIC)
    RETURNS NUMERIC LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN calc.calculate_interpolation(p_temperature, calc.get_temperature_interpolation_params(p_temperature));
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.get_constant(p_code VARCHAR)
    RETURNS NUMERIC LANGUAGE plpgsql STABLE
    AS $func$
    DECLARE v_value NUMERIC;
    BEGIN
        SELECT "value" INTO v_value FROM calc.constants WHERE code = p_code;
        IF NOT FOUND THEN RAISE EXCEPTION 'Константа % не найдена', p_code; END IF;
        RETURN v_value;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.convert_unit(p_value NUMERIC, p_from_unit_id INT, p_to_unit_id INT)
    RETURNS NUMERIC LANGUAGE plpgsql STABLE
    AS $func$
    DECLARE v_from_val NUMERIC; v_to_val NUMERIC;
    BEGIN
        IF p_from_unit_id = p_to_unit_id THEN RETURN p_value; END IF;
        SELECT from_value, to_value INTO v_from_val, v_to_val FROM reference.unit_conversions WHERE from_unit_id = p_from_unit_id AND to_unit_id = p_to_unit_id;
        IF NOT FOUND THEN RAISE EXCEPTION 'Конвертация не найдена'; END IF;
        RETURN p_value * (v_to_val / v_from_val);
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.validate_parameters(p_params calc.parameters_list)
    RETURNS TEXT LANGUAGE plpgsql STABLE
    AS $func$
    DECLARE v_error_list TEXT;
    BEGIN
        WITH unpacked_params (parameter_id, val, is_required) AS (
            VALUES (1, p_params.height, TRUE), (2, p_params.temperature, TRUE), (3, p_params.pressure, TRUE), (4, p_params.wind_direction, TRUE),
                   (5, p_params.wind_speed, COALESCE(p_params.equipment_type_id = 1, FALSE)),
                   (6, p_params.bullet_drift, COALESCE(p_params.equipment_type_id = 2, FALSE))
        ), checked_params AS (
            SELECT p.id, CASE WHEN up.val IS NULL AND up.is_required THEN pe.error_message || ' (не заполнено)'
                              WHEN up.val IS NOT NULL AND ((p.min_value IS NOT NULL AND up.val < p.min_value) OR (p.max_value IS NOT NULL AND up.val > p.max_value)) THEN pe.error_message || ' (передано: ' || up.val || ')'
                              ELSE NULL END AS err_text
            FROM unpacked_params up
            JOIN reference.parameters p ON p.id = up.parameter_id
            JOIN reference.parameter_errors pe ON p.id = pe.parameter_id ORDER BY p.id
        ) SELECT STRING_AGG(err_text, '; ') INTO v_error_list FROM checked_params WHERE err_text IS NOT NULL;
        RETURN v_error_list;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calc_meteo_ddhhm(p_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    RETURNS VARCHAR(5) LANGUAGE plpgsql IMMUTABLE
    AS $func$
    BEGIN
        RETURN TO_CHAR(p_datetime, 'DDHH24') || TRUNC(EXTRACT(MINUTE FROM p_datetime)::INT / 10)::TEXT;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calc_meteo_vvvv(p_height NUMERIC)
    RETURNS VARCHAR(5) LANGUAGE plpgsql IMMUTABLE
    AS $func$
    BEGIN
        IF p_height < 0 THEN RETURN '-' || LPAD(ROUND(ABS(p_height))::INT::TEXT, 4, '0'); END IF;
        RETURN LPAD(ROUND(p_height)::INT::TEXT, 4, '0');
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calc_meteo_bbbtt(p_pressure NUMERIC, p_temp_tenths NUMERIC)
    RETURNS VARCHAR(5) LANGUAGE plpgsql STABLE
    AS $func$
    DECLARE
        v_norm_pressure NUMERIC := calc.get_constant('NORMAL_PRESSURE');
        v_norm_temp_tenths NUMERIC := calc.get_constant('NORMAL_VIRTUAL_TEMP');
        v_delta_pressure INT; v_delta_temp_deg INT; v_bbb TEXT; v_tt TEXT;
    BEGIN
        v_delta_pressure := ROUND(p_pressure - v_norm_pressure)::INT;
        IF v_delta_pressure < 0 THEN v_bbb := '5' || LPAD(ABS(v_delta_pressure)::TEXT, 2, '0');
        ELSE v_bbb := LPAD(v_delta_pressure::TEXT, 3, '0'); END IF;
        
        v_delta_temp_deg := ROUND(calc.convert_unit((p_temp_tenths + calc.calculate_temperature_correction(p_temp_tenths)) - v_norm_temp_tenths, 2, 6))::INT;
        IF v_delta_temp_deg < 0 THEN v_tt := LPAD((ABS(v_delta_temp_deg) + 50)::TEXT, 2, '0');
        ELSE v_tt := LPAD(v_delta_temp_deg::TEXT, 2, '0'); END IF;
        
        RETURN v_bbb || v_tt;
    END;
    $func$;

    CREATE OR REPLACE FUNCTION calc.calculate_meteo_approx(p_datetime TIMESTAMP, p_params calc.parameters_list)
    RETURNS TEXT LANGUAGE plpgsql STABLE
    AS $func$
    BEGIN
        IF calc.validate_parameters(p_params) IS NOT NULL THEN RETURN NULL; END IF;
        RETURN calc.calc_meteo_ddhhm(p_datetime) || ' - ' || calc.calc_meteo_vvvv(p_params.height) || ' - ' || calc.calc_meteo_bbbtt(p_params.pressure, p_params.temperature);
    END;
    $func$;

    -- ========================================================================
    -- БЛОК 7: Наполнение справочников и констант
    -- ========================================================================
    TRUNCATE TABLE reference.unit_conversions, reference.parameter_errors, reference.parameters, reference.units, reference.parameter_types, reference.equipment_types, reference.military_ranks, calc.temperature_correction, calc.constants CASCADE;
    PERFORM setval('reference.seq_military_ranks', 1, false);
    PERFORM setval('reference.seq_equipment_types', 1, false);
    PERFORM setval('reference.seq_parameter_types', 1, false);
    PERFORM setval('reference.seq_units', 1, false);
    PERFORM setval('reference.seq_parameters', 1, false);
    PERFORM setval('reference.seq_parameter_errors', 1, false);

    INSERT INTO calc.temperature_correction (temperature, correction) VALUES (0, 0), (50, 5), (100, 10), (150, 10), (200, 15), (250, 20), (300, 35), (400, 45);
    
    INSERT INTO reference.military_ranks (title) VALUES ('Рядовой'), ('Ефрейтор'), ('Младший сержант'), ('Сержант'), ('Старший сержант'), ('Старшина'), ('Прапорщик'), ('Старший прапорщик'), ('Младший лейтенант'), ('Лейтенант'), ('Старший лейтенант'), ('Капитан'), ('Майор'), ('Подполковник'), ('Полковник');
    
    INSERT INTO reference.equipment_types (title, abbreviation) VALUES ('Десантный метеокомплект', 'ДМК'), ('Ветровое ружье', 'ВР');
    
    INSERT INTO reference.parameter_types (title) VALUES ('Высота метеопоста'), ('Температура'), ('Давление'), ('Направление ветра'), ('Скорость ветра'), ('Дальность сноса пуль');
    
    INSERT INTO reference.units (title, abbreviation) VALUES ('Метр', 'м'), ('1/10 градуса по Цельсию', '*C/10'), ('Миллиметр ртутного столба', 'мм рт. ст.'), ('Деление угломера', 'дел. угл.'), ('Метр в секунду', 'м/с'), ('Градус по Цельсию', '*C');
    
    INSERT INTO calc.constants (code, title, "value", unit_id) VALUES ('NORMAL_PRESSURE', 'Табличное наземное давление (мм рт. ст.)', 750, 3), ('NORMAL_VIRTUAL_TEMP', 'Табличная приземная виртуальная температура (*C/10)', 159, 2);
    
    INSERT INTO reference.parameters (parameter_type_id, unit_id, default_value, min_value, max_value) VALUES (1, 1, 100, NULL, NULL), (2, 2, 150, -580, 580), (3, 3, 750, 500, 900), (4, 4, 0, 0, 59), (5, 5, 0, 0, 15), (6, 1, 0, 0, 150);
    
    INSERT INTO reference.unit_conversions (from_unit_id, to_unit_id, from_value, to_value) VALUES (2, 6, 10, 1);

    INSERT INTO reference.parameter_errors (parameter_id, error_message) VALUES (1, 'Некорректная высота метеопоста'), (2, 'Температура вне диапазона (-580..580 *C/10)'), (3, 'Давление вне диапазона (500..900 мм рт. ст.)'), (4, 'Направление ветра вне диапазона (0..59 дел. угл.)'), (5, 'Скорость ветра вне диапазона (0..15 м/с)'), (6, 'Дальность сноса пуль вне диапазона (0..150 м)');
END $$;