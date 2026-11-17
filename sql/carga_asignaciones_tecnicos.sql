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
