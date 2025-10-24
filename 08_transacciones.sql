-- tabla de registro de transacciones y errrores 
USE vet;
-- Log de transacciones/errores
CREATE TABLE tx_log (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 etiqueta VARCHAR(50),
 intento INT,
 error_code INT NULL,
 error_msg TEXT NULL,
 detalle TEXT NULL,
 ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
--índice para consultas/updates por veterinaria
CREATE INDEX idx_microchip_veterinaria ON microchip(veterinaria);

-- Deadlock en 2 Sesiones.
USE vet;
-- Elegimos dos pares válidos (microchip_id no nulo)
SELECT m1.id AS mascotaA, m1.microchip_id AS chipA,
 m2.id AS mascotaB, m2.microchip_id AS chipB
FROM mascota m1
JOIN mascota m2 ON m2.id <> m1.id
WHERE m1.microchip_id IS NOT NULL
 AND m2.microchip_id IS NOT NULL
LIMIT 1;

-- Sesión 1
USE vet;
SET autocommit=0;
START TRANSACTION;
-- 1) Bloquea una fila de mascota
UPDATE mascota
SET raza = raza
WHERE id = 276592;
-- 2) Luego intenta bloquear microchip del otro par (quedará esperando)
UPDATE microchip
SET observaciones = CONCAT('upd S1 ', NOW())
WHERE id = 262334;
-- Sesión 2
USE vet;
SET autocommit=0;
START TRANSACTION;
-- 1) Bloquea un microchip del segundo par
UPDATE microchip
SET observaciones = CONCAT('upd S2 ', NOW())
WHERE id = 262334;
-- 2) Luego intenta bloquear la mascota del primer par (ciclo de espera)
UPDATE mascota
SET raza = raza
WHERE id = 276592;

-- 2. Procedimiento SQL con transacción + retry (hasta 2 reintentos)
-- Stored Procedure retry
CREATE PROCEDURE sp_update_chip_retry(
 IN p_chip_id BIGINT UNSIGNED,
 IN p_etiqueta VARCHAR(50)
)
BEGIN
 DECLARE v_try INT DEFAULT 0;
 DECLARE v_max INT DEFAULT 2;
 DECLARE v_err INT DEFAULT 0;
 DECLARE v_msg TEXT DEFAULT NULL;
 retry_loop: LOOP
 SET v_try = v_try + 1;
 SET v_err = 0; SET v_msg = NULL;
 -- Marca de inicio del intento
 INSERT INTO tx_log(etiqueta,intento,error_code,error_msg,detalle)
 VALUES(p_etiqueta, v_try, NULL, 'BEGIN', 
CONCAT('chip=',p_chip_id));
 BEGIN
 -- Si hay DEADLOCK (1213) o LOCK WAIT TIMEOUT (1205) → log + 
ROLLBACK
 DECLARE CONTINUE HANDLER FOR 1213
 BEGIN
 GET DIAGNOSTICS CONDITION 1 v_err = MYSQL_ERRNO, v_msg = 
MESSAGE_TEXT;
 ROLLBACK;
 INSERT INTO 
tx_log(etiqueta,intento,error_code,error_msg,detalle)
 VALUES(p_etiqueta, v_try, v_err, v_msg, 'deadlock');
 END;
67
 DECLARE CONTINUE HANDLER FOR 1205
 BEGIN
 GET DIAGNOSTICS CONDITION 1 v_err = MYSQL_ERRNO, v_msg = 
MESSAGE_TEXT;
 ROLLBACK;
 INSERT INTO 
tx_log(etiqueta,intento,error_code,error_msg,detalle)
 VALUES(p_etiqueta, v_try, v_err, v_msg, 
'lock_wait_timeout');
 END;
 START TRANSACTION;
 UPDATE microchip
 SET observaciones = CONCAT('[', p_etiqueta, ' T', v_try, 
'] ', COALESCE(observaciones,''))
 WHERE id = p_chip_id;
 COMMIT;
 IF v_err = 0 THEN
 INSERT INTO 
tx_log(etiqueta,intento,error_code,error_msg,detalle)
 VALUES(p_etiqueta, v_try, NULL, 'OK', 'commit');
 END IF;
 END;
 IF v_err = 0 THEN
 LEAVE retry_loop;
 END IF;
 -- Reintenta sólo si fue 1213 o 1205 y aún quedan intentos
 IF v_err IN (1213,1205) AND v_try <= v_max THEN
 DO SLEEP(0.1 * v_try); -- backoff breve
 ITERATE retry_loop;
 ELSE
 LEAVE retry_loop;
 END IF;
 END LOOP;
END //
DELIMITER ;

-- S1: 
USE vet;
SET autocommit = 0;
START TRANSACTION;
UPDATE microchip 
SET observaciones = CONCAT('HOLD S1 ', NOW())
WHERE id = 262334;
68
-- S2: 
USE vet;
SET SESSION innodb_lock_wait_timeout = 3;
CALL sp_update_chip_retry(262334, 'demo');
SELECT * FROM tx_log ORDER BY id DESC LIMIT 10;

-- 3) Comparar niveles de aislamiento: READ COMMITTED vs REPEATABLE READ
READ COMMITTED – muestra “lectura no repetible”
sesión 1:
USE vet;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET autocommit = 0;
START TRANSACTION;
-- 1) Lectura inicial
SELECT veterinaria FROM microchip WHERE id = 262334; 

-- sesión 2:
USE vet;
SET autocommit = 0;
START TRANSACTION;
UPDATE microchip
SET veterinaria = 'Sede Tortuguitas'
69
WHERE id = 262334;
COMMIT;
-- Volvemos a sesión 1:
-- 2) Segunda lectura en la misma TX
SELECT veterinaria FROM microchip WHERE id = 262334; 
COMMIT;

--REPEATABLE READ
-- sesión 1: 
USE vet;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET autocommit = 0;
START TRANSACTION WITH CONSISTENT SNAPSHOT; 
SELECT veterinaria AS v1
FROM microchip
WHERE id = 262334; 

-- REPEATABLE READ
-- sesión 1: 
USE vet;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET autocommit = 0;
START TRANSACTION WITH CONSISTENT SNAPSHOT; 
SELECT veterinaria AS v1
FROM microchip
WHERE id = 262334; 

-- Sesión 2:
USE vet;
SET autocommit = 0;
START TRANSACTION;
UPDATE microchip
SET veterinaria = 'Sede Quilmes'
WHERE id = 262334;
COMMIT;
-- sesión 1:
SELECT veterinaria AS v2
FROM microchip
WHERE id = 262334;
COMMIT;
SELECT veterinaria AS v3
FROM microchip
WHERE id = 262334;
