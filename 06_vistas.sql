-- Ahora queremos realizar una vista que incluya los datos completos de las mascotas a las cuales 
-- se les haya implantado un microchip en los ultimos 10 días, junto con los datos del microchip correspondiente:

-- Como se aclaró en la Etapa 2, en la fecha actual se incluyen los chips efectivamente colocados en esta fecha y a su vez
-- los chips reservados para mascotas menores a 60 días (que no pueden ser implantados todavía).

-- Esta vista muestra a todas las mascotas implantadas en los últimos 10 días y a las mascotas con menos
-- de 60 días de vida que tienen reservados sus chips para ser implantados cuando se cumpla el requisito de
-- días mínimos:
CREATE VIEW v_mascotas_con_chips_10d_y_reservas AS
SELECT 
    mc.codigo,
    mc.fecha_implantacion,
    mc.veterinaria,
    mc.observaciones,
    m.nombre AS mascota_nombre,
    m.especie,
    m.raza,
    m.fecha_nacimiento,
    m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion
FROM microchip mc
JOIN mascota m ON mc.id = m.microchip_id
WHERE mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 10 DAY)
ORDER BY mc.fecha_implantacion DESC;


-- Para ver una mayor variedad de datos en la vista podemos incluir un filtro que limite la cantidad de registros por
-- fecha. En este caso optamos por delimitar que el tope sea de 5 registros. Además se incluyó un intervalo de análisis
-- que muestra sólo a mascotas con una edad superior a 60 días (por lo cual no se incluyen los chips reservados):

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


-- O también se podrían plantear rangos agrupando por meses para hacer proyecciones a nivel empresarial respecto a los chips
-- implantados o reservados:
CREATE VIEW v_mascotas_y_chips_ultimos_seis_meses AS
SELECT 
    mc.codigo,
    mc.fecha_implantacion,
    mc.veterinaria,
    mc.observaciones,
    m.nombre AS mascota_nombre,
    m.especie,
    m.raza,
    m.fecha_nacimiento,
    m.duenio,
    DATEDIFF(CURDATE(), mc.fecha_implantacion) AS dias_desde_implantacion
FROM microchip mc
JOIN mascota m ON mc.id = m.microchip_id
WHERE mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY mc.fecha_implantacion DESC;

-- Otro tipo de vista que podemos generar es una que asocie a los dueños de más de una mascotas con su inforamción:
-- (Como aclaramos antes, en este caso no se generaron dueños repetidos, por lo cual no se mostrarán resultados)

CREATE VIEW v_duenios_varias_mascotas AS
SELECT 
    duenio,
    COUNT(*) AS total_mascotas,
    GROUP_CONCAT(nombre SEPARATOR ', ') AS nombres_mascotas,
    GROUP_CONCAT(especie SEPARATOR ', ') AS especies
FROM mascota
GROUP BY duenio
HAVING COUNT(*) > 1
ORDER BY total_mascotas DESC, duenio;

-- Para ver la vista como fue generada, se puede correr esta línea:
SELECT * FROM v_duenios_varias_mascotas;

-- A su vez se podría determinar que se tengan en cuenta otros parámetros, por ejemplo que sólo se muestren
-- los dueños de más de 2 masotas:
SELECT * FROM v_duenios_varias_mascotas 
WHERE total_mascotas > 2;
