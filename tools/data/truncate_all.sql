DROP PROCEDURE IF EXISTS procDropAllTables;

DELIMITER //

CREATE PROCEDURE procDropAllTables()

BEGIN
        DECLARE table_name VARCHAR(255);
        DECLARE end_of_tables INT DEFAULT 0;

        DECLARE cur CURSOR FOR
            SELECT t.table_name
            FROM information_schema.tables t
            WHERE t.table_schema = DATABASE() AND t.table_type='BASE TABLE';
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET end_of_tables = 1;

        SET FOREIGN_KEY_CHECKS = 0;
        OPEN cur;

        tables_loop: LOOP
            FETCH cur INTO table_name;

            IF end_of_tables = 1 THEN
                LEAVE tables_loop;
            END IF;

            SET @s = CONCAT('TRUNCATE TABLE ' , table_name);
            PREPARE stmt FROM @s;
            EXECUTE stmt;

        END LOOP;

        CLOSE cur;
        SET FOREIGN_KEY_CHECKS = 1;
    END//

DELIMITER ;
CALL procDropAllTables();
