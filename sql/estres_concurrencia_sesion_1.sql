USE bd_escuelas_rurales;

-- Ejecutar en una primera consola MariaDB.
-- La sesión 2 intenta actualizar el mismo dispositivo mientras esta sesión
-- conserva el bloqueo de fila.
SET SESSION innodb_lock_wait_timeout = 10;
START TRANSACTION;

SELECT codigo_inventario, estado_fisico, id_responsable
FROM DISPOSITIVO
WHERE codigo_inventario = 'INV-MINTIC-2024-001'
FOR UPDATE;

UPDATE DISPOSITIVO
SET estado_fisico = 'Regular'
WHERE codigo_inventario = 'INV-MINTIC-2024-001';

SELECT 'Sesion 1 mantiene el bloqueo; ejecutar ahora sesion 2' AS instruccion;
DO SLEEP(5);
COMMIT;

SELECT 'Sesion 1 confirmó su transaccion' AS resultado;
