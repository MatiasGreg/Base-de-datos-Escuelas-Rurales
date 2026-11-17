-- ==============================================================================
-- VISTAS - FASE 4
-- Base de datos: bd_escuelas_rurales
-- Compatible con MariaDB 10.4+.
-- Las agregaciones separadas evitan multiplicar dispositivos, incidencias,
-- mediciones y conexiones al hacer los JOIN.
-- ==============================================================================

USE bd_escuelas_rurales;

DROP VIEW IF EXISTS vw_resumen_general_sedes;
DROP VIEW IF EXISTS vw_tendencia_mensual_conectividad;
DROP VIEW IF EXISTS vw_analisis_dimension_geografica_proveedor;

-- RESUMEN POR SEDE
CREATE VIEW vw_resumen_general_sedes AS
SELECT
    s.id_sede,
    m.nombre_municipio AS municipio,
    s.nombre_sede AS sede,
    s.zona,
    COALESCE(c.total_conexiones, 0) AS total_conexiones,
    COALESCE(c.velocidad_promedio_mbps, 0) AS velocidad_promedio_mbps,
    COALESCE(d.total_dispositivos, 0) AS total_dispositivos,
    COALESCE(d.dispositivos_buenos, 0) AS dispositivos_buenos,
    COALESCE(d.dispositivos_danados, 0) AS dispositivos_danados,
    COALESCE(i.total_incidencias_historicas, 0) AS total_incidencias_historicas,
    COALESCE(i.incidencias_abiertas, 0) AS incidencias_abiertas,
    COALESCE(i.incidencias_cerradas, 0) AS incidencias_cerradas,
    COALESCE(i.horas_reparacion_promedio, 0) AS horas_reparacion_promedio
FROM SEDE_EDUCATIVA s
JOIN MUNICIPIO m ON m.id_municipio = s.id_municipio
LEFT JOIN (
    SELECT
        id_sede,
        COUNT(*) AS total_conexiones,
        ROUND(AVG(velocidad_mbps), 2) AS velocidad_promedio_mbps
    FROM CONEXION
    GROUP BY id_sede
) c ON c.id_sede = s.id_sede
LEFT JOIN (
    SELECT
        id_sede,
        COUNT(*) AS total_dispositivos,
        SUM(CASE WHEN estado_fisico = 'Bueno' THEN 1 ELSE 0 END) AS dispositivos_buenos,
        SUM(CASE WHEN estado_fisico = 'Dañado' THEN 1 ELSE 0 END) AS dispositivos_danados
    FROM DISPOSITIVO
    GROUP BY id_sede
) d ON d.id_sede = s.id_sede
LEFT JOIN (
    SELECT
        id_sede,
        COUNT(*) AS total_incidencias_historicas,
        SUM(CASE WHEN fecha_cierre IS NULL THEN 1 ELSE 0 END) AS incidencias_abiertas,
        SUM(CASE WHEN fecha_cierre IS NOT NULL THEN 1 ELSE 0 END) AS incidencias_cerradas,
        ROUND(AVG(CASE
            WHEN fecha_cierre IS NOT NULL
            THEN TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_cierre) / 60
            ELSE NULL
        END), 2) AS horas_reparacion_promedio
    FROM INCIDENCIA
    GROUP BY id_sede
) i ON i.id_sede = s.id_sede;

-- TENDENCIA MENSUAL
CREATE VIEW vw_tendencia_mensual_conectividad AS
SELECT
    DATE_FORMAT(mu.fecha_medicion, '%Y-%m-01') AS fecha_mes,
    COUNT(*) AS total_mediciones,
    COUNT(DISTINCT mu.id_conexion) AS conexiones_medicadas,
    ROUND(SUM(mu.horas_servicio_activo), 2) AS horas_servicio_total,
    ROUND(AVG(mu.horas_servicio_activo), 2) AS horas_servicio_promedio,
    ROUND(AVG(mu.horas_servicio_activo / 744 * 100), 2) AS disponibilidad_promedio_pct,
    COALESCE(con.total_conexiones_nuevas, 0) AS total_conexiones_nuevas
