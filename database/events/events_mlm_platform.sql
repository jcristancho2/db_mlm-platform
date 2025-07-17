-- Activar el programador de eventos
SET GLOBAL event_scheduler = ON;




CREATE TABLE IF NOT EXISTS user_reminders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    fecha DATETIME DEFAULT NOW(),
    UNIQUE KEY (customer_id, product_id)
);

CREATE TABLE IF NOT EXISTS favoritos_resumen (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    total_favoritos INT NOT NULL,
    fecha DATETIME DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auditorias_diarias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME DEFAULT NOW(),
    total_productos INT NOT NULL,
    total_clientes INT NOT NULL,
    total_empresas INT NOT NULL
);

CREATE TABLE IF NOT EXISTS notificaciones_empresa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    fecha DATETIME DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS estadisticas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME DEFAULT NOW(),
    total_productos INT NOT NULL,
    total_empresas INT NOT NULL,
    total_clientes INT NOT NULL
);

CREATE TABLE IF NOT EXISTS resumen_categoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    total_calificados INT NOT NULL,
    fecha DATETIME DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alertas_productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    fecha DATETIME DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inflacion_indice (
    id INT AUTO_INCREMENT PRIMARY KEY,
    valor DECIMAL(10,4) NOT NULL,
    fecha DATE NOT NULL
);


ALTER TABLE productos_backup ADD COLUMN fecha_backup DATETIME DEFAULT NOW();

ALTER TABLE rates_backup ADD COLUMN fecha_backup DATETIME DEFAULT NOW();



-- 1. Borrar productos sin actividad cada 6 meses
CREATE EVENT IF NOT EXISTS ev_borrar_productos_sin_actividad
ON SCHEDULE EVERY 6 MONTH
DO
  CALL eliminar_productos_huerfanos();

-- 2. Recalcular el promedio de calificaciones semanalmente

CREATE EVENT IF NOT EXISTS ev_recalcular_promedios_calidad
ON SCHEDULE EVERY 1 WEEK
DO
  CALL recalcular_promedios_calidad();


-- 3. Actualizar precios según inflación mensual

CREATE EVENT IF NOT EXISTS ev_actualizar_precios_inflacion
ON SCHEDULE EVERY 1 MONTH
DO
  UPDATE companyproducts SET price = price * 1.03;


-- 4. Crear backups lógicos diariamente

-- Usar DELIMITER y BEGIN...END para múltiples instrucciones y especificar columnas
DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_backup_logico_diario
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE, '00:00:00'))
DO
BEGIN
  INSERT INTO productos_backup (
    id, name, description, price, category_id, created_at, updated_at, fecha_backup
  )
  SELECT
    id, name, description, price, category_id, created_at, updated_at, NOW()
  FROM products;

  INSERT INTO rates_backup (
    id, product_id, customer_id, rating, comment, created_at, fecha_backup
  )
  SELECT
    id, product_id, customer_id, rating, comment, created_at, NOW()
  FROM rates;
END $$

DELIMITER ;



-- 5. Notificar sobre productos favoritos sin calificar

CREATE EVENT IF NOT EXISTS ev_notificar_favoritos_no_calificados
ON SCHEDULE EVERY 1 WEEK
DO
  INSERT INTO user_reminders (customer_id, product_id)
  SELECT f.customer_id, df.product_id
  FROM favorites f
  JOIN details_favorites df ON f.id = df.favorite_id
  LEFT JOIN rates r ON r.product_id = df.product_id AND r.customer_id = f.customer_id
  WHERE r.id IS NULL;


-- 6. Revisar inconsistencias entre empresa y productos

-- Usar DELIMITER y BEGIN...END, y CONCAT para cadenas
DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_revisar_inconsistencias_empresa_producto
ON SCHEDULE EVERY 1 WEEK STARTS (TIMESTAMP(CURRENT_DATE, '00:00:00'))
DO
BEGIN
  INSERT INTO errores_log (error_desc, fecha)
  SELECT CONCAT('Producto sin empresa: ', p.id), NOW()
  FROM products p
  WHERE NOT EXISTS (SELECT 1 FROM companyproducts cp WHERE cp.product_id = p.id);

  INSERT INTO errores_log (error_desc, fecha)
  SELECT CONCAT('Empresa sin productos: ', c.id), NOW()
  FROM companies c
  WHERE NOT EXISTS (SELECT 1 FROM companyproducts cp WHERE cp.company_id = c.id);
END $$
DELIMITER ;


-- 7. Archivar membresías vencidas diariamente

CREATE EVENT IF NOT EXISTS ev_archivar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
DO
  UPDATE membershipperiods SET status = 'INACTIVA' WHERE end_date < CURDATE();


-- 8. Notificar beneficios nuevos a usuarios semanalmente

CREATE EVENT IF NOT EXISTS ev_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
DO
  INSERT INTO notificaciones (mensaje)
  SELECT CONCAT('Nuevo beneficio: ', description)
  FROM benefits
  WHERE created_at >= NOW() - INTERVAL 7 DAY;


-- 9. Calcular cantidad de favoritos por cliente mensualmente

