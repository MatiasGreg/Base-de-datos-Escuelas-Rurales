USE bd_escuelas_rurales;

-- Restricciones
-- Estos inserts deben fallar y se esperan manualmente con --force.
INSERT INTO SEDE_EDUCATIVA (id_municipio, nombre_sede, zona)
VALUES (1, 'Prueba CHECK zona', 'Urbana');

INSERT INTO CONEXION (
    id_sede, id_proveedor, tipo_servicio, velocidad_mbps,
    vigencia_inicio, vigencia_fin
)
VALUES (1, 1, 'Cable', 0, '2026-01-01', NULL);

INSERT INTO MEDICION_USO (id_conexion, fecha_medicion, horas_servicio_activo)
VALUES (1, '2026-11-30', 800);

-- Funciones
SELECT fn_horas_reparacion((SELECT MIN(id_incidencia) FROM INCIDENCIA)) AS horas_reparacion;
SELECT fn_disponibilidad_pct(1, 2025, 10) AS disponibilidad_pct;

-- Procedimientos
SET @id_sede = 1;
SET @id_conexion = (SELECT MIN(id_conexion) FROM CONEXION WHERE id_sede = 1);
SET @codigo = (SELECT MIN(codigo_inventario) FROM DISPOSITIVO WHERE id_sede = 1);
CALL sp_registrar_incidencia(
    @id_sede,
    @id_conexion,
    @codigo,
    'Prueba automatizada',
    NULL,
    1,
    'Intermitente',
    @id_incidencia
);
SELECT @id_incidencia AS id_incidencia_creada;

CALL sp_cerrar_incidencia(
    @id_incidencia,
    DATE_ADD(NOW(), INTERVAL 90 MINUTE),
    'Activo',
    @horas
);
SELECT @horas AS horas_reparacion;

-- Inmutabilidad del historial
-- Debe devolver error 1644.
UPDATE HISTORIAL_ESTADO_CONEXION
SET estado_actual = 'Activo'
WHERE id_historial = 1;
