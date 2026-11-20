-- ============================================================================
-- ТЕСТОВЫЙ СКРИПТ: Тестирование функции для расчетов
-- Версия базы данных: 11
-- ============================================================================

-- Без форматирования
SELECT * 
FROM calc.calculate_meteo_heights(
    ROW(
        1,    -- equipment_type_id
        100,  -- height
        250,  -- temperature
        765,  -- pressure
        15,   -- wind_direction
        6,    -- wind_speed
        0     -- bullet_drift
    )::calc.parameters_list
);

-- То жэе самое, только с форматированием
SELECT * 
FROM calc.calculate_meteo_heights_formatted(
    ROW(
        1,    -- equipment_type_id
        100,  -- height
        250,  -- temperature
        765,  -- pressure
        15,   -- wind_direction
        6,    -- wind_speed
        0     -- bullet_drift
    )::calc.parameters_list
);

SELECT * 
FROM calc.calculate_meteo_heights_formatted(
    ROW(
        1,    -- equipment_type_id
        100,  -- height
        230,  -- temperature
        750,  -- pressure
        0,    -- wind_direction
        0,    -- wind_speed
        0     -- bullet_drift
    )::calc.parameters_list
);

SELECT * 
FROM calc.calculate_meteo_heights_formatted(
    ROW(
        1,    -- equipment_type_id
        100,  -- height
        30,   -- temperature
        750,  -- pressure
        10,   -- wind_direction
        5,    -- wind_speed
        0     -- bullet_drift
    )::calc.parameters_list
);

SELECT * 
FROM calc.calculate_meteo_heights_formatted(
    ROW(
        2,    -- equipment_type_id
        100,  -- height
        150,  -- temperature
        750,  -- pressure
        0,    -- wind_direction
        0,    -- wind_speed
        134     -- bullet_drift
    )::calc.parameters_list
);

-- Неправильный запрос
SELECT * 
FROM calc.calculate_meteo_heights_formatted(
    ROW(
        2,    -- equipment_type_id
        100,  -- height
        150,  -- temperature
        750,  -- pressure
        0,    -- wind_direction
        0,    -- wind_speed
        3333     -- bullet_drift
    )::calc.parameters_list
);