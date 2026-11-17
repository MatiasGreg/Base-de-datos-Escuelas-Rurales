USE bd_escuelas_rurales;

DELIMITER $$

DROP FUNCTION IF EXISTS fn_horas_reparacion$$
CREATE FUNCTION fn_horas_reparacion(p_id_incidencia INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_horas DECIMAL(10,2) DEFAULT NULL;
    SELECT ROUND(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_cierre) / 60, 2)
    INTO v_horas
    FROM INCIDENCIA
    WHERE id_incidencia = p_id_incidencia
      AND fecha_cierre IS NOT NULL;
    RETURN v_horas;
END$$

DROP FUNCTION IF EXISTS fn_disponibilidad_pct$$
CREATE FUNCTION fn_disponibilidad_pct(p_id_conexion INT, p_anio INT, p_mes INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_horas_mes INT;
    DECLARE v_horas_activas DECIMAL(10,2);

    IF p_anio IS NULL OR p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN
        RETURN NULL;
    END IF;

    SET v_inicio = STR_TO_DATE(
        CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'),
        '%Y-%m-%d'
    );
    SET v_horas_mes = DAY(LAST_DAY(v_inicio)) * 24;

    SELECT AVG(horas_servicio_activo)
    INTO v_horas_activas
    FROM MEDICION_USO
    WHERE id_conexion = p_id_conexion
      AND fecha_medicion >= v_inicio
      AND fecha_medicion < v_inicio + INTERVAL 1 MONTH;

    IF v_horas_activas IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN LEAST(100, ROUND(v_horas_activas / v_horas_mes * 100, 2));
END$$

DROP PROCEDURE IF EXISTS sp_registrar_incidencia$$
CREATE PROCEDURE sp_registrar_incidencia(
    IN p_id_sede INT,
    IN p_id_conexion INT,
    IN p_codigo_inventario VARCHAR(50),
    IN p_descripcion_falla TEXT,
    IN p_fecha_inicio DATETIME,
    IN p_id_tecnico INT,
    IN p_estado_conexion VARCHAR(20),
    OUT p_id_incidencia INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET p_id_incidencia = NULL;
    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM SEDE_EDUCATIVA WHERE id_sede = p_id_sede) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sede indicada no existe';
    END IF;

    IF p_descripcion_falla IS NULL OR TRIM(p_descripcion_falla) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La descripcion de la falla es obligatoria';
    END IF;

    IF p_id_tecnico IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM TECNICO
           WHERE id_tecnico = p_id_tecnico AND activo = 1
       ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tecnico no existe o no esta activo';
    END IF;

    INSERT INTO INCIDENCIA (
        id_sede, id_conexion, codigo_inventario,
        descripcion_falla, fecha_inicio, fecha_cierre
    )
    VALUES (
        p_id_sede, p_id_conexion, p_codigo_inventario,
        p_descripcion_falla, COALESCE(p_fecha_inicio, NOW()), NULL
    );

    SET p_id_incidencia = LAST_INSERT_ID();

    IF p_id_tecnico IS NOT NULL THEN
        INSERT INTO INCIDENCIA_TECNICO (
            id_incidencia, id_tecnico, rol_asignado
        )
        VALUES (p_id_incidencia, p_id_tecnico, 'Principal');
    END IF;

    IF p_estado_conexion IS NOT NULL THEN
        INSERT INTO HISTORIAL_ESTADO_CONEXION (
            id_conexion, estado_actual, observaciones
        )
        VALUES (
            p_id_conexion,
            p_estado_conexion,
            CONCAT('Registrado desde la incidencia #', p_id_incidencia)
        );
    END IF;

    COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_cerrar_incidencia$$
CREATE PROCEDURE sp_cerrar_incidencia(
    IN p_id_incidencia INT,
    IN p_fecha_cierre DATETIME,
    IN p_estado_conexion_final VARCHAR(20),
    OUT p_horas_reparacion DECIMAL(10,2)
)
BEGIN
    DECLARE v_id_conexion INT;
    DECLARE v_inicio DATETIME;
    DECLARE v_cierre DATETIME;
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET p_horas_reparacion = NULL;
    START TRANSACTION;

    SELECT COUNT(*) INTO v_existe
    FROM INCIDENCIA
    WHERE id_incidencia = p_id_incidencia
    FOR UPDATE;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La incidencia indicada no existe';
    END IF;

    SELECT id_conexion, fecha_inicio
    INTO v_id_conexion, v_inicio
    FROM INCIDENCIA
    WHERE id_incidencia = p_id_incidencia
      AND fecha_cierre IS NULL;

    IF v_inicio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La incidencia ya esta cerrada';
    END IF;

    SET v_cierre = COALESCE(p_fecha_cierre, NOW());

    IF v_cierre < v_inicio THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de cierre no puede ser anterior al inicio';
    END IF;

    UPDATE INCIDENCIA
    SET fecha_cierre = v_cierre
    WHERE id_incidencia = p_id_incidencia;

    IF p_estado_conexion_final IS NOT NULL THEN
        INSERT INTO HISTORIAL_ESTADO_CONEXION (
            id_conexion, fecha_hora_registro, estado_actual, observaciones
        )
        VALUES (
            v_id_conexion,
            v_cierre,
            p_estado_conexion_final,
            CONCAT('Cierre de la incidencia #', p_id_incidencia)
        );
    END IF;

    SET p_horas_reparacion = fn_horas_reparacion(p_id_incidencia);
    COMMIT;
END$$

DROP PROCEDURE IF EXISTS sp_actualizar_dispositivo$$
CREATE PROCEDURE sp_actualizar_dispositivo(
    IN p_codigo_inventario VARCHAR(50),
    IN p_estado_fisico VARCHAR(20),
    IN p_id_responsable INT,
    OUT p_filas_modificadas INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET p_filas_modificadas = 0;
    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM DISPOSITIVO
        WHERE codigo_inventario = p_codigo_inventario
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El dispositivo indicado no existe';
    END IF;

    IF p_estado_fisico IS NULL AND p_id_responsable IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debe indicar un nuevo estado fisico o responsable';
    END IF;

    UPDATE DISPOSITIVO
    SET estado_fisico = COALESCE(p_estado_fisico, estado_fisico),
        id_responsable = COALESCE(p_id_responsable, id_responsable)
    WHERE codigo_inventario = p_codigo_inventario;

    SET p_filas_modificadas = ROW_COUNT();
    COMMIT;
END$$

DROP TRIGGER IF EXISTS trg_historial_no_update$$
CREATE TRIGGER trg_historial_no_update
BEFORE UPDATE ON HISTORIAL_ESTADO_CONEXION
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: el historial de estados es inmutable';
END$$

DROP TRIGGER IF EXISTS trg_historial_no_delete$$
CREATE TRIGGER trg_historial_no_delete
BEFORE DELETE ON HISTORIAL_ESTADO_CONEXION
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN02: el historial de estados es inmutable';
END$$

DROP TRIGGER IF EXISTS trg_incidencia_validar_coherencia$$
CREATE TRIGGER trg_incidencia_validar_coherencia
BEFORE INSERT ON INCIDENCIA
FOR EACH ROW
BEGIN
    IF NEW.id_conexion IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM CONEXION
           WHERE id_conexion = NEW.id_conexion AND id_sede = NEW.id_sede
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La conexion no pertenece a la sede';
    END IF;

    IF NEW.codigo_inventario IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM DISPOSITIVO
           WHERE codigo_inventario = NEW.codigo_inventario
             AND id_sede = NEW.id_sede
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El dispositivo no pertenece a la sede';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_incidencia_validar_coherencia_upd$$
CREATE TRIGGER trg_incidencia_validar_coherencia_upd
BEFORE UPDATE ON INCIDENCIA
FOR EACH ROW
BEGIN
    IF NEW.id_conexion IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM CONEXION
           WHERE id_conexion = NEW.id_conexion AND id_sede = NEW.id_sede
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La conexion no pertenece a la sede';
    END IF;

    IF NEW.codigo_inventario IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM DISPOSITIVO
           WHERE codigo_inventario = NEW.codigo_inventario
             AND id_sede = NEW.id_sede
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El dispositivo no pertenece a la sede';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_dispositivo_auditar_insert$$
CREATE TRIGGER trg_dispositivo_auditar_insert
AFTER INSERT ON DISPOSITIVO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DISPOSITIVO (
        codigo_inventario, estado_anterior, estado_nuevo,
        id_responsable_anterior, id_responsable_nuevo,
        usuario, origen
    )
    VALUES (
        NEW.codigo_inventario, NULL, NEW.estado_fisico,
        NULL, NEW.id_responsable, CURRENT_USER(), 'Trigger'
    );
END$$

DROP TRIGGER IF EXISTS trg_dispositivo_auditar_cambio$$
CREATE TRIGGER trg_dispositivo_auditar_cambio
AFTER UPDATE ON DISPOSITIVO
FOR EACH ROW
BEGIN
    IF NOT (OLD.estado_fisico <=> NEW.estado_fisico)
       OR NOT (OLD.id_responsable <=> NEW.id_responsable) THEN
        INSERT INTO AUDITORIA_DISPOSITIVO (
            codigo_inventario, estado_anterior, estado_nuevo,
            id_responsable_anterior, id_responsable_nuevo,
            usuario, origen
        )
        VALUES (
            NEW.codigo_inventario, OLD.estado_fisico, NEW.estado_fisico,
            OLD.id_responsable, NEW.id_responsable,
            CURRENT_USER(), 'Trigger'
        );
    END IF;
END$$

DELIMITER ;
