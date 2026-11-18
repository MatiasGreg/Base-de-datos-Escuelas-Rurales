USE bd_escuelas_rurales;

DROP TEMPORARY TABLE IF EXISTS tmp_numeros;
CREATE TEMPORARY TABLE tmp_numeros (
    n INT PRIMARY KEY
);

INSERT INTO tmp_numeros (n) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
(41),(42),(43),(44),(45),(46),(47),(48),(49),(50);

INSERT INTO MUNICIPIO (nombre_municipio)
SELECT CONCAT('Municipio Rural ', LPAD(n, 2, '0'))
FROM tmp_numeros;

INSERT INTO PROVEEDOR (nombre_proveedor)
SELECT CONCAT('Proveedor Rural ', LPAD(n, 2, '0'))
FROM tmp_numeros;

INSERT INTO RESPONSABLE (descripcion_cargo)
SELECT CONCAT('Dependencia TIC Rural ', LPAD(n, 2, '0'))
FROM tmp_numeros;

INSERT INTO TECNICO (codigo_tecnico, especialidad)
SELECT CONCAT('TEC-', LPAD(n, 3, '0')),
       ELT(1 + MOD(n - 1, 5), 'Redes', 'Hardware', 'Energia', 'Satelital', 'Soporte general')
FROM tmp_numeros;

INSERT INTO SEDE_EDUCATIVA (id_municipio, nombre_sede, zona)
SELECT id_municipio,
       CONCAT('I.E.D. Rural Nueva Esperanza Sede ', LPAD(id_municipio, 2, '0')),
       IF(MOD(id_municipio, 5) = 0, 'Palafito', 'Rural')
FROM MUNICIPIO
ORDER BY id_municipio;

INSERT INTO CONEXION (
    id_sede, id_proveedor, tipo_servicio, velocidad_mbps,
    vigencia_inicio, vigencia_fin
)
SELECT s.id_sede,
       1 + MOD(s.id_sede - 1, 50),
       ELT(1 + MOD(s.id_sede - 1, 4), 'Satelital', 'Fibra', 'Radioenlace', 'Movil'),
       10 + (MOD(s.id_sede - 1, 10) * 10),
       DATE_ADD('2023-01-15', INTERVAL MOD(s.id_sede - 1, 12) MONTH),
       NULL
FROM SEDE_EDUCATIVA s
ORDER BY s.id_sede;

INSERT INTO HISTORIAL_ESTADO_CONEXION (
    id_conexion, fecha_hora_registro, estado_actual, observaciones
)
SELECT c.id_conexion,
       DATE_ADD('2025-01-01 08:00:00', INTERVAL c.id_conexion DAY),
       ELT(1 + MOD(c.id_conexion - 1, 3), 'Activo', 'Intermitente', 'Caído'),
       CONCAT('Registro inicial de estado para la conexión ', c.id_conexion)
FROM CONEXION c
ORDER BY c.id_conexion;

INSERT INTO DISPOSITIVO (
    codigo_inventario, id_sede, id_responsable,
    tipo_dispositivo, fecha_entrega, estado_fisico
)
SELECT CONCAT('INV-MINTIC-2024-', LPAD(s.id_sede, 3, '0')),
       s.id_sede,
       1 + MOD(s.id_sede - 1, 50),
       ELT(1 + MOD(s.id_sede - 1, 4),
           'Computador Portátil', 'Router Inalámbrico', 'Antena Satelital', 'Tablet'),
       DATE_ADD('2024-02-10', INTERVAL MOD(s.id_sede - 1, 30) DAY),
       ELT(1 + MOD(s.id_sede - 1, 3), 'Bueno', 'Regular', 'Dañado')
FROM SEDE_EDUCATIVA s
ORDER BY s.id_sede;

INSERT INTO INCIDENCIA (
    id_sede, id_conexion, codigo_inventario,
    descripcion_falla, fecha_inicio, fecha_cierre
)
SELECT s.id_sede,
       c.id_conexion,
       d.codigo_inventario,
       ELT(1 + MOD(s.id_sede - 1, 5),
           'Mantenimiento preventivo',
           'Fallo de configuración IP',
           'Caída del enlace satelital',
           'Fallo de alimentación eléctrica',
           'Intermitencia del servicio'),
       DATE_ADD('2025-01-01 08:00:00', INTERVAL s.id_sede DAY),
       IF(MOD(s.id_sede, 2) = 0,
          DATE_ADD('2025-01-01 08:00:00', INTERVAL s.id_sede + 3 DAY),
          NULL)
FROM SEDE_EDUCATIVA s
JOIN CONEXION c ON c.id_sede = s.id_sede
JOIN DISPOSITIVO d ON d.id_sede = s.id_sede
ORDER BY s.id_sede;

INSERT INTO MEDICION_USO (
    id_conexion, fecha_medicion, horas_servicio_activo
)
SELECT c.id_conexion,
       DATE_ADD('2025-01-01', INTERVAL MOD(c.id_conexion - 1, 12) MONTH),
       500.00 + (MOD(c.id_conexion - 1, 25) * 10)
FROM CONEXION c
ORDER BY c.id_conexion;

INSERT INTO INCIDENCIA_TECNICO (
    id_incidencia, id_tecnico, rol_asignado, fecha_asignacion
)
SELECT i.id_incidencia,
       1 + MOD(i.id_incidencia - 1, 50),
       IF(MOD(i.id_incidencia, 2) = 0, 'Apoyo', 'Principal'),
       i.fecha_inicio
FROM INCIDENCIA i
ORDER BY i.id_incidencia;

INSERT INTO AUDITORIA_DISPOSITIVO (
    codigo_inventario, estado_anterior, estado_nuevo,
    id_responsable_anterior, id_responsable_nuevo,
    usuario, origen
)
SELECT codigo_inventario, NULL, estado_fisico, NULL, id_responsable,
       'sistema', 'Carga inicial'
FROM DISPOSITIVO
ORDER BY codigo_inventario;

DROP TEMPORARY TABLE tmp_numeros;
USE bd_escuelas_rurales;

INSERT INTO INCIDENCIA (
    id_sede, id_conexion, codigo_inventario,
    descripcion_falla, fecha_inicio, fecha_cierre
)
SELECT
    s.id_sede,
    c.id_conexion,
    d.codigo_inventario,
    CASE s.id_sede % 5
        WHEN 0 THEN 'Mantenimiento preventivo'
        WHEN 1 THEN 'Router quemado por tormenta eléctrica'
        WHEN 2 THEN 'Fallo de configuración IP'
        WHEN 3 THEN 'Robo de cableado'
        ELSE 'Caída del enlace satelital'
    END,
    TIMESTAMP('2025-01-01', CONCAT(LPAD((s.id_sede % 23), 2, '0'), ':00:00')),
    NULL
FROM SEDE_EDUCATIVA s
JOIN CONEXION c ON c.id_sede = s.id_sede
JOIN DISPOSITIVO d ON d.id_sede = s.id_sede
WHERE s.id_sede <= 10;

INSERT INTO INCIDENCIA_TECNICO (
    id_incidencia, id_tecnico, rol_asignado, fecha_asignacion
)
SELECT
    i.id_incidencia,
    ((i.id_incidencia - 1) % 10) + 1,
    'Principal',
    i.fecha_inicio
FROM INCIDENCIA i
WHERE NOT EXISTS (
    SELECT 1
    FROM INCIDENCIA_TECNICO it
    WHERE it.id_incidencia = i.id_incidencia
);
