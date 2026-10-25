
-- Таблица ошибок 1:1 к параметрам, тип "Список параметров"
-- и функция проверки корректности параметров

DO $$
BEGIN
    -- Создание таблицы ошибок со связью 1:1 к reference.parameters
    DROP TABLE IF EXISTS reference.parameter_errors CASCADE;

    CREATE TABLE reference.parameter_errors (
        parameter_id INT PRIMARY KEY REFERENCES reference.parameters (id) ON DELETE CASCADE,
        error_message VARCHAR(255) NOT NULL
    );

    COMMENT ON TABLE reference.parameter_errors IS 'Сообщения об ошибках для входных параметров';
    COMMENT ON COLUMN reference.parameter_errors.parameter_id IS 'Идентификатор параметра';
    COMMENT ON COLUMN reference.parameter_errors.error_message IS 'Текст ошибки при некорректном значении параметра';

    INSERT INTO reference.parameter_errors (parameter_id, error_message)
    VALUES
        (1, 'Некорректная высота метеопоста'),
        (2, 'Температура вне диапазона (-580..580 *C/10)'),
        (3, 'Давление вне диапазона (500..900 мм рт. ст.)'),
        (4, 'Направление ветра вне диапазона (0..59 дел. угл.)'),
        (5, 'Скорость ветра вне диапазона (0..15 м/с)'),
        (6, 'Дальность сноса пуль вне диапазона (0..150 м)');

    -- Создание составного типа "Список параметров"
    DROP TYPE IF EXISTS calc.parameters_list CASCADE;

    CREATE TYPE calc.parameters_list AS (
        equipment_type_id INT,
        height NUMERIC,
        temperature NUMERIC,
        pressure NUMERIC,
        wind_direction NUMERIC,
        wind_speed NUMERIC,
        bullet_drift NUMERIC
    );

    COMMENT ON TYPE calc.parameters_list IS 'Список входных параметров пачки измерений';

    -- Функция проверки корректности параметров
    CREATE OR REPLACE FUNCTION calc.validate_parameters(p_params calc.parameters_list)
    RETURNS TEXT
    LANGUAGE plpgsql
    STABLE
    AS $func$
    DECLARE
        v_error_list TEXT;
    BEGIN
        WITH unpacked_params (parameter_id, val, is_required) AS (
            VALUES
                (1, p_params.height, TRUE),
                (2, p_params.temperature, TRUE),
                (3, p_params.pressure, TRUE),
                (4, p_params.wind_direction, TRUE),
                -- Скорость ветра обязательна только для ДМК
                (5, p_params.wind_speed, COALESCE(p_params.equipment_type_id = 1, FALSE)),
                -- Дальность сноса пуль обязательна только для ВР
                (6, p_params.bullet_drift, COALESCE(p_params.equipment_type_id = 2, FALSE))
        ),
        checked_params AS (
            SELECT
                p.id,
                CASE
                    WHEN up.val IS NULL AND up.is_required THEN
                        pe.error_message || ' (не заполнено)'
                    WHEN up.val IS NOT NULL
                         AND (
                             (p.min_value IS NOT NULL AND up.val < p.min_value)
                             OR
                             (p.max_value IS NOT NULL AND up.val > p.max_value)
                         ) THEN
                        pe.error_message || ' (передано: ' || up.val || ')'
                    ELSE NULL
                END AS err_text
            FROM unpacked_params up
            JOIN reference.parameters p ON p.id = up.parameter_id
            JOIN reference.parameter_errors pe ON p.id = pe.parameter_id
            ORDER BY p.id
        )
        SELECT STRING_AGG(err_text, '; ')
        INTO v_error_list
        FROM checked_params
        WHERE err_text IS NOT NULL;

        RETURN v_error_list;
    END;
    $func$;

    COMMENT ON FUNCTION calc.validate_parameters(calc.parameters_list)
    IS 'Возвращает строку со списком ошибок для переданного типа параметров (NULL, если ошибок нет)';
END $$;