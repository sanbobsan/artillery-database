-- ============================================================================
-- СКРИПТ: src - зеркало Front (MSSQL -> Postgres)
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
