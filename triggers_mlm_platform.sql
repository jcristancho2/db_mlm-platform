-- 1. Actualizar la fecha de modificación de un producto
DELIMITER $$
CREATE TRIGGER trg_update_product_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- 2. Registrar log cuando un cliente califica un producto
CREATE TABLE IF NOT EXISTS log_acciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    accion VARCHAR(100),
    cliente_id INT,
    producto_id INT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_log_calificacion
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    INSERT INTO log_acciones (accion, cliente_id, producto_id)
    VALUES ('Calificacion producto', NEW.customer_id, NEW.product_id);
END$$
DELIMITER ;

-- 3. Impedir insertar productos sin unidad de medida
DELIMITER $$
CREATE TRIGGER trg_no_product_sin_unidad
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.unit_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite producto sin unidad de medida';
    END IF;
END$$
DELIMITER ;

-- 4. Validar calificaciones no mayores a 5
DELIMITER $$
CREATE TRIGGER trg_valida_rating_max
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
    IF NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La calificación máxima permitida es 5';
    END IF;
END$$
DELIMITER ;

-- 5. Actualizar estado de membresía cuando vence
DELIMITER $$
CREATE TRIGGER trg_actualiza_estado_membresia
AFTER UPDATE ON membershipperiods
FOR EACH ROW
BEGIN
    IF NEW.end_date < CURDATE() THEN
        UPDATE membershipperiods SET status = 'INACTIVA' WHERE membership_id = NEW.membership_id AND period_id = NEW.period_id;
    END IF;
END$$
DELIMITER ;

-- 6. Evitar duplicados de productos por empresa
DELIMITER $$
CREATE TRIGGER trg_no_duplicado_producto_empresa
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM companyproducts
        WHERE company_id = NEW.company_id AND product_id = NEW.product_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Producto ya existe para esta empresa';
    END IF;
END$$
DELIMITER ;

-- 7. Enviar notificación al añadir un favorito
CREATE TABLE IF NOT EXISTS notificaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensaje VARCHAR(255),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_notifica_favorito
AFTER INSERT ON details_favorites
FOR EACH ROW
BEGIN
    INSERT INTO notificaciones (mensaje)
    VALUES (CONCAT('Nuevo favorito añadido: producto ', NEW.product_id));
END$$
DELIMITER ;

-- 8. Insertar fila en quality_products tras calificación
DELIMITER $$
CREATE TRIGGER trg_insert_quality_products
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    INSERT IGNORE INTO quality_products (product_id, quality_level)
    VALUES (NEW.product_id, 'Pendiente');
END$$
DELIMITER ;

-- 9. Eliminar favoritos si se elimina el producto
DELIMITER $$
CREATE TRIGGER trg_delete_favoritos_al_borrar_producto
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites WHERE product_id = OLD.id;
END$$
DELIMITER ;

-- 10. Bloquear modificación de audiencias activas
DELIMITER $$
CREATE TRIGGER trg_bloquea_audiencia_activa
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
    IF OLD.status = 'ACTIVA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar una audiencia activa';
    END IF;
END$$
DELIMITER ;

-- 11. Recalcular promedio de calidad tras nueva evaluación
DELIMITER $$
CREATE TRIGGER trg_recalcula_promedio_calidad
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    UPDATE products
    SET average_rating = (SELECT AVG(rating) FROM rates WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END$$
DELIMITER ;

-- 12. Registrar asignación de nuevo beneficio
CREATE TABLE IF NOT EXISTS bitacora (
    id INT AUTO_INCREMENT PRIMARY KEY,
    accion VARCHAR(100),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_log_beneficio_membresia
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (accion) VALUES (CONCAT('Nuevo beneficio asignado a membresía ', NEW.membership_id));
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_log_beneficio_audiencia
AFTER INSERT ON audiencebenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (accion) VALUES (CONCAT('Nuevo beneficio asignado a audiencia ', NEW.audience_id));
END$$
DELIMITER ;

-- 13. Impedir doble calificación por parte del cliente
DELIMITER $$
CREATE TRIGGER trg_no_doble_calificacion
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM rates WHERE product_id = NEW.product_id AND customer_id = NEW.customer_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite calificar el mismo producto dos veces seguidas';
    END IF;
END$$
DELIMITER ;

-- 14. Validar correos duplicados en clientes
DELIMITER $$
CREATE TRIGGER trg_no_email_duplicado
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM customers WHERE email = NEW.email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico ya registrado';
    END IF;
END$$
DELIMITER ;

-- 15. Eliminar detalles de favoritos huérfanos
DELIMITER $$
CREATE TRIGGER trg_delete_details_favorites
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites WHERE favorite_id = OLD.id;
END$$
DELIMITER ;

-- 16. Actualizar campo updated_at en companies
DELIMITER $$
CREATE TRIGGER trg_update_companies_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- 17. Impedir borrar ciudad si hay empresas activas
DELIMITER $$
CREATE TRIGGER trg_no_borrar_ciudad_con_empresas
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM companies WHERE city_id = OLD.code) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede borrar ciudad con empresas activas';
    END IF;
END$$
DELIMITER ;

-- 18. Registrar cambios de estado en encuestas
CREATE TABLE IF NOT EXISTS log_estado_encuestas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    poll_id INT,
    nuevo_estado VARCHAR(20),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_log_estado_encuesta
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO log_estado_encuestas (poll_id, nuevo_estado)
        VALUES (NEW.id, NEW.status);
    END IF;
END$$
DELIMITER ;

-- 19. Sincronizar rates y quality_products
DELIMITER $$
CREATE TRIGGER trg_sync_rates_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    UPDATE quality_products
    SET quality_level = 
        CASE
            WHEN (SELECT AVG(rating) FROM rates WHERE product_id = NEW.product_id) >= 4.5 THEN 'Alta'
            WHEN (SELECT AVG(rating) FROM rates WHERE product_id = NEW.product_id) >= 3 THEN 'Media'
            ELSE 'Baja'
        END
    WHERE product_id = NEW.product_id;
END$$
DELIMITER ;

-- 20. Eliminar productos sin relación a empresas
DELIMITER $$
CREATE TRIGGER trg_delete_producto_sin_empresa
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM companyproducts WHERE product_id = OLD.product_id) THEN
        DELETE FROM products WHERE id = OLD.product_id;
    END IF;
END$$
DELIMITER ;