FROM MEDICION_USO mu
LEFT JOIN (
    SELECT
        DATE_FORMAT(vigencia_inicio, '%Y-%m-01') AS fecha_mes,
        COUNT(*) AS total_conexiones_nuevas
    FROM CONEXION
    GROUP BY DATE_FORMAT(vigencia_inicio, '%Y-%m-01')
) con
  ON con.fecha_mes = DATE_FORMAT(mu.fecha_medicion, '%Y-%m-01')
GROUP BY
    DATE_FORMAT(mu.fecha_medicion, '%Y-%m-01'),
    con.total_conexiones_nuevas;

-- ANÁLISIS GEOGRÁFICO Y DE PROVEEDOR
CREATE VIEW vw_analisis_dimension_geografica_proveedor AS
SELECT
    m.id_municipio,
    m.nombre_municipio AS municipio,
    COALESCE(sedes.total_sedes, 0) AS total_sedes,
    COALESCE(conex.total_enlaces, 0) AS total_enlaces,
    COALESCE(conex.velocidad_promedio_mbps, 0) AS velocidad_promedio_mbps,
    COALESCE(prov.total_proveedores, 0) AS total_proveedores,
    COALESCE(disps.total_dispositivos, 0) AS total_dispositivos,
    COALESCE(inci.total_incidencias_historicas, 0) AS total_incidencias_historicas,
    COALESCE(inci.incidencias_abiertas, 0) AS incidencias_abiertas,
    COALESCE(med.promedio_horas_servicio, 0) AS promedio_horas_servicio,
    COALESCE(med.promedio_horas_servicio, 0) AS promedio_horas_servicio_activo
FROM MUNICIPIO m
LEFT JOIN (
    SELECT id_municipio, COUNT(*) AS total_sedes
    FROM SEDE_EDUCATIVA
    GROUP BY id_municipio
) sedes ON sedes.id_municipio = m.id_municipio
LEFT JOIN (
    SELECT
        s.id_municipio,
        COUNT(DISTINCT c.id_conexion) AS total_enlaces,
        ROUND(AVG(c.velocidad_mbps), 2) AS velocidad_promedio_mbps,
        COUNT(DISTINCT c.id_proveedor) AS total_proveedores
    FROM SEDE_EDUCATIVA s
    JOIN CONEXION c ON c.id_sede = s.id_sede
    GROUP BY s.id_municipio
) conex ON conex.id_municipio = m.id_municipio
LEFT JOIN (
    SELECT id_municipio, COUNT(*) AS total_proveedores
    FROM (
        SELECT DISTINCT s.id_municipio, c.id_proveedor
        FROM SEDE_EDUCATIVA s
        JOIN CONEXION c ON c.id_sede = s.id_sede
    ) prov_dist
    GROUP BY id_municipio
) prov ON prov.id_municipio = m.id_municipio
LEFT JOIN (
    SELECT s.id_municipio, COUNT(*) AS total_dispositivos
    FROM SEDE_EDUCATIVA s
    JOIN DISPOSITIVO d ON d.id_sede = s.id_sede
    GROUP BY s.id_municipio
) disps ON disps.id_municipio = m.id_municipio
LEFT JOIN (
    SELECT
        s.id_municipio,
        COUNT(*) AS total_incidencias_historicas,
        SUM(CASE WHEN i.fecha_cierre IS NULL THEN 1 ELSE 0 END) AS incidencias_abiertas
    FROM SEDE_EDUCATIVA s
    JOIN INCIDENCIA i ON i.id_sede = s.id_sede
    GROUP BY s.id_municipio
) inci ON inci.id_municipio = m.id_municipio
LEFT JOIN (
    SELECT
        s.id_municipio,
        ROUND(AVG(mu.horas_servicio_activo), 2) AS promedio_horas_servicio
    FROM SEDE_EDUCATIVA s
    JOIN CONEXION c ON c.id_sede = s.id_sede
    JOIN MEDICION_USO mu ON mu.id_conexion = c.id_conexion
    GROUP BY s.id_municipio
) med ON med.id_municipio = m.id_municipio;
