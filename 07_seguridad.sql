use vet;

-- 1) Privilegios
-- Usuario de solo lectura sobre las tablas principales
DROP USER IF EXISTS 'vet_read'@'localhost';
CREATE USER 'vet_read'@'localhost' IDENTIFIED BY 'VetRead2025!';
GRANT SELECT ON vet.* TO 'vet_read'@'localhost';

-- Usuario que puede insertar mascotas
DROP USER IF EXISTS 'vet_writer'@'localhost';
CREATE USER 'vet_writer'@'localhost' IDENTIFIED BY 'VetWrite2025!';
GRANT SELECT, INSERT ON vet.mascota TO 'vet_writer'@'localhost';

-- Usuario administrador para mantenimiento
DROP USER IF EXISTS 'vet_admin'@'localhost';
CREATE USER 'vet_admin'@'localhost' IDENTIFIED BY 'VetAdmin2025!';
GRANT ALL PRIVILEGES ON vet.* TO 'vet_admin'@'localhost';

-- VER USUARIOS Y SUS PERMISOS
SELECT user, host 
FROM mysql.user 
WHERE user IN ('vet_read', 'vet_writer', 'vet_admin');

SHOW GRANTS FOR 'vet_read'@'localhost';
SHOW GRANTS FOR 'vet_writer'@'localhost';
SHOW GRANTS FOR 'vet_admin'@'localhost';

-- 2) Vistas
-- Vista de mascotas sin datos del dueño
CREATE VIEW v_mascota_segura AS
SELECT 
    id,
    nombre AS nombre_mascota,
    especie,
    raza,
    fecha_nacimiento
FROM mascota;

-- Microchip sin codigo completo
CREATE VIEW v_microchip_segura AS
SELECT 
    id,
    CONCAT(LEFT(codigo, 5), '****') AS codigo_oculto,
    fecha_implantacion,
    veterinaria
FROM microchip;

-- RESULTADOS MASCOTA VS VISTAS
SELECT * FROM mascota;
SELECT * FROM v_mascota_segura;
SELECT * FROM v_microchip_segura;

SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 3) Pruebas de integridad
-- Intentar insertar una raza con especie inexistente (debe fallar)
INSERT INTO raza (especie_id, nombre) VALUES (999, 'RazaFantasma');
-- Resultado esperado: ERROR 1452: Cannot add or update a child row: a foreign key constraint fails

-- Intentar insertar un microchip duplicado
INSERT INTO microchip (eliminado, codigo, fecha_implantacion, veterinaria) 
VALUES (0, 'CHIP-CAAT1-000001', CURDATE(), 'Sede Quilmes');
-- Resultado esperado: ERROR 1062: Duplicate entry 'CHIP-CAAT1-000001' for key 'codigo'

-- 4) Implementacion de consulta parametrizada segura sql con procedimiento almacenado sin sql dinamico
DROP PROCEDURE IF EXISTS sp_get_mascota_por_nombre;
DELIMITER $$

CREATE PROCEDURE sp_get_mascota_por_nombre(IN p_nombre VARCHAR(40))
BEGIN
    SELECT id, nombre, especie, raza
    FROM mascota
    WHERE nombre = p_nombre;
END$$

DELIMITER ;

-- EJECUCIÓN SEGURA
CALL sp_get_mascota_por_nombre("Candy' OR '1'='1");

