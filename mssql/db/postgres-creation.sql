-- ============================================================================
-- СКРИПТ:
-- - src - зеркало Front (MSSQL -> Postgres) - STG (Staging)
-- - dwh - DWH (Data Warehouse)
-- ============================================================================

DO $$
BEGIN
    CREATE SCHEMA IF NOT EXISTS src;

    DROP TABLE IF EXISTS src.bm_journalbarnetdocs CASCADE;
    DROP TABLE IF EXISTS src.bm_storageoperations CASCADE;
    DROP TABLE IF EXISTS src.product CASCADE;
    DROP TABLE IF EXISTS src.category CASCADE;
    DROP TABLE IF EXISTS src.vendors CASCADE;
    DROP TABLE IF EXISTS src.vendorgroup CASCADE;
    DROP TABLE IF EXISTS src.personnel CASCADE;
    DROP TABLE IF EXISTS src.journal CASCADE;
    DROP TABLE IF EXISTS src.securityaccess CASCADE;
    DROP TABLE IF EXISTS src.size CASCADE;

    DROP SEQUENCE IF EXISTS src.bm_journalbarnetdocs_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.bm_storageoperations_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.product_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.category_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.vendors_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.vendorgroup_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.personnel_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.journal_seq CASCADE;
    DROP SEQUENCE IF EXISTS src.size_seq CASCADE;

    CREATE SEQUENCE IF NOT EXISTS src.bm_journalbarnetdocs_seq;
    CREATE TABLE src.bm_journalbarnetdocs (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.bm_journalbarnetdocs_seq'),
        documenttypeid INT,
        period TIMESTAMP,
        amount NUMERIC(18, 2),
        personid INT,
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.bm_journalbarnetdocs_seq OWNED BY src.bm_journalbarnetdocs.id;
    COMMENT ON TABLE src.bm_journalbarnetdocs IS 'Шапки документов (bm_JournalBarnetDocs)';

    CREATE SEQUENCE IF NOT EXISTS src.bm_storageoperations_seq;
    CREATE TABLE src.bm_storageoperations (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.bm_storageoperations_seq'),
        documentid INT,
        operationid INT,
        productid INT,
        vendorid INT,
        rangeid INT,
        count NUMERIC(18, 4),
        amount NUMERIC(18, 2),
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.bm_storageoperations_seq OWNED BY src.bm_storageoperations.id;
    COMMENT ON TABLE src.bm_storageoperations IS 'Строки операций (bm_StorageOperations)';

    CREATE SEQUENCE IF NOT EXISTS src.product_seq;
    CREATE TABLE src.product (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.product_seq'),
        productid INT,
        description VARCHAR(255),
        categoryid INT,
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.product_seq OWNED BY src.product.id;
    COMMENT ON TABLE src.product IS 'Продукты (product)';

    CREATE SEQUENCE IF NOT EXISTS src.category_seq;
    CREATE TABLE src.category (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.category_seq'),
        description VARCHAR(255),
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.category_seq OWNED BY src.category.id;
    COMMENT ON TABLE src.category IS 'Категории (category)';

    CREATE SEQUENCE IF NOT EXISTS src.vendors_seq;
    CREATE TABLE src.vendors (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.vendors_seq'),
        firstname VARCHAR(255),
        clientgroup INT,
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.vendors_seq OWNED BY src.vendors.id;
    COMMENT ON TABLE src.vendors IS 'Поставщики (vendors)';

    CREATE SEQUENCE IF NOT EXISTS src.vendorgroup_seq;
    CREATE TABLE src.vendorgroup (
        vendorgroupid INT NOT NULL PRIMARY KEY DEFAULT nextval('src.vendorgroup_seq'),
        description VARCHAR(255),
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.vendorgroup_seq OWNED BY src.vendorgroup.vendorgroupid;
    COMMENT ON TABLE src.vendorgroup IS 'Группы поставщиков (vendorgroup)';

    CREATE SEQUENCE IF NOT EXISTS src.personnel_seq;
    CREATE TABLE src.personnel (
        personid INT NOT NULL PRIMARY KEY DEFAULT nextval('src.personnel_seq'),
        lastname VARCHAR(255),
        firstname VARCHAR(255),
        securityaccess INT,
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.personnel_seq OWNED BY src.personnel.personid;
    COMMENT ON TABLE src.personnel IS 'Сотрудники (personnel)';

    CREATE SEQUENCE IF NOT EXISTS src.journal_seq;
    CREATE TABLE src.journal (
        transnumber INT NOT NULL PRIMARY KEY DEFAULT nextval('src.journal_seq'),
        transtype INT,
        receiptn BIGINT,
        dater TIMESTAMP,
        id INT,
        description VARCHAR(255),
        quantity NUMERIC(18, 3),
        amount NUMERIC(18, 2),
        loginid INT,
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.journal_seq OWNED BY src.journal.transnumber;
    COMMENT ON TABLE src.journal IS 'Журнал транзакций (journal)';

    CREATE TABLE src.securityaccess (
        securityaccessid INT,
        description VARCHAR(255),
        date_add TIMESTAMP DEFAULT now()
    );
    COMMENT ON TABLE src.securityaccess IS 'Роли (securityaccess)';

    CREATE SEQUENCE IF NOT EXISTS src.size_seq;
    CREATE TABLE src.size (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('src.size_seq'),
        sizeid VARCHAR(50),
        description VARCHAR(255),
        portionrate NUMERIC(18, 3),
        date_add TIMESTAMP DEFAULT now()
    );
    ALTER SEQUENCE src.size_seq OWNED BY src.size.id;
    COMMENT ON TABLE src.size IS 'Единицы измерения (size)';

END $$;


DO $$
BEGIN
    CREATE SCHEMA IF NOT EXISTS dwh;

    DROP TABLE IF EXISTS dwh.fact_purchase CASCADE;
    DROP TABLE IF EXISTS dwh.fact_sales CASCADE;
    DROP TABLE IF EXISTS dwh.fact_personnel_activity CASCADE;
    DROP TABLE IF EXISTS dwh.fact_inventory CASCADE;

    DROP TABLE IF EXISTS dwh.dim_product CASCADE;
    DROP TABLE IF EXISTS dwh.dim_vendor CASCADE;
    DROP TABLE IF EXISTS dwh.dim_personnel CASCADE;
    DROP TABLE IF EXISTS dwh.dim_time CASCADE;

    DROP SEQUENCE IF EXISTS dwh.dim_product_seq CASCADE;
    DROP SEQUENCE IF EXISTS dwh.dim_vendor_seq CASCADE;
    DROP SEQUENCE IF EXISTS dwh.dim_personnel_seq CASCADE;
    DROP SEQUENCE IF EXISTS dwh.fact_purchase_seq CASCADE;
    DROP SEQUENCE IF EXISTS dwh.fact_sales_seq CASCADE;

    -- Измерения ------------------------------------------------------------

    CREATE TABLE dwh.dim_time (
        time_code INT NOT NULL PRIMARY KEY, -- вида 202611
        month_start DATE NOT NULL,
        month_end DATE NOT NULL,
        month_name VARCHAR(20) NOT NULL,
        year INT NOT NULL,
        quarter_num INT NOT NULL,
        quarter_name VARCHAR(20) NOT NULL
    );
    COMMENT ON TABLE dwh.dim_time IS 'Месяцы';

    CREATE SEQUENCE IF NOT EXISTS dwh.dim_product_seq;
    CREATE TABLE dwh.dim_product (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('dwh.dim_product_seq'),
        external_id INT NOT NULL UNIQUE, -- из src
        article INT,
        name VARCHAR(255),
        category_name VARCHAR(255)
    );
    ALTER SEQUENCE dwh.dim_product_seq OWNED BY dwh.dim_product.id;
    COMMENT ON TABLE dwh.dim_product IS 'Товары (product)';

    CREATE SEQUENCE IF NOT EXISTS dwh.dim_vendor_seq;
    CREATE TABLE dwh.dim_vendor (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('dwh.dim_vendor_seq'),
        external_id INT NOT NULL UNIQUE, -- из src
        name VARCHAR(255),
        group_name VARCHAR(255)
    );
    ALTER SEQUENCE dwh.dim_vendor_seq OWNED BY dwh.dim_vendor.id;
    COMMENT ON TABLE dwh.dim_vendor IS 'Поставщики (vendors)';

    CREATE SEQUENCE IF NOT EXISTS dwh.dim_personnel_seq;
    CREATE TABLE dwh.dim_personnel (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('dwh.dim_personnel_seq'),
        external_id INT NOT NULL UNIQUE, -- из src
        full_name TEXT,
        role_name VARCHAR(255)
    );
    ALTER SEQUENCE dwh.dim_personnel_seq OWNED BY dwh.dim_personnel.id;
    COMMENT ON TABLE dwh.dim_personnel IS 'Сотрудники (personnel)';

    -- Факты ----------------------------------------------------------------

    CREATE SEQUENCE IF NOT EXISTS dwh.fact_purchase_seq;
    CREATE TABLE dwh.fact_purchase (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('dwh.fact_purchase_seq'),
        time_code INT NOT NULL REFERENCES dwh.dim_time(time_code),
        product_id INT NOT NULL REFERENCES dwh.dim_product(id),
        vendor_id INT NOT NULL REFERENCES dwh.dim_vendor(id),
        document_id INT,
        quantity NUMERIC(18, 4), -- количество
        amount NUMERIC(18, 2) -- на сумму
    );
    ALTER SEQUENCE dwh.fact_purchase_seq OWNED BY dwh.fact_purchase.id;
    COMMENT ON TABLE dwh.fact_purchase IS 'Закупки';

    CREATE SEQUENCE IF NOT EXISTS dwh.fact_sales_seq;
    CREATE TABLE dwh.fact_sales (
        id INT NOT NULL PRIMARY KEY DEFAULT nextval('dwh.fact_sales_seq'),
        time_code INT NOT NULL REFERENCES dwh.dim_time(time_code),
        product_id INT NOT NULL REFERENCES dwh.dim_product(id),
        personnel_id INT NOT NULL REFERENCES dwh.dim_personnel(id),
        receipt_number BIGINT,
        quantity NUMERIC(18, 3), -- количество
        revenue NUMERIC(18, 2) -- на сумму
    );
    ALTER SEQUENCE dwh.fact_sales_seq OWNED BY dwh.fact_sales.id;
    COMMENT ON TABLE dwh.fact_sales IS 'Продажи';

    CREATE TABLE dwh.fact_personnel_activity (
        time_code INT NOT NULL REFERENCES dwh.dim_time(time_code),
        personnel_id INT NOT NULL REFERENCES dwh.dim_personnel(id),
        activity VARCHAR(255) NOT NULL, -- тип работы
        operations_count INT NOT NULL DEFAULT 0, -- количество операций этого типа
        amount NUMERIC(18, 2), -- на сумму
        PRIMARY KEY (time_code, personnel_id, activity)
    );
    COMMENT ON TABLE dwh.fact_personnel_activity IS 'Работа персонала';

    CREATE TABLE dwh.fact_inventory (
        time_code INT NOT NULL REFERENCES dwh.dim_time(time_code),
        product_id INT NOT NULL REFERENCES dwh.dim_product(id),
        unit_id INT NOT NULL,
        unit_name VARCHAR(255),
        quantity NUMERIC(18, 4), -- количество
        amount NUMERIC(18, 2), -- на сумму
        PRIMARY KEY (time_code, product_id, unit_id)
    );
    COMMENT ON TABLE dwh.fact_inventory IS 'Остатки';

END $$;
