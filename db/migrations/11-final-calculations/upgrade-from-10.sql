-- ============================================================================
 -- СКРИПТ МИГРАЦИИ 11: Функции для итогового расчета
-- ============================================================================

DO $$
BEGIN
    -- ========================================================================
    -- ГЛАВНАЯ ФУНКЦИЯ: Считает значения, которые нам нужно получить
    -- ========================================================================
    CREATE OR REPLACE FUNCTION calc.calculate_meteo_heights(
        p_params calc.parameters_list -- equipment_id есть в parameters_list
    )
    RETURNS TABLE (
        height INT, -- высота
        delta_t INT, -- отклонение температуры
        wind_direction INT, -- направление ветра
        wind_speed INT -- скорость ветра
    )
    LANGUAGE plpgsql STABLE
    AS $func$
    DECLARE
        v_error_msg TEXT; -- переменная для вывода ошибки валидации
        
        -- Переменные для температуры
        v_norm_temp_tenths NUMERIC := calc.get_constant('NORMAL_VIRTUAL_TEMP');
        v_delta_t_deg INT; -- дельта температуры, по которой делаем корректировки
        v_temp_corr_type INT; -- индекс типа корректировок (положительные или отрицательные)
        -- Индексы в массиве для таблицы корректировок
        v_idx_tens INT; -- индекс для десятков (NULL если без них)
        v_idx_ones INT; -- индекс для единиц (NULL если только десятки)
        
        -- Переменные для ветра
        v_search_speed INT; -- скорость, по которой делаем корректировки
        v_wind_speed_corr_type INT; -- индекс типа корректировок для скорости ветра (ВР или ДМК)
        v_wind_dir_corr_type INT; -- индекс типа корректировок для направления ветра (ВР или ДМК)
        -- эти ^ индексы равны NULL, если не считаем (ветер слишком слабый)
        v_idx_speed INT; -- индекс в массиве для таблицы корректировок
    BEGIN

        -- ====================================================================
        -- Валидация параметров
        -- ====================================================================
        v_error_msg := calc.validate_parameters(p_params);
        IF v_error_msg IS NOT NULL THEN
            RAISE EXCEPTION 'Ошибка валидации параметров: %', v_error_msg;
        END IF;

        -- ====================================================================
        -- Подготовка параметров температуры
        -- ====================================================================
        v_delta_t_deg := ROUND(((p_params.temperature + calc.calculate_temperature_correction(p_params.temperature)) - v_norm_temp_tenths) / 10.0);
        
        -- Выбираем индекс типа корректировок
        IF v_delta_t_deg < 0 THEN -- отрицательные
            v_temp_corr_type := 5;
        ELSIF v_delta_t_deg > 0 THEN -- положительные
            v_temp_corr_type := 4;
        END IF;

        IF v_temp_corr_type IS NOT NULL THEN
            -- сохраняем индексы в массиве для единиц и десятков
            SELECT
                array_position(ch.header_values, (ABS(v_delta_t_deg) / 10) * 10), -- десятки
                array_position(ch.header_values, ABS(v_delta_t_deg) % 10) -- единицы
            INTO v_idx_tens, v_idx_ones
            FROM calc.correction_types ct
            JOIN calc.correction_headers ch ON ct.header_id = ch.id
            WHERE ct.id = v_temp_corr_type;
        END IF;

        -- ====================================================================
        -- Подготовка параметров ветра
        -- ====================================================================
        IF (p_params.equipment_type_id = 1 AND p_params.wind_speed < 3) OR 
           (p_params.equipment_type_id = 2 AND p_params.bullet_drift < 40) THEN
            -- Скорость ветра равна нулю
            v_wind_speed_corr_type := NULL;
            v_wind_dir_corr_type := NULL;

        ELSE
            -- Выбираем индексы типов корректировок
            IF p_params.equipment_type_id = 1 THEN -- ДМК
                v_wind_speed_corr_type := 8;
                v_wind_dir_corr_type := 9;
                v_search_speed := p_params.wind_speed;
            ELSE -- ВР
                v_wind_speed_corr_type := 6;
                v_wind_dir_corr_type := 7;
                v_search_speed := ROUND(p_params.bullet_drift / 10.0)::INT * 10; -- В целых десятках
            END IF;

            SELECT array_position(ch.header_values, v_search_speed)
            INTO v_idx_speed -- индекс для нужной нам скорости в массиве
            FROM calc.correction_types ct
            JOIN calc.correction_headers ch ON ct.header_id = ch.id
            WHERE ct.id = v_wind_speed_corr_type;
        END IF;

        -- ====================================================================
        -- Расчеты
        -- ====================================================================
        RETURN QUERY
        WITH raw_data AS ( -- Собираем таблицу со всеми высотами
            SELECT 
                ch_h.height AS h_val,
                -- Складываем температуру для десяток и для единиц
                COALESCE(c_temp.row_values[v_idx_tens], 0) + COALESCE(c_temp.row_values[v_idx_ones], 0) AS delta_t,
                -- Скорость
                COALESCE(c_speed.row_values[v_idx_speed], 0) AS speed_val,
                -- Угол
                COALESCE(c_dir.row_values[1], 0) AS dir_corr
            FROM calc.correction_heights ch_h
            LEFT JOIN calc.corrections c_temp 
                ON c_temp.height_id = ch_h.id AND c_temp.correction_type_id = v_temp_corr_type
            LEFT JOIN calc.corrections c_speed 
                ON c_speed.height_id = ch_h.id AND c_speed.correction_type_id = v_wind_speed_corr_type
            LEFT JOIN calc.corrections c_dir 
                ON c_dir.height_id = ch_h.id AND c_dir.correction_type_id = v_wind_dir_corr_type
        )
        SELECT 
            rd.h_val,

            rd.delta_t,

            -- Если индекс ветра NULL, возвращаем 0, иначе считаем угол
            CASE WHEN v_wind_speed_corr_type IS NULL THEN 0
                 ELSE ((p_params.wind_direction + rd.dir_corr / 100)::INT % 60)
            END,
            
            -- Если индекс ветра NULL, возвращаем 0, иначе берем сырую скорость
            CASE WHEN v_wind_speed_corr_type IS NULL THEN 0
                 ELSE rd.speed_val
            END
            
        FROM raw_data rd
        ORDER BY rd.h_val;

    END;
    $func$;

    -- ========================================================================
    -- ФУНКЦИЯ ФОРМАТИРОВАНИЯ: Обертка для отображения
    -- ========================================================================
    CREATE OR REPLACE FUNCTION calc.calculate_meteo_heights_formatted(
        p_params calc.parameters_list
    )
    RETURNS TABLE (
        height VARCHAR(2), -- высота
        tt VARCHAR(2), -- отклонение температуры
        hh VARCHAR(2), -- направление ветра
        cc VARCHAR(2) -- скорость ветра
    )
    LANGUAGE sql STABLE
    AS $func$
        SELECT 
            -- Высота
            LPAD((r.height / 100)::INT::TEXT, 2, '0')::VARCHAR as height,
            
            -- Форматирование TT (|x| + 50 для отрицательных)
            LPAD(CASE WHEN r.delta_t < 0 THEN (ABS(r.delta_t) + 50) ELSE r.delta_t END::TEXT, 2, '0')::VARCHAR AS tt,
            
            -- Форматирование HH
            LPAD(r.wind_direction::TEXT, 2, '0')::VARCHAR AS hh,
            
            -- Форматирование CC
            LPAD(r.wind_speed::TEXT, 2, '0')::VARCHAR AS cc
            
        FROM calc.calculate_meteo_heights(p_params) r;
    $func$;

END $$;