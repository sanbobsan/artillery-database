-- Создание структуры с нуля

DO $$
BEGIN
    -- Удаляем, если были до этого
    DROP TABLE IF EXISTS unit_conversions CASCADE;
    DROP TABLE IF EXISTS measurements CASCADE;
    DROP TABLE IF EXISTS measurements_buckets CASCADE;
    DROP TABLE IF EXISTS parameters CASCADE;
    DROP TABLE IF EXISTS units CASCADE;
    DROP TABLE IF EXISTS parameter_types CASCADE;
    DROP TABLE IF EXISTS equipment_types CASCADE;
    DROP TABLE IF EXISTS employees CASCADE;
    DROP TABLE IF EXISTS military_ranks CASCADE;

    DROP SEQUENCE IF EXISTS seq_military_ranks;
    DROP SEQUENCE IF EXISTS seq_employees;
    DROP SEQUENCE IF EXISTS seq_equipment_types;
    DROP SEQUENCE IF EXISTS seq_parameter_types;
    DROP SEQUENCE IF EXISTS seq_units;
    DROP SEQUENCE IF EXISTS seq_parameters;
    DROP SEQUENCE IF EXISTS seq_measurements_buckets;

    -- Счетчики
    CREATE SEQUENCE seq_military_ranks;
    CREATE SEQUENCE seq_employees;
    CREATE SEQUENCE seq_equipment_types;
    CREATE SEQUENCE seq_parameter_types;
    CREATE SEQUENCE seq_units;
    CREATE SEQUENCE seq_parameters;
    CREATE SEQUENCE seq_measurements_buckets;

    -- Звания
    CREATE TABLE military_ranks (
        id INT NOT NULL DEFAULT nextval('seq_military_ranks') PRIMARY KEY,
        title VARCHAR(100) NOT NULL UNIQUE
    );
    ALTER SEQUENCE seq_military_ranks OWNED BY military_ranks.id;

    -- Работники
    CREATE TABLE employees (
        id INT NOT NULL DEFAULT nextval('seq_employees') PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        surname VARCHAR(100) NOT NULL,
        rank_id INT REFERENCES military_ranks (id)
    );
    ALTER SEQUENCE seq_employees OWNED BY employees.id;

    -- Типы оборудования для измерений
    CREATE TABLE equipment_types (
        id INT NOT NULL DEFAULT nextval('seq_equipment_types') PRIMARY KEY,
        title VARCHAR(100) NOT NULL UNIQUE,
        abbreviation VARCHAR(20) NOT NULL UNIQUE
    );
    ALTER SEQUENCE seq_equipment_types OWNED BY equipment_types.id;

    -- Типы параметров, возможные параметры без единиц измерения
    CREATE TABLE parameter_types (
        id INT NOT NULL DEFAULT nextval('seq_parameter_types') PRIMARY KEY,
        title VARCHAR(100) NOT NULL UNIQUE
    );
    ALTER SEQUENCE seq_parameter_types OWNED BY parameter_types.id;

    -- Единицы измерения
    CREATE TABLE units (
        id INT NOT NULL DEFAULT nextval('seq_units') PRIMARY KEY,
        title VARCHAR(100) NOT NULL UNIQUE,
        abbreviation VARCHAR(20) NOT NULL UNIQUE
    );
    ALTER SEQUENCE seq_units OWNED BY units.id;

    -- Параметры с единицами измерения, не хранит измерения
    CREATE TABLE parameters (
        id INT NOT NULL DEFAULT nextval('seq_parameters') PRIMARY KEY,
        parameter_type_id INT NOT NULL REFERENCES parameter_types (id),
        unit_id INT NOT NULL REFERENCES units (id),
        default_value DECIMAL(10, 0) NULL,
        min_value DECIMAL(10, 0) NULL,
        max_value DECIMAL(10, 0) NULL
    );
    ALTER SEQUENCE seq_parameters OWNED BY parameters.id;

    -- Пачки измерений
    CREATE TABLE measurements_buckets (
        id INT NOT NULL DEFAULT nextval('seq_measurements_buckets') PRIMARY KEY,
        employee_id INT NOT NULL REFERENCES employees (id)
    );
    ALTER SEQUENCE seq_measurements_buckets OWNED BY measurements_buckets.id;

    -- Измерения.
    CREATE TABLE measurements (
        measurements_bucket_id INT NOT NULL REFERENCES measurements_buckets (id),
        equipment_type_id INT NOT NULL REFERENCES equipment_types (id),
        parameter_id INT NOT NULL REFERENCES parameters (id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "value" DECIMAL(10, 0) NOT NULL,
        PRIMARY KEY (measurements_bucket_id, parameter_id)
    );

    -- Таблица перевода единиц измерения.
    CREATE TABLE unit_conversions (
        from_unit_id INT NOT NULL REFERENCES units (id),
        to_unit_id INT NOT NULL REFERENCES units (id),
        from_value DECIMAL(10, 0),
        to_value DECIMAL(10, 0),
        PRIMARY KEY (from_unit_id, to_unit_id)
    );
COMMIT;
END $$;