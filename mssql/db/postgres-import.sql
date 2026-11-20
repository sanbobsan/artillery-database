COPY src.bm_journalbarnetdocs (id, documenttypeid, period, amount, personid)
FROM '/csv/bm_JournalBarnetDocs.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.bm_storageoperations (id, documentid, operationid, productid, vendorid, rangeid, count, amount)
FROM '/csv/bm_StorageOperations.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.product (id, productid, description, categoryid)
FROM '/csv/product.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.category (id, description)
FROM '/csv/category.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.vendors (id, firstname, clientgroup)
FROM '/csv/vendors.csv'
WITH (FORMAT text, DELIMITER ',', HEADER true, ENCODING 'UTF8');

COPY src.vendorgroup (vendorgroupid, description)
FROM '/csv/vendorgroup.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.personnel (personid, lastname, firstname, securityaccess)
FROM '/csv/personnel.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.journal (transnumber, transtype, receiptn, dater, id, description, quantity, amount, loginid)
FROM '/csv/journal.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.securityaccess (securityaccessid, description)
FROM '/csv/securityaccess.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY src.size (id, sizeid, description, portionrate)
FROM '/csv/size.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
