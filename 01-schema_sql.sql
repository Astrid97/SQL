-- 1) Esquema -> la creamos para organizar la estructura de nuestro modelo (bd)
CREATE SCHEMA IF NOT EXISTS vet DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vet;

-- 2) Tabla MICROCHIP (B) 
CREATE TABLE microchip (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  eliminado          TINYINT(1) NOT NULL DEFAULT 0,
  codigo             VARCHAR(25) NOT NULL UNIQUE,
  fecha_implantacion DATE NULL,
  veterinaria        VARCHAR(120) NULL,
  observaciones      VARCHAR(255) NULL,
  
  CONSTRAINT chk_microchip_eliminado
    CHECK (eliminado IN (0,1))
);

-- Creamos el trigger para verificar antes de insertar que la fecha que se recibe no sea futura
DELIMITER //
CREATE TRIGGER trg_check_fecha_implantacion
BEFORE INSERT ON microchip
FOR EACH ROW
BEGIN
  IF NEW.fecha_implantacion > CURDATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: La fecha de implantación no puede ser futura';
  END IF;
END;
//
DELIMITER ;




-- 3) Tabla MASCOTA (A)
CREATE TABLE mascota (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  eliminado          TINYINT(1) NOT NULL DEFAULT 0,
  nombre             VARCHAR(60)  NOT NULL,
  especie            VARCHAR(30)  NOT NULL,
  raza               VARCHAR(60)  NULL,
  fecha_nacimiento   DATE         NULL,
  duenio             VARCHAR(120) NOT NULL,
  microchip_id       BIGINT UNSIGNED NULL UNIQUE,  -- UNIQUE asegura el 1:1

  CONSTRAINT fk_mascota_microchip  -- Si se actualiza un id en microchip, se actualiza también en mascota
    FOREIGN KEY (microchip_id)
    REFERENCES microchip(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

DELIMITER //

CREATE TRIGGER trg_mascota_fecha_nac_bi -- antes de insertar
BEFORE INSERT ON mascota
FOR EACH ROW
BEGIN
  IF NEW.fecha_nacimiento IS NOT NULL
     AND NEW.fecha_nacimiento > CURDATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: La fecha de nacimiento no puede ser futura';
  END IF;
END;
//

CREATE TRIGGER trg_mascota_fecha_nac_bu -- antes de actualizar 
BEFORE UPDATE ON mascota
FOR EACH ROW
BEGIN
  IF NEW.fecha_nacimiento IS NOT NULL
     AND NEW.fecha_nacimiento > CURDATE() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: La fecha de nacimiento no puede ser futura';
  END IF;
END;
//

DELIMITER ;