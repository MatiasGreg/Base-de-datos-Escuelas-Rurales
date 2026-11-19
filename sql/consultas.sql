-- CONSULTAS DE OPERACION Y REPORTES
-- Base de datos: bd_escuelas_rurales
-- Compatible con MariaDB 10.4+ y MySQL 8+.

USE bd_escuelas_rurales;

-- 1. Sedes sin conexión vigente o con servicio caído en una fecha.
SET @fecha_consulta = '2025-12-31 23:59:59';
SELECT s.id_sede, m.nombre_municipio AS municipio, s.nombre_sede, s.zona,
       CASE
           WHEN c.id_conexion IS NULL THEN 'Sin conexión vigente'
           WHEN h.estado_actual = 'Caído' THEN 'Servicio caído'
           ELSE 'Con conexión'
       END AS situacion
FROM SEDE_EDUCATIVA s
JOIN MUNICIPIO m ON m.id_municipio = s.id_municipio
LEFT JOIN CONEXION c
  ON c.id_sede = s.id_sede
 AND c.vigencia_inicio <= DATE(@fecha_consulta)
 AND (c.vigencia_fin IS NULL OR c.vigencia_fin >= DATE(@fecha_consulta))
LEFT JOIN HISTORIAL_ESTADO_CONEXION h
  ON h.id_historial = (
      SELECT h2.id_historial
      FROM HISTORIAL_ESTADO_CONEXION h2
      WHERE h2.id_conexion = c.id_conexion
        AND h2.fecha_hora_registro <= @fecha_consulta
      ORDER BY h2.fecha_hora_registro DESC, h2.id_historial DESC
      LIMIT 1
  )
WHERE c.id_conexion IS NULL OR h.estado_actual = 'Caído'
ORDER BY municipio, s.nombre_sede;

-- 2. Último estado conocido de cada conexión a una fecha.
SET @fecha_estado = '2025-12-31 23:59:59';
SELECT c.id_conexion, s.nombre_sede, p.nombre_proveedor,
       h.estado_actual, h.fecha_hora_registro
FROM CONEXION c
JOIN SEDE_EDUCATIVA s ON s.id_sede = c.id_sede
JOIN PROVEEDOR p ON p.id_proveedor = c.id_proveedor
LEFT JOIN HISTORIAL_ESTADO_CONEXION h
  ON h.id_historial = (
      SELECT h2.id_historial
      FROM HISTORIAL_ESTADO_CONEXION h2
      WHERE h2.id_conexion = c.id_conexion
        AND h2.fecha_hora_registro <= @fecha_estado
      ORDER BY h2.fecha_hora_registro DESC, h2.id_historial DESC
      LIMIT 1
  )
WHERE c.vigencia_inicio <= DATE(@fecha_estado)
  AND (c.vigencia_fin IS NULL OR c.vigencia_fin >= DATE(@fecha_estado))
ORDER BY s.nombre_sede, c.id_conexion;

-- 3. Cobertura por municipio.
SELECT cobertura.municipio,
       cobertura.total_sedes,
       cobertura.sedes_con_conexion,
       cobertura.cobertura_pct
FROM (
    SELECT m.nombre_municipio AS municipio,
           COUNT(DISTINCT s.id_sede) AS total_sedes,
           COUNT(DISTINCT CASE WHEN c.id_conexion IS NOT NULL THEN s.id_sede END)
               AS sedes_con_conexion,
           ROUND(
               100 * COUNT(DISTINCT CASE WHEN c.id_conexion IS NOT NULL THEN s.id_sede END)
               / NULLIF(COUNT(DISTINCT s.id_sede), 0), 2
           ) AS cobertura_pct
    FROM MUNICIPIO m
    LEFT JOIN SEDE_EDUCATIVA s ON s.id_municipio = m.id_municipio
    LEFT JOIN CONEXION c ON c.id_sede = s.id_sede
    GROUP BY m.id_municipio, m.nombre_municipio
) cobertura
ORDER BY cobertura.cobertura_pct ASC, cobertura.municipio ASC;

-- 4. Cantidad y antigüedad promedio de dispositivos por sede.
SELECT s.id_sede, m.nombre_municipio AS municipio, s.nombre_sede,
       COUNT(d.codigo_inventario) AS total_equipos,
       ROUND(AVG(TIMESTAMPDIFF(MONTH, d.fecha_entrega, CURDATE()) / 12), 2)
           AS antiguedad_promedio_anios
