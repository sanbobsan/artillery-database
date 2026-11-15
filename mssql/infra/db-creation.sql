-- Создать новую базу данных
CREATE DATABASE Front
GO

-- Переключиться на системную базу данных
USE master;
GO

-- Восстановить базу данных
RESTORE DATABASE Front
FROM DISK = '/backup/rest.bak'
WITH REPLACE,
MOVE 'pos' TO '/var/opt/mssql/data/rest.mdf', 
MOVE 'pos_log' TO '/var/opt/mssql/data/rest_log.ldf'; 
GO

-- Посмотреть физические файлы новой базы данных
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    type_desc AS FileType,
    physical_name AS PhysicalPath
FROM sys.master_files
WHERE DB_NAME(database_id) = 'Front';
GO