CREATE EVENT IF NOT EXISTS ev_favoritos_resumen_mensual
ON SCHEDULE EVERY 1 MONTH
DO
  INSERT INTO favoritos_resumen (customer_id, total_favoritos, fecha)
  SELECT f.customer_id, COUNT(df.product_id), NOW()
  FROM favorites f
  JOIN details_favorites df ON f.id = df.favorite_id
  GROUP BY f.customer_id;


-- 10. Validar claves foráneas semanalmente

CREATE EVENT IF NOT EXISTS ev_validar_claves_foraneas
ON SCHEDULE EVERY 1 WEEK
DO
  CALL validar_claves_rates_polls();


-- 11. Eliminar calificaciones inválidas antiguas

CREATE EVENT IF NOT EXISTS ev_eliminar_calificaciones_invalidas
ON SCHEDULE EVERY 1 MONTH
DO
  DELETE FROM rates WHERE (rating IS NULL OR rating < 0) AND created_at < NOW() - INTERVAL 3 MONTH;


-- 12. Cambiar estado de encuestas inactivas automáticamente

CREATE EVENT IF NOT EXISTS ev_encuestas_inactivas
ON SCHEDULE EVERY 1 MONTH
DO
  UPDATE polls SET status = 'inactiva' WHERE id IN (
    SELECT p.id FROM polls p
    LEFT JOIN customerpollratings cpr ON cpr.poll_id = p.id
    WHERE cpr.poll_id IS NULL AND p.status <> 'inactiva' AND p.created_at < NOW() - INTERVAL 6 MONTH
  );


-- 13. Registrar auditorías de forma periódica

CREATE EVENT IF NOT EXISTS ev_auditoria_diaria
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO auditorias_diarias (fecha, total_productos, total_clientes, total_empresas)
  SELECT NOW(), (SELECT COUNT(*) FROM products), (SELECT COUNT(*) FROM customers), (SELECT COUNT(*) FROM companies);


-- 14. Notificar métricas de calidad a empresas

CREATE EVENT IF NOT EXISTS ev_notificar_metricas_calidad
ON SCHEDULE EVERY 1 WEEK STARTS (TIMESTAMP(CURRENT_DATE, '00:00:00'))
DO
  INSERT INTO notificaciones_empresa (company_id, mensaje, fecha)
  SELECT c.id, CONCAT('Promedio de rating de sus productos: ', IFNULL(AVG(r.rating), 'Sin calificaciones')), NOW()
  FROM companies c
  LEFT JOIN companyproducts cp ON cp.company_id = c.id
  LEFT JOIN rates r ON r.product_id = cp.product_id
  GROUP BY c.id;


-- 15. Recordar renovación de membresías

CREATE EVENT IF NOT EXISTS ev_recordar_renovacion_membresias
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO notificaciones (mensaje)
  SELECT CONCAT('Recuerde renovar su membresía que vence el ', end_date)
  FROM membershipperiods
  WHERE end_date BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY;


-- 16. Reordenar estadísticas generales cada semana

CREATE EVENT IF NOT EXISTS ev_estadisticas_generales
ON SCHEDULE EVERY 1 WEEK
DO
  INSERT INTO estadisticas (fecha, total_productos, total_empresas, total_clientes)
  SELECT NOW(), (SELECT COUNT(*) FROM products), (SELECT COUNT(*) FROM companies), (SELECT COUNT(*) FROM customers);


-- 17. Crear resúmenes temporales de uso por categoría

CREATE EVENT IF NOT EXISTS ev_resumen_categoria
ON SCHEDULE EVERY 1 WEEK
DO
  INSERT INTO resumen_categoria (categoria_id, total_calificados, fecha)
  SELECT p.category_id, COUNT(DISTINCT r.product_id), NOW()
  FROM products p
  JOIN rates r ON r.product_id = p.id
  GROUP BY p.category_id;


-- 18. Actualizar beneficios caducados

CREATE EVENT IF NOT EXISTS ev_actualizar_beneficios_caducados
ON SCHEDULE EVERY 1 DAY
DO
  UPDATE benefits
  SET status = 'inactivo'
  WHERE expires_at IS NOT NULL AND expires_at < NOW();


-- 19. Alertar productos sin evaluación anual

CREATE EVENT IF NOT EXISTS ev_alertar_productos_sin_evaluacion
ON SCHEDULE EVERY 1 YEAR
DO
  INSERT INTO alertas_productos (product_id, mensaje, fecha)
  SELECT p.id, 'Producto sin evaluación en el último año', NOW()
  FROM products p
  LEFT JOIN rates r ON r.product_id = p.id AND r.created_at > NOW() - INTERVAL 365 DAY
  WHERE r.id IS NULL;


-- 20. Actualizar precios con índice externo

CREATE EVENT IF NOT EXISTS ev_actualizar_precios_indice
ON SCHEDULE EVERY 1 MONTH
DO
  UPDATE companyproducts
  SET price = price * (
    SELECT valor
    FROM inflacion_indice
    WHERE fecha = (SELECT MAX(fecha) FROM inflacion_indice)
  );