FROM SEDE_EDUCATIVA s
JOIN MUNICIPIO m ON m.id_municipio = s.id_municipio
LEFT JOIN DISPOSITIVO d ON d.id_sede = s.id_sede
GROUP BY s.id_sede, m.nombre_municipio, s.nombre_sede
ORDER BY antiguedad_promedio_anios DESC;

-- 5. Equipos por estado físico.
SELECT estado_fisico, COUNT(*) AS total_equipos
FROM DISPOSITIVO
GROUP BY estado_fisico
ORDER BY total_equipos DESC, estado_fisico;

-- 6. Tiempo promedio de reparación por sede.
SELECT s.id_sede, s.nombre_sede,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, i.fecha_inicio, i.fecha_cierre) / 60), 2)
           AS horas_reparacion_promedio,
       COUNT(i.id_incidencia) AS incidencias_cerradas
FROM SEDE_EDUCATIVA s
JOIN INCIDENCIA i ON i.id_sede = s.id_sede
WHERE i.fecha_cierre IS NOT NULL
GROUP BY s.id_sede, s.nombre_sede
ORDER BY horas_reparacion_promedio DESC;

-- 7. Tiempo promedio de reparación por proveedor.
SELECT p.id_proveedor, p.nombre_proveedor,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, i.fecha_inicio, i.fecha_cierre) / 60), 2)
           AS horas_reparacion_promedio,
       COUNT(i.id_incidencia) AS incidencias_cerradas
FROM PROVEEDOR p
JOIN CONEXION c ON c.id_proveedor = p.id_proveedor
JOIN INCIDENCIA i ON i.id_conexion = c.id_conexion
WHERE i.fecha_cierre IS NOT NULL
GROUP BY p.id_proveedor, p.nombre_proveedor
ORDER BY horas_reparacion_promedio DESC;

-- 8. Incidencias abiertas y su antigüedad.
SELECT i.id_incidencia, s.nombre_sede, i.descripcion_falla,
       i.fecha_inicio,
       TIMESTAMPDIFF(HOUR, i.fecha_inicio, NOW()) AS horas_abierta
FROM INCIDENCIA i
JOIN SEDE_EDUCATIVA s ON s.id_sede = i.id_sede
WHERE i.fecha_cierre IS NULL
ORDER BY i.fecha_inicio;

-- 9. Disponibilidad mensual por conexión a partir de mediciones.
SELECT c.id_conexion, s.nombre_sede,
       DATE_FORMAT(mu.fecha_medicion, '%Y-%m') AS mes,
       ROUND(AVG(mu.horas_servicio_activo), 2) AS horas_activas_promedio,
       ROUND(AVG(mu.horas_servicio_activo) / 744 * 100, 2)
           AS disponibilidad_promedio_pct
FROM MEDICION_USO mu
JOIN CONEXION c ON c.id_conexion = mu.id_conexion
JOIN SEDE_EDUCATIVA s ON s.id_sede = c.id_sede
GROUP BY c.id_conexion, s.nombre_sede, DATE_FORMAT(mu.fecha_medicion, '%Y-%m')
ORDER BY mes, s.nombre_sede;

-- 10. Conexiones por proveedor y tipo de servicio.
SELECT p.nombre_proveedor, c.tipo_servicio,
       COUNT(*) AS total_conexiones,
       ROUND(AVG(c.velocidad_mbps), 2) AS velocidad_promedio_mbps
FROM CONEXION c
JOIN PROVEEDOR p ON p.id_proveedor = c.id_proveedor
GROUP BY p.id_proveedor, p.nombre_proveedor, c.tipo_servicio
ORDER BY p.nombre_proveedor, total_conexiones DESC;

-- 11. Conexiones vencidas o próximas a vencer.
SET @dias_alerta = 90;
SELECT c.id_conexion, s.nombre_sede, p.nombre_proveedor,
       c.vigencia_inicio, c.vigencia_fin,
       DATEDIFF(c.vigencia_fin, CURDATE()) AS dias_para_vencer
FROM CONEXION c
JOIN SEDE_EDUCATIVA s ON s.id_sede = c.id_sede
JOIN PROVEEDOR p ON p.id_proveedor = c.id_proveedor
WHERE c.vigencia_fin IS NOT NULL
  AND c.vigencia_fin <= DATE_ADD(CURDATE(), INTERVAL @dias_alerta DAY)
