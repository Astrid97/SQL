#################################################################################################

-- Se crea un procedimiento que mida los tiempos obtenidos al ejecutar ciertas porciones de código

-- En el PDF con la descripción de todo lo realizado se explica cuales fueron las consultas seleccionadas para 
-- analizar y cuales son los resultados obtenidosc (junto con una descripción de como deben leerse esos resultados)
-- Este Script se ejecuta por fuera de este archivo 

/* =========================
   0) CONTEXTO Y PREP
   ========================= */
-- Usá tu base acá:
-- USE tu_base;

-- (Opcional) refrescar estadísticas
ANALYZE TABLE mascota, microchip;

/* =========================
   1) ÍNDICES SUGERIDOS
   (si ya existen, podés saltar estos CREATE)
   ========================= */
-- MICROCHIP
CREATE INDEX idx_mc_fecha        ON microchip(fecha_implantacion);
CREATE INDEX idx_mc_veterinaria  ON microchip(veterinaria);
CREATE INDEX idx_mc_fecha_vet    ON microchip(fecha_implantacion, veterinaria);

-- MASCOTA
CREATE INDEX idx_m_especie       ON mascota(especie);
CREATE INDEX idx_m_microchip     ON mascota(microchip_id);
CREATE INDEX idx_m_fecha_nac     ON mascota(fecha_nacimiento);

/* =========================
   2) SP bench3: ejecuta 3 veces y devuelve mediana
   ========================= */
DELIMITER //
CREATE PROCEDURE bench3(IN q LONGTEXT, IN measure_full_result BOOL)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE t1, t2 DATETIME(6);
  DROP TEMPORARY TABLE IF EXISTS tmp_times;
  CREATE TEMPORARY TABLE tmp_times (run TINYINT, micros BIGINT);

  -- 3 corridas
  WHILE i <= 3 DO
    SET t1 = SYSDATE(6);

    IF measure_full_result THEN
      PREPARE s FROM q;
      EXECUTE s;
      DEALLOCATE PREPARE s;
    ELSE
      SET @qq = CONCAT('SELECT COUNT(*) FROM (', q, ') AS subq');
      PREPARE s FROM @qq;
      EXECUTE s;
      DEALLOCATE PREPARE s;
    END IF;

    SET t2 = SYSDATE(6);
    INSERT INTO tmp_times VALUES (i, TIMESTAMPDIFF(MICROSECOND, t1, t2));
    SET i = i + 1;
  END WHILE;

  -- 3 tiempos ordenados
  SELECT 'runs_sorted' AS section, run, micros, ROUND(micros/1000,2) AS ms
  FROM tmp_times ORDER BY micros;

  -- Mediana (2º de los 3)
  SELECT 'median' AS section, micros AS mediana_us, ROUND(micros/1000,2) AS mediana_ms
  FROM tmp_times ORDER BY micros LIMIT 1 OFFSET 1;
END//
DELIMITER ;

/* =========================
   3) Q1 - Agregación por mes/sede, últimos 6 meses
   ========================= */

-- Q1 BASE (calentamiento + medición + planes)
SET @q1_base := "
SELECT
  YEAR(mc.fecha_implantacion) AS año,
  MONTH(mc.fecha_implantacion) AS mes,
  mc.veterinaria AS sede,
  COUNT(*) AS perros_atendidos
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY año DESC, mes DESC, perros_atendidos DESC
";
-- Calentamiento
CALL bench3(@q1_base, FALSE);
-- Medición
CALL bench3(@q1_base, FALSE);
-- EXPLAIN (MariaDB)
EXPLAIN FORMAT=JSON
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

EXPLAIN
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

-- Q1 FORCE INDEX
SET @q1_force := "
SELECT
  YEAR(mc.fecha_implantacion) AS año,
  MONTH(mc.fecha_implantacion) AS mes,
  mc.veterinaria AS sede,
  COUNT(*) AS perros_atendidos
