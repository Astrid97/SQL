-- Etapa 3: Consultas avanzadas y reportes
use vet;

-- ####################################################################################################################
-- Primero hacemos una consulta relativamente simple para analizar cómo funciona la base de datos
-- Buscamos identificar la cantidad de perros atendidos en el último año

SELECT COUNT(*) AS perros_ultimo_ano
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE m.especie = 'Perros'
AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

-- Ahora queremos un reporte más detallado, en el que podamos identificar en qué sede se atendió qué cantidad de perros:

SELECT 
    mc.veterinaria AS sede,
    COUNT(*) AS perros_atendidos
FROM mascota m
JOIN microchip mc ON m.microchip_id = mc.id
WHERE m.especie = 'Perros'
AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY mc.veterinaria
ORDER BY perros_atendidos DESC;

-- Podríamos pedir un informe con la cantidad de gatos que fueron atendidos en una sede específica en el último año:

SELECT
    YEAR(mc.fecha_implantacion) AS año,
    MONTH(mc.fecha_implantacion) AS mes,
    mc.veterinaria AS sede,
    COUNT(*) AS gatos_atendidos
FROM
    mascota m
    JOIN microchip mc ON m.microchip_id = mc.id
WHERE
    m.especie = 'Gatos'
    AND mc.veterinaria = 'Sede Quilmes' 
    AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY YEAR(mc.fecha_implantacion), MONTH(mc.fecha_implantacion), mc.veterinaria
ORDER BY año DESC, mes DESC;

-- Si quisieramos identificar cuál fue la cantidad de gatos atendida por cada sede, en los últimos 6 meses:

SELECT 
    YEAR(mc.fecha_implantacion) AS año,
    MONTH(mc.fecha_implantacion) AS mes,
    mc.veterinaria AS sede,
    COUNT(*) AS gatos_atendidos
FROM
    mascota m
        JOIN
    microchip mc ON m.microchip_id = mc.id
WHERE
    m.especie = 'Gatos'
        AND mc.fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY YEAR(mc.fecha_implantacion) , MONTH(mc.fecha_implantacion) , mc.veterinaria
ORDER BY año DESC , mes DESC , gatos_atendidos DESC;

-- ####################################################################################################################

-- Consultas un poco más avanzadas:

-- (Recordamos que previamente se designó que la implantación se puede realizar desde los 60 días de vida del animal
-- hasta los 259 días)
-- Queremos identificar cuales son las mascotas a las cuáles se les implantó el chip cuando tenían exactamente 100 días

SELECT 
    m.nombre AS mascota,
    m.especie,
    m.raza,
	m.fecha_nacimiento,
    mc.fecha_implantacion,
    DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc 
ON m.microchip_id = mc.id
WHERE 
    DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) = 100;   
    
-- Queremos lo mismo pero en una sede especpifica, en este caso Tortuguitas:
SELECT 
    m.nombre AS mascota,
    m.especie,
    m.raza,
	m.fecha_nacimiento,
    mc.fecha_implantacion,
    mc.veterinaria AS sede,
    DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc 
ON m.microchip_id = mc.id
WHERE
	mc.veterinaria = 'Sede Tortuguitas'
    AND DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) = 100;

-- Si quisieramos filtrar por rango de días podríamos hacerlo más complejo (sirve para casos 
-- como la Sede Quilmes que no tiene resultados para búsqueda anterior):
SELECT 
    m.nombre AS mascota,
    m.especie,
    m.raza,
	m.fecha_nacimiento,
    mc.fecha_implantacion,
    mc.veterinaria,
    DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc 
ON m.microchip_id = mc.id
WHERE DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) BETWEEN 95 AND 105
	AND mc.veterinaria = 'Sede Quilmes';

-- Si quisieramos filtrar por rango de días pero solo viendo a los gatos en otra sede:
  SELECT 
    m.nombre AS mascota,
    m.especie,
    m.raza,
	m.fecha_nacimiento,
    mc.fecha_implantacion,
    mc.veterinaria,
    DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) AS dias_diferencia
FROM mascota m
JOIN microchip mc 
ON m.microchip_id = mc.id
WHERE DATEDIFF(mc.fecha_implantacion, m.fecha_nacimiento) BETWEEN 90 AND 125
	AND mc.veterinaria = 'Sede Coghlan'
    AND m.especie = 'Gatos';
    
-- Además, se puede analizar cuantos dueños tienen más de una mascota (lo cual podría ser útil para evaluar
-- la reincidencia y eventualmente ofrecer planes personalizados, descuentos, etc):
-- (En este caso se mostrará un conjunto vacío porque en la Etapa 2 se estableció que no se repitan los dueños)

SELECT 
    duenio,
    COUNT(*) AS mascotas
FROM mascota
GROUP BY duenio
HAVING COUNT(*) > 1
ORDER BY mascotas DESC;
    
    
-- Podemos analizar con qué frecuencia se utiliza una letra (o conjunto de letras) como inicial
-- de los nombres de las mascotas:

-- Podemos ver cuantos nombres inician con 'A'
SELECT 
    UPPER(LEFT(nombre, 1)) AS letra_inicial,
    COUNT(*) AS total_mascotas
FROM mascota
GROUP BY letra_inicial
HAVING letra_inicial LIKE 'A%';

-- Podemos ver cuantos nombres empiezan con 'B', 'C' y 'D':

SELECT
    UPPER(LEFT(nombre, 1)) AS letra_inicial,
    COUNT(*) AS total_mascotas
FROM mascota
GROUP BY letra_inicial
HAVING letra_inicial LIKE 'B%' OR letra_inicial LIKE 'C%' OR letra_inicial LIKE 'D%';

-- ######################################################################################################

-- A modo demostrativo podemos hacer una subconsulta sencilla para identificar a las mascotas que tienen
--  microchip implantado o tienen reservado el suyo (que en este caso serán todas):

SELECT 
    nombre,
    especie,
    raza
FROM mascota
WHERE microchip_id IN (
    SELECT id 
    FROM microchip
);

-- Podríamos hacer una consulta un poco más compleja en la que evaluamos cuales fueron los microchips
-- implantados en los últimos 10 días:

SELECT 
    codigo,
    fecha_implantacion,
    veterinaria
FROM microchip
WHERE fecha_implantacion IN (
    SELECT fecha_implantacion
    FROM microchip
    WHERE fecha_implantacion >= DATE_SUB(CURDATE(), INTERVAL 10 DAY)
);

