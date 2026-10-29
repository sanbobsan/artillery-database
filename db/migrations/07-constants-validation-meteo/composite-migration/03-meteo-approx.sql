
-- Функции для расчета "Метео приближенный" (ДДЧЧМ, ВВВВ, БББТТ)

DO $$
BEGIN
    -- Расчет группы ДДЧЧМ
    CREATE OR REPLACE FUNCTION calc.calc_meteo_ddhhm(p_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    RETURNS VARCHAR(5)
    LANGUAGE plpgsql
    IMMUTABLE
    AS $func$
    BEGIN
        RETURN TO_CHAR(p_datetime, 'DDHH24')
            || TRUNC(EXTRACT(MINUTE FROM p_datetime)::INT / 10)::TEXT;
    END;
    $func$;

    COMMENT ON FUNCTION calc.calc_meteo_ddhhm(TIMESTAMP)
    IS 'Рассчитывает группу ДДЧЧМ';

    -- Расчет группы ВВВВ
    CREATE OR REPLACE FUNCTION calc.calc_meteo_vvvv(p_height NUMERIC)
    RETURNS VARCHAR(5)
    LANGUAGE plpgsql
    IMMUTABLE
    AS $func$
    BEGIN
        IF p_height < 0 THEN
            RETURN '-' || LPAD(ROUND(ABS(p_height))::INT::TEXT, 4, '0');
        END IF;

        RETURN LPAD(ROUND(p_height)::INT::TEXT, 4, '0');
    END;
    $func$;

    COMMENT ON FUNCTION calc.calc_meteo_vvvv(NUMERIC)
    IS 'Рассчитывает группу ВВВВ';

    -- Расчет группы БББТТ
    CREATE OR REPLACE FUNCTION calc.calc_meteo_bbbtt(
        p_pressure NUMERIC,
        p_temp_tenths NUMERIC
    )
    RETURNS VARCHAR(6)
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
            -- если отрицательное значение, то в начале ставится 5
            v_bbb := '5' || LPAD(ABS(v_delta_pressure)::TEXT, 2, '0');
        ELSE
            v_bbb := LPAD(v_delta_pressure::TEXT, 3, '0');
        END IF;

        -- Расчет виртуальной температуры в *C/10: T0 = t0 + dTv
        v_virtual_temp_tenths := p_temp_tenths + calc.calculate_temperature_correction(p_temp_tenths);

        -- Отклонение виртуальной температуры в *C/10: dT0 = T0 - 159
        v_delta_temp_tenths := v_virtual_temp_tenths - v_norm_temp_tenths;

        -- Перевод из *C/10 (unit_id = 2) в *C (unit_id = 6) в самом конце и округление
        v_delta_temp_deg := ROUND(calc.convert_unit(v_delta_temp_tenths, 2, 6))::INT;

        IF v_delta_temp_deg < 0 THEN
            v_tt := '-' || LPAD(ABS(v_delta_temp_deg)::TEXT, 2, '0'); -- а что делать с минусом у температуры?
        ELSE
            v_tt := LPAD(v_delta_temp_deg::TEXT, 2, '0');
        END IF;

        RETURN v_bbb || v_tt;
    END;
    $func$;

    COMMENT ON FUNCTION calc.calc_meteo_bbbtt(NUMERIC, NUMERIC)
    IS 'Рассчитывает группу БББТТ';

    -- Общая функция для расчета "Метео приближенный"
    CREATE OR REPLACE FUNCTION calc.calculate_meteo_approx(
        p_datetime TIMESTAMP,
        p_params calc.parameters_list
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    STABLE
    AS $func$
    BEGIN
        IF calc.validate_parameters(p_params) IS NOT NULL THEN
            RETURN NULL; -- Валидируем наши параметры
        END IF;

        RETURN calc.calc_meteo_ddhhm(p_datetime) || ' - ' ||
               calc.calc_meteo_vvvv(p_params.height) || ' - ' ||
               calc.calc_meteo_bbbtt(p_params.pressure, p_params.temperature);
    END;
    $func$;

    COMMENT ON FUNCTION calc.calculate_meteo_approx(TIMESTAMP, calc.parameters_list)
    IS 'Формирует строку [ДДЧЧМ - ВВВВ - БББТТ]';
END $$;