FROM mascota m FORCE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY año DESC, mes DESC, perros_atendidos DESC
";
CALL bench3(@q1_force, FALSE);
CALL bench3(@q1_force, FALSE);
EXPLAIN FORMAT=JSON
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m FORCE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

EXPLAIN
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m FORCE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

-- Q1 IGNORE INDEX (simula “sin índice” sin tocar DDL)
SET @q1_ignore := "
SELECT
  YEAR(mc.fecha_implantacion) AS año,
  MONTH(mc.fecha_implantacion) AS mes,
  mc.veterinaria AS sede,
  COUNT(*) AS perros_atendidos
FROM mascota m IGNORE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY año DESC, mes DESC, perros_atendidos DESC
";
CALL bench3(@q1_ignore, FALSE);
CALL bench3(@q1_ignore, FALSE);
EXPLAIN FORMAT=JSON
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m IGNORE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

EXPLAIN
SELECT YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria, COUNT(*)
FROM mascota m IGNORE INDEX (idx_m_especie, idx_m_microchip)
JOIN microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  ON m.microchip_id = mc.id
WHERE m.especie = 'Gatos'
  AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY YEAR(mc.fecha_implantacion) DESC, MONTH(mc.fecha_implantacion) DESC, COUNT(*) DESC;

/* =========================
   4) Q2 - DATEDIFF ~100 días + sede
   (versión reescrita con BETWEEN/DATE_ADD para usar índices)
   ========================= */

-- Q2 BASE (reescrita recomendada)
SET @q2_base := "
SELECT
  m.nombre AS mascota,
  m.especie,
  m.raza,
  m.fecha_nacimiento,
  mc.fecha_implantacion,
  mc.veterinaria,
  DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes'
";
CALL bench3(@q2_base, FALSE);
CALL bench3(@q2_base, FALSE);
EXPLAIN FORMAT=JSON
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

EXPLAIN
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

-- Q2 FORCE INDEX
SET @q2_force := "
SELECT
  m.nombre, m.especie, m.raza, m.fecha_nacimiento,
  mc.fecha_implantacion, mc.veterinaria,
  DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
JOIN microchip mc FORCE INDEX (idx_mc_veterinaria, idx_mc_fecha)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes'
";
CALL bench3(@q2_force, FALSE);
CALL bench3(@q2_force, FALSE);
EXPLAIN FORMAT=JSON
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
JOIN microchip mc FORCE INDEX (idx_mc_veterinaria, idx_mc_fecha)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

EXPLAIN
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
JOIN microchip mc FORCE INDEX (idx_mc_veterinaria, idx_mc_fecha)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

-- Q2 IGNORE INDEX
SET @q2_ignore := "
SELECT
  m.nombre, m.especie, m.raza, m.fecha_nacimiento,
  mc.fecha_implantacion, mc.veterinaria,
  DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
