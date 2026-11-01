-- ============================================================================
-- СКРИПТ МИГРАЦИИ: Исправление ошибок БББТТ, оптимизация типов данных
-- ============================================================================

DO $$
BEGIN
    -- ========================================================================
    -- 1. Исправление функции calc_meteo_bbbtt
    -- Удаляем старую функцию, так как меняется возвращаемый тип с VARCHAR(6) на VARCHAR(5)
    -- ========================================================================
    DROP FUNCTION IF EXISTS calc.calc_meteo_bbbtt(NUMERIC, NUMERIC);

    -- Вложенный блок для пересоздания функции
    CREATE OR REPLACE FUNCTION calc.calc_meteo_bbbtt(
        p_pressure NUMERIC,
        p_temp_tenths NUMERIC
    )
    RETURNS VARCHAR(5)
    LANGUAGE plpgsql
    STABLE
    AS $func$
    DECLARE
        v_norm_pressure NUMERIC;
        v_norm_temp_tenths NUMERIC;
        v_virtual_temp_tenths NUMERIC;
        v_delta_temp_tenths NUMERIC;
        v_delta_pressure INT;
        v_delta_temp_deg INT;
        v_bbb TEXT;
        v_tt TEXT;
    BEGIN
        v_norm_pressure := calc.get_constant('NORMAL_PRESSURE');
        v_norm_temp_tenths := calc.get_constant('NORMAL_VIRTUAL_TEMP');

        -- Расчет отклонения давления: dH0 = H0 - 750
        v_delta_pressure := ROUND(p_pressure - v_norm_pressure)::INT;
        IF v_delta_pressure < 0 THEN
            v_bbb := '5' || LPAD(ABS(v_delta_pressure)::TEXT, 2, '0');
        ELSE
            v_bbb := LPAD(v_delta_pressure::TEXT, 3, '0');
        END IF;

        -- Расчет виртуальной температуры в *C/10: T0 = t0 + dTv
        v_virtual_temp_tenths := p_temp_tenths + calc.calculate_temperature_correction(p_temp_tenths);
        v_delta_temp_tenths := v_virtual_temp_tenths - v_norm_temp_tenths;
        v_delta_temp_deg := ROUND(calc.convert_unit(v_delta_temp_tenths, 2, 6))::INT;

        -- ИСПРАВЛЕНИЕ: Температура
        -- Согласно правилам метео, при отрицательном отклонении к модулю температуры прибавляется 50
        -- Это автоматически убирает минус и ставит нужную цифру в начало. Пример: -4 превращается в 54.
        IF v_delta_temp_deg < 0 THEN
            v_tt := LPAD((ABS(v_delta_temp_deg) + 50)::TEXT, 2, '0');
        ELSE
            v_tt := LPAD(v_delta_temp_deg::TEXT, 2, '0');
        END IF;

        RETURN v_bbb || v_tt;
    END;
    $func$;

    COMMENT ON FUNCTION calc.calc_meteo_bbbtt(NUMERIC, NUMERIC)
    IS 'Рассчитывает группу БББТТ';

    -- ========================================================================
    -- 2. Снятие жестких ограничений VARCHAR -> VARCHAR(255)
    -- Единственное найденное узкое место - код констант, но для безопасности
    -- прогоняем ALTER по всем текстовым колонкам.
    -- ========================================================================
    ALTER TABLE calc.constants ALTER COLUMN code TYPE VARCHAR(255);
    ALTER TABLE reference.military_ranks ALTER COLUMN title TYPE VARCHAR(255);
    ALTER TABLE reference.equipment_types ALTER COLUMN title TYPE VARCHAR(255);
    ALTER TABLE reference.equipment_types ALTER COLUMN abbreviation TYPE VARCHAR(255);
    ALTER TABLE reference.parameter_types ALTER COLUMN title TYPE VARCHAR(255);
    ALTER TABLE reference.units ALTER COLUMN title TYPE VARCHAR(255);
    ALTER TABLE reference.units ALTER COLUMN abbreviation TYPE VARCHAR(255);
    ALTER TABLE public.employees ALTER COLUMN name TYPE VARCHAR(255);
    ALTER TABLE public.employees ALTER COLUMN surname TYPE VARCHAR(255);

    -- ========================================================================
    -- 3. Оптимизация хранения: замена целочисленных DECIMAL(10, 0) на INTEGER
    -- Перевод хранения значений в целочисленный тип, так как дробная часть 
    -- уже учтена форматом *C/10 на уровне логики приложения.
    -- ========================================================================
    
    -- Параметры (default, min, max значения)
    ALTER TABLE reference.parameters
        ALTER COLUMN default_value TYPE INTEGER USING default_value::INTEGER,
        ALTER COLUMN min_value TYPE INTEGER USING min_value::INTEGER,
        ALTER COLUMN max_value TYPE INTEGER USING max_value::INTEGER;

    -- Переводы единиц измерения (коэффициенты конвертации)
    ALTER TABLE reference.unit_conversions
        ALTER COLUMN from_value TYPE INTEGER USING from_value::INTEGER,
        ALTER COLUMN to_value TYPE INTEGER USING to_value::INTEGER;

    -- Журнал измерений (фактические значения)
    ALTER TABLE public.measurements
        ALTER COLUMN "value" TYPE INTEGER USING "value"::INTEGER;

END $$;