ORDER BY c.vigencia_fin;

-- 12. Sedes con más de una conexión registrada.
SELECT s.id_sede, s.nombre_sede, COUNT(c.id_conexion) AS conexiones
FROM SEDE_EDUCATIVA s
JOIN CONEXION c ON c.id_sede = s.id_sede
GROUP BY s.id_sede, s.nombre_sede
HAVING COUNT(c.id_conexion) > 1
ORDER BY conexiones DESC, s.nombre_sede;

-- 13. Dispositivos sin cambios de auditoría posteriores a su entrega.
SELECT d.codigo_inventario, s.nombre_sede, d.fecha_entrega, d.estado_fisico
FROM DISPOSITIVO d
JOIN SEDE_EDUCATIVA s ON s.id_sede = d.id_sede
LEFT JOIN AUDITORIA_DISPOSITIVO a
  ON a.codigo_inventario = d.codigo_inventario
 AND a.fecha_cambio > d.fecha_entrega
WHERE a.id_auditoria IS NULL
ORDER BY d.fecha_entrega;

-- 14. Carga de trabajo por técnico.
SELECT t.codigo_tecnico, t.especialidad, t.activo,
       COUNT(it.id_incidencia) AS incidencias_asignadas,
       SUM(CASE WHEN it.rol_asignado = 'Principal' THEN 1 ELSE 0 END)
           AS incidencias_principales
FROM TECNICO t
LEFT JOIN INCIDENCIA_TECNICO it ON it.id_tecnico = t.id_tecnico
GROUP BY t.id_tecnico, t.codigo_tecnico, t.especialidad, t.activo
ORDER BY incidencias_asignadas DESC, t.codigo_tecnico;

-- 15. Historial completo de una conexión.
SET @id_conexion = 1;
SELECT h.id_historial, h.fecha_hora_registro, h.estado_actual,
       h.observaciones
FROM HISTORIAL_ESTADO_CONEXION h
WHERE h.id_conexion = @id_conexion
ORDER BY h.fecha_hora_registro, h.id_historial;

-- 16. Municipios con menor cobertura que el promedio.
SELECT cobertura.municipio, cobertura.cobertura_pct
FROM (
    SELECT m.nombre_municipio AS municipio,
           100 * COUNT(DISTINCT CASE WHEN c.id_conexion IS NOT NULL THEN s.id_sede END)
             / NULLIF(COUNT(DISTINCT s.id_sede), 0) AS cobertura_pct
    FROM MUNICIPIO m
    LEFT JOIN SEDE_EDUCATIVA s ON s.id_municipio = m.id_municipio
    LEFT JOIN CONEXION c ON c.id_sede = s.id_sede
    GROUP BY m.id_municipio, m.nombre_municipio
) cobertura
WHERE cobertura.cobertura_pct < (
    SELECT AVG(cobertura2.cobertura_pct)
    FROM (
        SELECT 100 * COUNT(DISTINCT CASE WHEN c2.id_conexion IS NOT NULL THEN s2.id_sede END)
                 / NULLIF(COUNT(DISTINCT s2.id_sede), 0) AS cobertura_pct
        FROM MUNICIPIO m2
        LEFT JOIN SEDE_EDUCATIVA s2 ON s2.id_municipio = m2.id_municipio
        LEFT JOIN CONEXION c2 ON c2.id_sede = s2.id_sede
        GROUP BY m2.id_municipio
    ) cobertura2
)
ORDER BY cobertura.cobertura_pct;

-- 17. Conexiones sin mediciones de uso.
SELECT c.id_conexion, s.nombre_sede, p.nombre_proveedor
FROM CONEXION c
JOIN SEDE_EDUCATIVA s ON s.id_sede = c.id_sede
JOIN PROVEEDOR p ON p.id_proveedor = c.id_proveedor
LEFT JOIN MEDICION_USO mu ON mu.id_conexion = c.id_conexion
WHERE mu.id_medicion IS NULL
ORDER BY s.nombre_sede, c.id_conexion;

-- 18. Incidencias que no tienen conexión ni dispositivo asociado.
SELECT i.id_incidencia, s.nombre_sede, i.descripcion_falla, i.fecha_inicio
FROM INCIDENCIA i
JOIN SEDE_EDUCATIVA s ON s.id_sede = i.id_sede
WHERE i.id_conexion IS NULL
  AND i.codigo_inventario IS NULL
ORDER BY i.fecha_inicio;
