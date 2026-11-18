USE bd_escuelas_rurales;

-- Ejecutar simultáneamente en una segunda consola MariaDB.
-- La sentencia espera el bloqueo de la sesión 1 y luego confirma que InnoDB
-- serializa la actualización. El trigger generará la auditoría correspondiente.
SET SESSION innodb_lock_wait_timeout = 10;
START TRANSACTION;

UPDATE DISPOSITIVO
SET estado_fisico = 'Dañado'
WHERE codigo_inventario = 'INV-MINTIC-2024-001';

COMMIT;

SELECT codigo_inventario, estado_fisico
FROM DISPOSITIVO
WHERE codigo_inventario = 'INV-MINTIC-2024-001';
