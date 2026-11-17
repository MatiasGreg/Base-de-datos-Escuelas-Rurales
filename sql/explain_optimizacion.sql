USE bd_escuelas_rurales;

EXPLAIN SELECT id_incidencia, id_sede, fecha_inicio
FROM INCIDENCIA
WHERE fecha_inicio >= '2025-01-01'
  AND fecha_inicio < '2025-02-01';

CREATE INDEX IF NOT EXISTS idx_incidencia_fecha_inicio
ON INCIDENCIA(fecha_inicio);

CREATE INDEX IF NOT EXISTS idx_incidencia_fecha_cierre
ON INCIDENCIA(fecha_cierre);

CREATE INDEX IF NOT EXISTS idx_historial_conexion_fecha
ON HISTORIAL_ESTADO_CONEXION(id_conexion, fecha_hora_registro);

EXPLAIN SELECT id_incidencia, id_sede, fecha_inicio
FROM INCIDENCIA
WHERE fecha_inicio >= '2025-01-01'
  AND fecha_inicio < '2025-02-01';

EXPLAIN SELECT id_incidencia, id_sede
FROM INCIDENCIA
WHERE fecha_cierre IS NULL;

EXPLAIN SELECT estado_actual
FROM HISTORIAL_ESTADO_CONEXION
WHERE id_conexion = 1
ORDER BY fecha_hora_registro DESC, id_historial DESC
LIMIT 1;
