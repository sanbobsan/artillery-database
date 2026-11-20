
-- Структуры и функции для хранения констант в схеме calc,
-- перевод таблицы температурных поправок в 1/10 градуса

DO $$
BEGIN
    -- Таблица констант
    DROP TABLE IF EXISTS calc.constants CASCADE;

    CREATE TABLE calc.constants (
        code VARCHAR(100) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        "value" NUMERIC(10, 2) NOT NULL,
        unit_id INT NULL REFERENCES reference.units (id)
    );

    COMMENT ON TABLE calc.constants IS 'Расчетные константы';
    COMMENT ON COLUMN calc.constants.code IS 'Код константы';
    COMMENT ON COLUMN calc.constants.title IS 'Наименование константы';
    COMMENT ON COLUMN calc.constants."value" IS 'Значение константы';
    COMMENT ON COLUMN calc.constants.unit_id IS 'Ссылка на единицу измерения';

    -- Константы, необходимые для формул расчета
    INSERT INTO calc.constants (code, title, "value", unit_id)
    VALUES
        ('NORMAL_PRESSURE', 'Табличное наземное давление (мм рт. ст.)', 750, 3),
        ('NORMAL_VIRTUAL_TEMP', 'Табличная приземная виртуальная температура (*C/10)', 159, 2);

    -- Переводим таблицу температурных поправок calc.temperature_correction в *C/10 вместо дробных значений
    ALTER TABLE calc.temperature_correction
        ALTER COLUMN temperature TYPE SMALLINT,
        ALTER COLUMN correction TYPE SMALLINT;

    TRUNCATE TABLE calc.temperature_correction;

    INSERT INTO calc.temperature_correction (temperature, correction)
    VALUES
        (0, 0),
        (50, 5),
        (100, 10),
        (150, 10),
        (200, 15),
        (250, 20),
        (300, 35),
        (400, 45);

    -- Функция получения значения константы по коду
    CREATE OR REPLACE FUNCTION calc.get_constant(p_code VARCHAR)
    RETURNS NUMERIC
    LANGUAGE plpgsql
    STABLE
    AS $func$
    DECLARE
        v_value NUMERIC;
    BEGIN
        SELECT "value"
        INTO v_value
        FROM calc.constants
        WHERE code = p_code;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Константа % не найдена в таблице calc.constants', p_code;
        END IF;

        RETURN v_value;
    END;
    $func$;

    COMMENT ON FUNCTION calc.get_constant(VARCHAR)
    IS 'Возвращает значение константы из таблицы calc.constants по ее коду';

    -- 4. Функция перевода единиц измерения (для перевода *C/10 в *C в конце вычислений)
    CREATE OR REPLACE FUNCTION calc.convert_unit(
        p_value NUMERIC,
        p_from_unit_id INT,
        p_to_unit_id INT
    )
    RETURNS NUMERIC
    LANGUAGE plpgsql
    STABLE
    AS $func$
    DECLARE
        v_from_val NUMERIC;
        v_to_val NUMERIC;
    BEGIN
        IF p_from_unit_id = p_to_unit_id THEN
            RETURN p_value;
        END IF;

        SELECT from_value, to_value
        INTO v_from_val, v_to_val
        FROM reference.unit_conversions
        WHERE from_unit_id = p_from_unit_id
          AND to_unit_id = p_to_unit_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Конвертация из unit_id=% в unit_id=% не найдена', p_from_unit_id, p_to_unit_id;
        END IF;

        RETURN p_value * (v_to_val / v_from_val);
    END;
    $func$;

    COMMENT ON FUNCTION calc.convert_unit(NUMERIC, INT, INT)
    IS 'Переводит значение между единицами измерения по справочнику reference.unit_conversions';
END $$;