JOIN microchip mc IGNORE INDEX (idx_mc_veterinaria, idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes'
";
CALL bench3(@q2_ignore, FALSE);
CALL bench3(@q2_ignore, FALSE);
EXPLAIN FORMAT=JSON
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
JOIN microchip mc IGNORE INDEX (idx_mc_veterinaria, idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

EXPLAIN
SELECT m.nombre, m.especie, m.raza, m.fecha_nacimiento,
       mc.fecha_implantacion, mc.veterinaria,
       DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
JOIN microchip mc IGNORE INDEX (idx_mc_veterinaria, idx_mc_fecha, idx_mc_fecha_vet)
  ON m.microchip_id = mc.id
WHERE mc.fecha_implantacion BETWEEN DATE_ADD(m.fecha_nacimiento, INTERVAL 95 DAY)
                               AND DATE_ADD(m.fecha_nacimiento, INTERVAL 105 DAY)
  AND mc.veterinaria = 'Sede Quilmes';

/* =========================
   5) Q3 - Vista últimos 10 días, top-5 por día
   ========================= */

-- Crear/Recrear la vista (una sola vez)
DROP VIEW IF EXISTS v_mascotas_chips_10d_5reg;

CREATE VIEW v_mascotas_chips_10d_5reg AS
WITH base AS (
  SELECT
    mc.id,
    mc.codigo,
    mc.fecha_implantacion,
    mc.veterinaria,
    mc.observaciones,
    m.nombre AS mascota_nombre,
    m.especie,
    m.raza,
    m.fecha_nacimiento,
    m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (
      PARTITION BY mc.fecha_implantacion
      ORDER BY mc.id
    ) AS rn_por_dia
  FROM microchip mc
  JOIN mascota m ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT *
FROM base
WHERE rn_por_dia <= 5
ORDER BY fecha_implantacion DESC, id;

-- Q3 BASE (usando la vista)
SET @q3_base := "SELECT * FROM v_mascotas_chips_10d_5reg";
CALL bench3(@q3_base, FALSE);
CALL bench3(@q3_base, FALSE);
EXPLAIN FORMAT=JSON SELECT * FROM v_mascotas_chips_10d_5reg;
EXPLAIN               SELECT * FROM v_mascotas_chips_10d_5reg;

-- Q3 FORCE INDEX (inline con hints)
SET @q3_force := "
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  JOIN mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT *
FROM base
WHERE rn_por_dia <= 5
ORDER BY fecha_implantacion DESC, id
";
CALL bench3(@q3_force, FALSE);
CALL bench3(@q3_force, FALSE);
EXPLAIN FORMAT=JSON
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  JOIN mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT * FROM base WHERE rn_por_dia <= 5 ORDER BY fecha_implantacion DESC, id;

EXPLAIN
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc FORCE INDEX (idx_mc_fecha, idx_mc_fecha_vet)
  JOIN mascota m FORCE INDEX (idx_m_microchip, idx_m_fecha_nac)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT * FROM base WHERE rn_por_dia <= 5 ORDER BY fecha_implantacion DESC, id;

-- Q3 IGNORE INDEX (inline)
SET @q3_ignore := "
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  JOIN mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT *
FROM base
WHERE rn_por_dia <= 5
ORDER BY fecha_implantacion DESC, id
";
CALL bench3(@q3_ignore, FALSE);
CALL bench3(@q3_ignore, FALSE);
EXPLAIN FORMAT=JSON
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  JOIN mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT * FROM base WHERE rn_por_dia <= 5 ORDER BY fecha_implantacion DESC, id;

EXPLAIN
WITH base AS (
  SELECT
    mc.id, mc.codigo, mc.fecha_implantacion, mc.veterinaria, mc.observaciones,
    m.nombre AS mascota_nombre, m.especie, m.raza, m.fecha_nacimiento, m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion,
    ROW_NUMBER() OVER (PARTITION BY mc.fecha_implantacion ORDER BY mc.id) AS rn_por_dia
  FROM microchip mc IGNORE INDEX (idx_mc_fecha, idx_mc_fecha_vet, idx_mc_veterinaria)
  JOIN mascota m IGNORE INDEX (idx_m_microchip, idx_m_fecha_nac, idx_m_especie)
    ON mc.id = m.microchip_id
  WHERE mc.fecha_implantacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 10 DAY) AND CURDATE()
    AND m.fecha_nacimiento <= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
)
SELECT * FROM base WHERE rn_por_dia <= 5 ORDER BY fecha_implantacion DESC, id;

/* =========================
   6) FIN
   Para cada variante vas a ver:
   - tiempos (3 corridas) y la mediana,
   - EXPLAIN FORMAT=JSON,
   - EXPLAIN clásico.
   ========================= */
   
   
#############################################################################################################
-- Etapa para crear la tabla comaparativa de resultados de la mediana

CREATE TABLE IF NOT EXISTS bench_results (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  query_code VARCHAR(10) NOT NULL,     -- Q1, Q2, Q3
  variant ENUM('BASE','FORCE','IGNORE') NOT NULL,
  run1_us BIGINT, run2_us BIGINT, run3_us BIGINT,
  median_us BIGINT,
  measured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* =========
   2) SP bench3_save: mide y guarda (3 corridas + mediana)
   ========= */
DROP PROCEDURE IF EXISTS bench3_save;
DELIMITER //
CREATE PROCEDURE bench3_save(
  IN p_query_code VARCHAR(10),
  IN p_variant ENUM('BASE','FORCE','IGNORE'),
  IN q LONGTEXT,
  IN measure_full_result BOOL
)
BEGIN
  DECLARE t1, t2 DATETIME(6);
  DECLARE r1 BIGINT; 
  DECLARE r2 BIGINT; 
  DECLARE r3 BIGINT;
  DECLARE temp_query LONGTEXT;

  DROP TEMPORARY TABLE IF EXISTS tmp_times2;
  CREATE TEMPORARY TABLE tmp_times2 (run TINYINT, micros BIGINT);

  -- 3 corridas
  SET @sql_text := q;
  SET @wrapped_sql := CONCAT('SELECT COUNT(*) FROM (', @sql_text, ') AS subq');

  -- corrida 1
  SET t1 = SYSDATE(6);
  IF measure_full_result THEN
      PREPARE s1 FROM @sql_text;
  ELSE
      PREPARE s1 FROM @wrapped_sql;
  END IF;
  EXECUTE s1;
  DEALLOCATE PREPARE s1;
  SET t2 = SYSDATE(6);
  INSERT INTO tmp_times2 VALUES (1, TIMESTAMPDIFF(MICROSECOND,t1,t2));

  -- corrida 2
  SET t1 = SYSDATE(6);
  IF measure_full_result THEN
      PREPARE s2 FROM @sql_text;
  ELSE
      PREPARE s2 FROM @wrapped_sql;
  END IF;
  EXECUTE s2;
  DEALLOCATE PREPARE s2;
  SET t2 = SYSDATE(6);
  INSERT INTO tmp_times2 VALUES (2, TIMESTAMPDIFF(MICROSECOND,t1,t2));

  -- corrida 3
  SET t1 = SYSDATE(6);
  IF measure_full_result THEN
      PREPARE s3 FROM @sql_text;
  ELSE
      PREPARE s3 FROM @wrapped_sql;
  END IF;
  EXECUTE s3;
  DEALLOCATE PREPARE s3;
  SET t2 = SYSDATE(6);
  INSERT INTO tmp_times2 VALUES (3, TIMESTAMPDIFF(MICROSECOND,t1,t2));

  -- guardar resultado
  INSERT INTO bench_results(query_code,variant,run1_us,run2_us,run3_us,median_us)
  SELECT p_query_code, p_variant,
         (SELECT micros FROM tmp_times2 WHERE run=1),
         (SELECT micros FROM tmp_times2 WHERE run=2),
         (SELECT micros FROM tmp_times2 WHERE run=3),
         (SELECT micros FROM tmp_times2 ORDER BY micros LIMIT 1 OFFSET 1);
END//
DELIMITER ;


-- Q1
CALL bench3_save('Q1','BASE',  @q1_base,  FALSE);
CALL bench3_save('Q1','FORCE', @q1_force, FALSE);
CALL bench3_save('Q1','IGNORE',@q1_ignore,FALSE);

-- Q2
CALL bench3_save('Q2','BASE',  @q2_base,  FALSE);
CALL bench3_save('Q2','FORCE', @q2_force, FALSE);
CALL bench3_save('Q2','IGNORE',@q2_ignore,FALSE);

-- Q3
CALL bench3_save('Q3','BASE',  @q3_base,  FALSE);
CALL bench3_save('Q3','FORCE', @q3_force, FALSE);
CALL bench3_save('Q3','IGNORE',@q3_ignore,FALSE);


