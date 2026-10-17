DO $$
BEGIN

    -- Создаем составной тип данных для параметров интерполяции
    -- Сначала удаляем тип
    DROP TYPE IF EXISTS calc.interpolation_params CASCADE;

    CREATE TYPE calc.interpolation_params AS (
        x0 NUMERIC,
        y0 NUMERIC,
        x1 NUMERIC,
        y1 NUMERIC
    );

    COMMENT ON TYPE calc.interpolation_params IS 'Структура параметров для интерполяции (x0, y0, x1, y1)';

    -- Функция определения параметров интерполяции по температуре
    CREATE OR REPLACE FUNCTION calc.get_temperature_interpolation_params(p_temperature NUMERIC)
    RETURNS calc.interpolation_params
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_adjusted_temp NUMERIC;
        v_result calc.interpolation_params;
    BEGIN
        -- Ограничиваем входную температуру минимальным и максимальным значением справочника
        SELECT GREATEST(MIN(temperature), LEAST(p_temperature, MAX(temperature)))
        INTO v_adjusted_temp
        FROM calc.temperature_correction;

        -- Находим ближайший узел слева и справа
        SELECT "lower".temperature, "lower".correction, "upper".temperature, "upper".correction
        INTO v_result.x0, v_result.y0, v_result.x1, v_result.y1
        FROM ( -- Ближайший слева
            SELECT temperature, correction
            FROM calc.temperature_correction
            WHERE temperature <= v_adjusted_temp
            ORDER BY temperature DESC
            LIMIT 1
        ) "lower"
        CROSS JOIN ( -- Ближайший справа
            SELECT temperature, correction
            FROM calc.temperature_correction
            WHERE temperature >= v_adjusted_temp
            ORDER BY temperature ASC
            LIMIT 1
        ) "upper";

        RETURN v_result;
    END;
    $func$;

    COMMENT ON FUNCTION calc.get_temperature_interpolation_params(NUMERIC)
    IS 'Возвращает параметры интерполяции по заданной температуре';

    -- Функция расчета линейной интерполяции
    CREATE OR REPLACE FUNCTION calc.calculate_interpolation(
        p_x NUMERIC,
        p_params calc.interpolation_params
    )
    RETURNS NUMERIC
    LANGUAGE plpgsql
    IMMUTABLE -- Одни и те же входные параметры приведут к одному результату +кеш
    AS $func$
    BEGIN
        -- Если наши входные параметры интерполяции одинаковые, то просто возвращаем их значение
        -- Это защищает нас от деления на ноль
        IF p_params.x1 = p_params.x0 THEN
            RETURN p_params.y0;
        END IF;

        -- Считаем линейную интерполяцию
        RETURN ROUND(
            p_params.y0 + (p_x - p_params.x0) * (p_params.y1 - p_params.y0) / (p_params.x1 - p_params.x0), 2
        );
    END;
    $func$;

    COMMENT ON FUNCTION calc.calculate_interpolation(NUMERIC, calc.interpolation_params) 
    IS 'Рассчитывает значение линейной интерполяции для точки x и структуры (x0, y0, x1, y1)';

    -- Функция обертка для удобного использования
    CREATE OR REPLACE FUNCTION calc.calculate_temperature_correction(p_temperature NUMERIC)
    RETURNS NUMERIC
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN calc.calculate_interpolation(p_temperature, calc.get_temperature_interpolation_params(p_temperature));
    END;
    $func$;

    COMMENT ON FUNCTION calc.calculate_temperature_correction(p_temperature NUMERIC) 
    IS 'Рассчитывает значение коррекции для температуры, используя линейную интерполяцию и данные из таблицы коррекции';

END $$;