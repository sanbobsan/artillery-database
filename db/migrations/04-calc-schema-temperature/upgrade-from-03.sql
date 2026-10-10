-- Расчетные таблицы: схема calc

CREATE SCHEMA IF NOT EXISTS calc;

CREATE TABLE calc.temperature_correction (
    temperature DECIMAL(3, 1) PRIMARY KEY,
    correction DECIMAL(2, 1) NOT NULL
);
-- Данные этих таблиц зашиты в базу данных, поэтому их изменение считаются миграцией
INSERT INTO calc.virtual_temperature_correction (temperature, correction) 
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