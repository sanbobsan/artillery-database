USE Front;

-- Шапки документов
SELECT 
  ID,
  DocumentTypeID,
  Period,
  Amount,
  PersonID
FROM bm_JournalBarnetDocs
ORDER BY ID;

-- Строки операций
SELECT
  ID,
  DocumentID,
  OperationID,
  ProductID,
  VendorID,
  RangeID,
  Count,
  Amount
FROM bm_StorageOperations
ORDER BY ID;

-- Продукты
SELECT
  id,
  productid,
  description,
  CategoryID
FROM product
ORDER BY id;

-- Категории
SELECT
  id,
  description 
FROM category 
ORDER BY id;

-- Поставщики
SELECT
  id,
  firstname,
  clientgroup
FROM vendors
ORDER BY id;

-- Группы поставщиков
SELECT
  vendorgroupid,
  description 
FROM vendorgroup
ORDER BY vendorgroupid;

-- Сотрудники
SELECT
  personid,
  lastname,
  firstname,
  securityaccess
FROM personnel
ORDER BY personid;

-- Журнал
SELECT 
  transnumber,
  transtype,
  receiptn,
  dater,
  CAST(NULLIF(id, '') AS INT) AS id,
  description,
  quantity,
  amount,
  loginid
FROM journal
ORDER BY transnumber;

-- Роли
SELECT 
  securityaccessid,
  description 
FROM securityaccess 
ORDER BY securityaccessid;

-- Единицы измерения
SELECT
  ID,
  sizeid,
  description,
  portionrate
FROM size
ORDER BY ID;
