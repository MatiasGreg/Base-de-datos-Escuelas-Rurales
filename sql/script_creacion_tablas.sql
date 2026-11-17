CREATE DATABASE IF NOT EXISTS bd_escuelas_rurales
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE bd_escuelas_rurales;

DROP TABLE IF EXISTS AUDITORIA_DISPOSITIVO;
DROP TABLE IF EXISTS INCIDENCIA_TECNICO;
DROP TABLE IF EXISTS TECNICO;
DROP TABLE IF EXISTS MEDICION_USO;
DROP TABLE IF EXISTS INCIDENCIA;
DROP TABLE IF EXISTS DISPOSITIVO;
DROP TABLE IF EXISTS HISTORIAL_ESTADO_CONEXION;
DROP TABLE IF EXISTS CONEXION;
DROP TABLE IF EXISTS SEDE_EDUCATIVA;
DROP TABLE IF EXISTS RESPONSABLE;
DROP TABLE IF EXISTS PROVEEDOR;
DROP TABLE IF EXISTS MUNICIPIO;

CREATE TABLE MUNICIPIO (
    id_municipio INT AUTO_INCREMENT PRIMARY KEY,
    nombre_municipio VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE PROVEEDOR (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre_proveedor VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE RESPONSABLE (
    id_responsable INT AUTO_INCREMENT PRIMARY KEY,
    descripcion_cargo VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE TECNICO (
    id_tecnico INT AUTO_INCREMENT PRIMARY KEY,
    codigo_tecnico VARCHAR(20) NOT NULL UNIQUE,
    especialidad VARCHAR(30) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT chk_tecnico_especialidad CHECK (
        especialidad IN ('Redes', 'Hardware', 'Energia', 'Satelital', 'Soporte general')
    ),
    CONSTRAINT chk_tecnico_activo CHECK (activo IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE SEDE_EDUCATIVA (
    id_sede INT AUTO_INCREMENT PRIMARY KEY,
    id_municipio INT NOT NULL,
    nombre_sede VARCHAR(150) NOT NULL,
    zona VARCHAR(20) NOT NULL,
    CONSTRAINT fk_sede_municipio FOREIGN KEY (id_municipio)
        REFERENCES MUNICIPIO(id_municipio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_sede_zona CHECK (zona IN ('Rural', 'Palafito'))
) ENGINE=InnoDB;

CREATE TABLE CONEXION (
    id_conexion INT AUTO_INCREMENT PRIMARY KEY,
    id_sede INT NOT NULL,
    id_proveedor INT NOT NULL,
    tipo_servicio VARCHAR(50) NOT NULL,
    velocidad_mbps INT NOT NULL,
    vigencia_inicio DATE NOT NULL,
    vigencia_fin DATE NULL,
    CONSTRAINT fk_conexion_sede FOREIGN KEY (id_sede)
        REFERENCES SEDE_EDUCATIVA(id_sede)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_conexion_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES PROVEEDOR(id_proveedor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_conexion_tipo CHECK (
        tipo_servicio IN ('Satelital', 'Fibra', 'Radioenlace', 'Movil')
    ),
    CONSTRAINT chk_conexion_velocidad CHECK (velocidad_mbps > 0),
    CONSTRAINT chk_conexion_fechas CHECK (
        vigencia_fin IS NULL OR vigencia_fin >= vigencia_inicio
    )
) ENGINE=InnoDB;

CREATE TABLE HISTORIAL_ESTADO_CONEXION (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_conexion INT NOT NULL,
    fecha_hora_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_actual VARCHAR(20) NOT NULL,
    observaciones TEXT NULL,
    CONSTRAINT fk_historial_conexion FOREIGN KEY (id_conexion)
        REFERENCES CONEXION(id_conexion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_historial_estado CHECK (
        estado_actual IN ('Activo', 'Intermitente', 'Caído')
    )
) ENGINE=InnoDB;

CREATE TABLE DISPOSITIVO (
    codigo_inventario VARCHAR(50) PRIMARY KEY,
    id_sede INT NOT NULL,
    id_responsable INT NOT NULL,
    tipo_dispositivo VARCHAR(100) NOT NULL,
    fecha_entrega DATE NOT NULL DEFAULT (CURRENT_DATE),
    estado_fisico VARCHAR(20) NOT NULL DEFAULT 'Bueno',
    CONSTRAINT fk_dispositivo_sede FOREIGN KEY (id_sede)
        REFERENCES SEDE_EDUCATIVA(id_sede)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_dispositivo_responsable FOREIGN KEY (id_responsable)
        REFERENCES RESPONSABLE(id_responsable)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_dispositivo_estado CHECK (
        estado_fisico IN ('Bueno', 'Regular', 'Dañado')
    )
) ENGINE=InnoDB;

CREATE TABLE INCIDENCIA (
    id_incidencia INT AUTO_INCREMENT PRIMARY KEY,
    id_sede INT NOT NULL,
    id_conexion INT NULL,
    codigo_inventario VARCHAR(50) NULL,
    descripcion_falla TEXT NOT NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre DATETIME NULL,
    CONSTRAINT fk_incidencia_sede FOREIGN KEY (id_sede)
        REFERENCES SEDE_EDUCATIVA(id_sede)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_incidencia_conexion FOREIGN KEY (id_conexion)
        REFERENCES CONEXION(id_conexion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_incidencia_dispositivo FOREIGN KEY (codigo_inventario)
        REFERENCES DISPOSITIVO(codigo_inventario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_incidencia_fechas CHECK (
        fecha_cierre IS NULL OR fecha_cierre >= fecha_inicio
    )
) ENGINE=InnoDB;

CREATE TABLE MEDICION_USO (
    id_medicion INT AUTO_INCREMENT PRIMARY KEY,
    id_conexion INT NOT NULL,
    fecha_medicion DATE NOT NULL,
    horas_servicio_activo DECIMAL(5,2) NOT NULL,
    CONSTRAINT fk_medicion_conexion FOREIGN KEY (id_conexion)
        REFERENCES CONEXION(id_conexion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_medicion_horas CHECK (
        horas_servicio_activo BETWEEN 0 AND 744
    )
) ENGINE=InnoDB;

CREATE TABLE INCIDENCIA_TECNICO (
    id_incidencia INT NOT NULL,
    id_tecnico INT NOT NULL,
    rol_asignado VARCHAR(20) NOT NULL DEFAULT 'Principal',
    fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_incidencia, id_tecnico),
    CONSTRAINT fk_inctec_incidencia FOREIGN KEY (id_incidencia)
        REFERENCES INCIDENCIA(id_incidencia)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inctec_tecnico FOREIGN KEY (id_tecnico)
        REFERENCES TECNICO(id_tecnico)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_inctec_rol CHECK (
        rol_asignado IN ('Principal', 'Apoyo')
    )
) ENGINE=InnoDB;

CREATE TABLE AUDITORIA_DISPOSITIVO (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    codigo_inventario VARCHAR(50) NOT NULL,
    estado_anterior VARCHAR(20) NULL,
    estado_nuevo VARCHAR(20) NOT NULL,
    id_responsable_anterior INT NULL,
    id_responsable_nuevo INT NOT NULL,
    usuario VARCHAR(100) NOT NULL DEFAULT 'sistema',
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    origen VARCHAR(30) NOT NULL DEFAULT 'Trigger',
    CONSTRAINT chk_aud_estado CHECK (
        estado_nuevo IN ('Bueno', 'Regular', 'Dañado')
    )
) ENGINE=InnoDB;

CREATE INDEX idx_sede_municipio ON SEDE_EDUCATIVA(id_municipio);
CREATE INDEX idx_conexion_sede ON CONEXION(id_sede);
CREATE INDEX idx_conexion_proveedor ON CONEXION(id_proveedor);
CREATE INDEX idx_historial_conexion ON HISTORIAL_ESTADO_CONEXION(id_conexion);
CREATE INDEX idx_historial_estado ON HISTORIAL_ESTADO_CONEXION(estado_actual);
CREATE INDEX idx_dispositivo_sede ON DISPOSITIVO(id_sede);
CREATE INDEX idx_dispositivo_responsable ON DISPOSITIVO(id_responsable);
CREATE INDEX idx_incidencia_sede ON INCIDENCIA(id_sede);
CREATE INDEX idx_incidencia_conexion ON INCIDENCIA(id_conexion);
CREATE INDEX idx_medicion_conexion ON MEDICION_USO(id_conexion);
CREATE INDEX idx_inctec_tecnico ON INCIDENCIA_TECNICO(id_tecnico);
CREATE INDEX idx_aud_dispositivo ON AUDITORIA_DISPOSITIVO(codigo_inventario);
