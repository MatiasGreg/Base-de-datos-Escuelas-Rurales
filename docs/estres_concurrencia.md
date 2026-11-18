# Prueba de estrés concurrente

La prueba usa dos sesiones InnoDB que actualizan la misma fila de
`DISPOSITIVO`. La sesión 1 adquiere el bloqueo con `SELECT ... FOR UPDATE`,
mantiene la transacción durante cinco segundos y confirma. La sesión 2 se
ejecuta durante ese intervalo, espera el bloqueo y actualiza después del
`COMMIT` de la primera sesión.

En dos terminales, desde el directorio del proyecto:

```bash
mysql -u root -p < sql/estres_concurrencia_sesion_1.sql
mysql -u root -p < sql/estres_concurrencia_sesion_2.sql
```

Resultado esperado:

1. La sesión 2 espera sin leer datos sucios.
2. No ocurre pérdida silenciosa de actualización.
3. El trigger `trg_dispositivo_auditar_cambio` registra ambos cambios.
4. La consulta final de la sesión 2 muestra `Dañado`.
