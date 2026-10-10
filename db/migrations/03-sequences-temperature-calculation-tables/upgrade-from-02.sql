-- Скрипт для миграции с прошлой версии базы данных

-- Убирает identity с колонок id и навешивает явные счетчики.
-- Синхронизирует каждый счётчик с текущим максимальным id, чтобы номер продолжался с последнего значения.
-- Добавляет связи FK.

DO $$
BEGIN
    -- 1. Воинские звания
    ALTER TABLE military_ranks ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE military_ranks ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_military_ranks CASCADE;
    CREATE SEQUENCE seq_military_ranks;
    ALTER TABLE military_ranks ALTER COLUMN id SET DEFAULT nextval('seq_military_ranks');
    ALTER SEQUENCE seq_military_ranks OWNED BY military_ranks.id;
    PERFORM setval('seq_military_ranks',
        COALESCE((SELECT MAX(id) FROM military_ranks), 1),
        EXISTS (SELECT 1 FROM military_ranks));

    -- 2. Работники
    ALTER TABLE employees ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE employees ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_employees CASCADE;
    CREATE SEQUENCE seq_employees;
    ALTER TABLE employees ALTER COLUMN id SET DEFAULT nextval('seq_employees');
    ALTER SEQUENCE seq_employees OWNED BY employees.id;
    PERFORM setval('seq_employees',
        COALESCE((SELECT MAX(id) FROM employees), 1),
        EXISTS (SELECT 1 FROM employees));

    -- 3. Типы оборудования для измерений
    ALTER TABLE equipment_types ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE equipment_types ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_equipment_types CASCADE;
    CREATE SEQUENCE seq_equipment_types;
    ALTER TABLE equipment_types ALTER COLUMN id SET DEFAULT nextval('seq_equipment_types');
    ALTER SEQUENCE seq_equipment_types OWNED BY equipment_types.id;
    PERFORM setval('seq_equipment_types',
        COALESCE((SELECT MAX(id) FROM equipment_types), 1),
        EXISTS (SELECT 1 FROM equipment_types));

    -- 4. Типы параметров
    ALTER TABLE parameter_types ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE parameter_types ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_parameter_types CASCADE;
    CREATE SEQUENCE seq_parameter_types;
    ALTER TABLE parameter_types ALTER COLUMN id SET DEFAULT nextval('seq_parameter_types');
    ALTER SEQUENCE seq_parameter_types OWNED BY parameter_types.id;
    PERFORM setval('seq_parameter_types',
        COALESCE((SELECT MAX(id) FROM parameter_types), 1),
        EXISTS (SELECT 1 FROM parameter_types));

    -- 5. Единицы измерения
    ALTER TABLE units ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE units ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_units CASCADE;
    CREATE SEQUENCE seq_units;
    ALTER TABLE units ALTER COLUMN id SET DEFAULT nextval('seq_units');
    ALTER SEQUENCE seq_units OWNED BY units.id;
    PERFORM setval('seq_units',
        COALESCE((SELECT MAX(id) FROM units), 1),
        EXISTS (SELECT 1 FROM units));

    -- 6. Параметры с единицами измерения
    ALTER TABLE parameters ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE parameters ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_parameters CASCADE;
    CREATE SEQUENCE seq_parameters;
    ALTER TABLE parameters ALTER COLUMN id SET DEFAULT nextval('seq_parameters');
    ALTER SEQUENCE seq_parameters OWNED BY parameters.id;
    PERFORM setval('seq_parameters',
        COALESCE((SELECT MAX(id) FROM parameters), 1),
        EXISTS (SELECT 1 FROM parameters));

    -- 7. Пачки измерений
    ALTER TABLE measurements_buckets ALTER COLUMN id DROP IDENTITY IF EXISTS;
    ALTER TABLE measurements_buckets ALTER COLUMN id SET NOT NULL;
    DROP SEQUENCE IF EXISTS seq_measurements_buckets CASCADE;
    CREATE SEQUENCE seq_measurements_buckets;
    ALTER TABLE measurements_buckets ALTER COLUMN id SET DEFAULT nextval('seq_measurements_buckets');
    ALTER SEQUENCE seq_measurements_buckets OWNED BY measurements_buckets.id;
    PERFORM setval('seq_measurements_buckets',
        COALESCE((SELECT MAX(id) FROM measurements_buckets), 1),
        EXISTS (SELECT 1 FROM measurements_buckets));

    -- У остальных 2 таблиц PK составлены из id этих

    -- Связи между таблицами (в схеме 02 отсутствовали)
    ALTER TABLE employees ADD CONSTRAINT fk_employees_rank
        FOREIGN KEY (rank_id) REFERENCES military_ranks (id);

    ALTER TABLE parameters ADD CONSTRAINT fk_parameters_type
        FOREIGN KEY (parameter_type_id) REFERENCES parameter_types (id);

    ALTER TABLE parameters ADD CONSTRAINT fk_parameters_unit
        FOREIGN KEY (unit_id) REFERENCES units (id);

    ALTER TABLE measurements_buckets ADD CONSTRAINT fk_measurements_buckets_employee
        FOREIGN KEY (employee_id) REFERENCES employees (id);

    ALTER TABLE measurements ADD CONSTRAINT fk_measurements_bucket
        FOREIGN KEY (measurements_bucket_id) REFERENCES measurements_buckets (id);

    ALTER TABLE measurements ADD CONSTRAINT fk_measurements_equipment
        FOREIGN KEY (equipment_type_id) REFERENCES equipment_types (id);

    ALTER TABLE measurements ADD CONSTRAINT fk_measurements_parameter
        FOREIGN KEY (parameter_id) REFERENCES parameters (id);

    ALTER TABLE unit_conversions ADD CONSTRAINT fk_unit_conversions_from
        FOREIGN KEY (from_unit_id) REFERENCES units (id);

    ALTER TABLE unit_conversions ADD CONSTRAINT fk_unit_conversions_to
        FOREIGN KEY (to_unit_id) REFERENCES units (id);
END;
$$;