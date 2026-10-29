
-- Выполнение запросов "Список параметров с ошибками" и "Лучший стрелок"
-- внутри тестовой транзакции с последующим откатом

BEGIN;

-- Вставка временных тестовых данных (откатим при ROLLBACK)
INSERT INTO public.employees (id, name, surname, rank_id)
VALUES
    (-1, 'Иван', 'Иванов', 4),  -- 0 ошибок
    (-2, 'Петр', 'Петров', 3),  -- 1 ошибка
    (-3, 'Алексей', 'Сидоров', 1);  -- 3 ошибки

INSERT INTO public.measurement_batches (id, employee_id)
VALUES
    (-101, -1),
    (-102, -1),
    (-103, -2),
    (-104, -3),
    (-105, -3);

INSERT INTO public.measurements (measurement_batch_id, equipment_type_id, parameter_id, "value")
VALUES
    -- Пачка -101 все корректно
    (-101, 1, 1, 100),
    (-101, 1, 2, 250), -- десятые от градусов по Цельсию
    (-101, 1, 3, 765),
    (-101, 1, 4, 15),
    (-101, 1, 5, 6),
    -- Пачка -102 все корректно
    (-102, 2, 1, 60),
    (-102, 2, 2, 230),
    (-102, 2, 3, 743),
    (-102, 2, 4, 10),
    (-102, 2, 6, 50),
    -- Пачка -103 неверное давление
    (-103, 1, 1, 100),
    (-103, 1, 2, 150),
    (-103, 1, 3, 950),
    (-103, 1, 4, 10),
    (-103, 1, 5, 5),
    -- Пачка -104 неверная температура и скорость ветра
    (-104, 1, 1, 100),
    (-104, 1, 2, 650),
    (-104, 1, 3, 750),
    (-104, 1, 4, 20),
    (-104, 1, 5, 20),
    -- Пачка -105 неверное направление ветра
    (-105, 2, 1, 100),
    (-105, 2, 2, 30),
    (-105, 2, 3, 750),
    (-105, 2, 4, 65),
    (-105, 2, 6, 45);


-- ЗАПРОС 1: Список параметров с ошибками
WITH batch_wo_parameters_list AS (
    SELECT
        mb.id AS batch_id,
        MAX(m.equipment_type_id) AS equipment_type_id,
        MAX(m.created_at) AS measured_at,
        MAX(m."value") FILTER (WHERE m.parameter_id = 1) AS "height",
        MAX(m."value") FILTER (WHERE m.parameter_id = 2) AS temperature,
        MAX(m."value") FILTER (WHERE m.parameter_id = 3) AS pressure,
        MAX(m."value") FILTER (WHERE m.parameter_id = 4) AS wind_direction,
        MAX(m."value") FILTER (WHERE m.parameter_id = 5) AS wind_speed,
        MAX(m."value") FILTER (WHERE m.parameter_id = 6) AS bullet_drift
    FROM public.measurement_batches mb
    LEFT JOIN public.measurements m ON m.measurement_batch_id = mb.id
    GROUP BY mb.id
),
batch AS (
    SELECT 
        *, 
        ( -- Наш составной тип
            equipment_type_id,
            "height",
            temperature,
            pressure,
            wind_direction,
            wind_speed,
            bullet_drift
        )::calc.parameters_list AS params
    FROM batch_wo_parameters_list
),
batch_validated AS (
    SELECT
        b.batch_id,
        et.abbreviation AS equipment_type,
        b.height,
        b.temperature,
        b.pressure,
        b.wind_direction,
        b.wind_speed,
        b.bullet_drift,
        calc.validate_parameters(b.params) AS error_description,
        calc.calculate_meteo_approx(b.measured_at, b.params) AS meteo_approx
    FROM batch b
    LEFT JOIN reference.equipment_types et ON et.id = b.equipment_type_id
)
SELECT
    batch_id AS "№",
    equipment_type AS "Тип оборудования",
    height AS "Высота метеопоста",
    temperature AS "Температура",
    pressure AS "Давление",
    wind_direction AS "Направление ветра",
    wind_speed AS "Скорость ветра",
    bullet_drift AS "Дальность сноса пуль",
    (error_description IS NOT NULL) AS "Есть ошибка?",
    COALESCE(error_description, 'Ошибок нет') AS "Описание ошибки",
    COALESCE(meteo_approx, '-') AS "Метео приближенный"
FROM batch_validated
ORDER BY batch_id ASC;


-- ЗАПРОС 2: Лучший стрелок
WITH batch_params AS (
    SELECT
        mb.id AS batch_id,
        mb.employee_id,
        ( -- Наш составной тип
            MAX(m.equipment_type_id),
            MAX(m."value") FILTER (WHERE m.parameter_id = 1),
            MAX(m."value") FILTER (WHERE m.parameter_id = 2),
            MAX(m."value") FILTER (WHERE m.parameter_id = 3),
            MAX(m."value") FILTER (WHERE m.parameter_id = 4),
            MAX(m."value") FILTER (WHERE m.parameter_id = 5),
            MAX(m."value") FILTER (WHERE m.parameter_id = 6)
        )::calc.parameters_list AS params
    FROM public.measurement_batches mb
    LEFT JOIN public.measurements m ON m.measurement_batch_id = mb.id
    GROUP BY mb.id, mb.employee_id
),
batch_error_counts AS (
    SELECT
        bp.batch_id,
        bp.employee_id,
        COALESCE(
            CARDINALITY(STRING_TO_ARRAY(calc.validate_parameters(bp.params), '; ')),
            0
        ) AS error_count
    FROM batch_params bp
),
employee_totals AS (
    SELECT
        e.id AS employee_id,
        mr.title AS rank_title,
        e.surname || ' ' || e.name AS employee_name,
        COUNT(bec.batch_id) AS total_batches,
        COALESCE(SUM(bec.error_count), 0) AS total_errors
    FROM public.employees e
    LEFT JOIN reference.military_ranks mr ON mr.id = e.rank_id
    LEFT JOIN batch_error_counts bec ON bec.employee_id = e.id
    GROUP BY e.id, mr.title, e.surname, e.name
)
SELECT
    DENSE_RANK() OVER (ORDER BY total_errors ASC, total_batches DESC) AS "Место",
    rank_title AS "Звание",
    employee_name AS "Пользователь",
    total_batches AS "Пачек измерений",
    total_errors AS "Количество допущенных ошибок",
    SUM(total_errors) OVER () AS "Всего ошибок по всем стрелкам"
FROM employee_totals
ORDER BY "Место", employee_name;

-- Откатываем временные тестовые данные
ROLLBACK;