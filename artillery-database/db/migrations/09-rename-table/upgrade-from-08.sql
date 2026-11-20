-- ==============================================================================
-- СКРИПТ МИГРАЦИИ 09: Переименование таблицы поправок и переопределение функции
-- ==============================================================================

DO $$
BEGIN
    -- ============================================================================
    -- Переименование таблицы поправок и переопределение зависимой функции
    -- ============================================================================
    
    -- Переименовываем таблицу виртуальной температуры для исключения путаницы с высотными
    IF EXISTS ( 
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'calc' AND table_name = 'temperature_correction'
    ) THEN
        ALTER TABLE calc.temperature_correction 
            RENAME TO virtual_temperature_corrections;
    END IF;

    COMMENT ON TABLE calc.virtual_temperature_corrections 
        IS 'Виртуальные поправки приземной температуры';

    -- Переопределяем функцию интерполяции с новым именем таблицы
    CREATE OR REPLACE FUNCTION calc.get_temperature_interpolation_params(p_temperature NUMERIC)
    RETURNS calc.interpolation_params
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_adjusted_temp NUMERIC;
        v_result calc.interpolation_params;
    BEGIN
        SELECT GREATEST(MIN(temperature), LEAST(p_temperature, MAX(temperature)))
        INTO v_adjusted_temp
        FROM calc.virtual_temperature_corrections;
        SELECT "lower".temperature, "lower".correction, "upper".temperature, "upper".correction
        INTO v_result.x0, v_result.y0, v_result.x1, v_result.y1
        FROM (
            SELECT temperature, correction
            FROM calc.virtual_temperature_corrections
            WHERE temperature <= v_adjusted_temp
            ORDER BY temperature DESC
            LIMIT 1
        ) "lower"
        CROSS JOIN (
            SELECT temperature, correction
            FROM calc.virtual_temperature_corrections
            WHERE temperature >= v_adjusted_temp
            ORDER BY temperature ASC
            LIMIT 1
        ) "upper";

        RETURN v_result;
    END;
    $func$;

    COMMENT ON FUNCTION calc.get_temperature_interpolation_params(NUMERIC)
    IS 'Возвращает параметры интерполяции по заданной температуре';

END $$;