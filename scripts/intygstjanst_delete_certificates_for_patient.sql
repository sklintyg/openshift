-- This script deletes certificates and related information for a certain patient.


DELIMITER $$
CREATE PROCEDURE delete_certificates()
BEGIN

    DECLARE caughtException int DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET caughtException = 1;


    START TRANSACTION;


    SET @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER := '19121212-1212';
    SET @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER_WITHOUT_DASH := REPLACE(@DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER, '-', '');
    SELECT CONCAT('Delete certificates for ', @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER, ' and ', @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER_WITHOUT_DASH, '.');


    -- Create temporary tables
    CREATE TEMPORARY TABLE `TEMP_CERTIFICATES_TO_DELETE` (
       `ID` varchar(64) NOT NULL,
       PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TEMPORARY TABLE `TEMP_SJUKFALL_CERT_TO_DELETE` (
       `CERTIFICATE_ID` varchar(255) NOT NULL,
       PRIMARY KEY (`CERTIFICATE_ID`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    -- Fill temporary tables
    INSERT INTO TEMP_CERTIFICATES_TO_DELETE SELECT ID FROM CERTIFICATE WHERE CIVIC_REGISTRATION_NUMBER = @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER;
    INSERT INTO TEMP_SJUKFALL_CERT_TO_DELETE SELECT ID FROM SJUKFALL_CERT WHERE CIVIC_REGISTRATION_NUMBER IN (@DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER, @DELETE_CERTIFICATES_FOR_PATIENT_PERSONAL_NUMBER_WITHOUT_DASH);


    -- Delete from relevant tables from temporary table
    DELETE FROM APPROVED_RECEIVER WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
    DELETE FROM ARENDE WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

    DELETE FROM RELATION WHERE FROM_INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
    DELETE FROM RELATION WHERE TO_INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

    DELETE FROM SJUKFALL_CERT_WORK_CAPACITY WHERE CERTIFICATE_ID IN (SELECT CERTIFICATE_ID FROM TEMP_SJUKFALL_CERT_TO_DELETE);
    DELETE FROM SJUKFALL_CERT WHERE ID IN (SELECT CERTIFICATE_ID FROM TEMP_SJUKFALL_CERT_TO_DELETE);

    DELETE FROM CERTIFICATE_METADATA WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
    DELETE FROM CERTIFICATE_STATE WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
    DELETE FROM ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
    DELETE FROM CERTIFICATE WHERE ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);


    -- Drop temporary tables
    DROP TABLE TEMP_CERTIFICATES_TO_DELETE;
    DROP TABLE TEMP_SJUKFALL_CERT_TO_DELETE;


    IF (caughtException) THEN
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
    ELSE
        COMMIT;
        SELECT 'Deletion of certificates was successfully.';
    END IF;


END $$
DELIMITER ;


USE intyg;
CALL delete_certificates;
DROP PROCEDURE delete_certificates;
