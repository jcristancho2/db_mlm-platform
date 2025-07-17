
-- 1 registrar una nueva calificacion y actualziar el promedio

ALTER TABLE product ADD COLUMN average_rating FLOAT DOUBLE DEFAULT 0;

CREATE TABLE IF NOT EXISTS rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    rating DOUBLE DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

DELIMITER $$

CREATE PROCEDURE registrar_calificacion_actualizar_promedio(
    IN p_product_id INT,
    IN p_customer_id INT,
    IN p_rating DOUBLE
)
BEGIN

    INSERT INTO rates (product_id, customer_id, rating)
    VALUES (p_product_id, p_customer_id, p_rating);

    UPDATE products
    SET average_rating = (
        SELECT AVG(rating) FROM rates WHERE product_id = p_product_id
    )

    WHERE id = p_product_id;

END$$

DELIMITER ;



CALL registrar_calificacion_actualizar_promedio(1, 21, 4.5);


--comprovacion del procedimiento almacenado 1 
SELECT 'companies' AS tabla, id AS dato1, name AS dato2, NULL AS dato3
FROM companies WHERE id = 'CMP100'
UNION ALL
SELECT 'companyproducts', company_id, product_id, price
FROM companyproducts WHERE company_id = 'CMP100'
UNION ALL
SELECT 'rates', product_id, customer_id, rating
FROM rates WHERE product_id = 1;


-- 2 Insertar empresa y asociar productos por defecto

CREATE TABLE IF NOT EXISTS default_products(
    product_id INT PRIMARY KEY,
    price DOUBLE,
    unitmeasure_id INT,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (unitmeasure_id) REFERENCES unitofmeasure(id));

    INSERT INTO default_products (product_id, price, unitmeasure_id)
    VALUES (1, 10.0, 1),
           (2, 15.0, 1),
           (3, 20.0, 2);

DELIMITER $$

CREATE PROCEDURE insertar_empresa_y_asociar_productos_por_defecto(
    IN p_id VARCHAR(20),
    IN p_type_id INT,
    IN p_name VARCHAR(80),
    IN p_category_id INT,
    IN p_city_id VARCHAR(6),
    IN p_audience_id INT,
    IN p_cellphone VARCHAR(15),
    IN p_email VARCHAR(80)
)
BEGIN

    INSERT INTO companies (id, type_id, name, category_id, city_id, audience_id, cellphone, email)
    VALUES (p_id, p_type_id, p_name, p_category_id, p_city_id, p_audience_id, p_cellphone, p_email);

    INSERT INTO companyproducts (company_id, product_id, price, unitmeasure_id)
    SELECT p_id, product_id, price, unitmeasure_id
    FROM default_products;
END$$

DELIMITER ;


CALL insertar_empresa_y_asociar_productos_por_defecto(
    'CMP100', 6, 'Soluciones Digitales Bogotá', 2,'11001',1,'3201234567','contacto@solucionesbogota.com'
);

-- comprobacion de el procedimiento almacenado 2 
SELECT * FROM companies WHERE id = 'CMP100';


-- 3. Añadir producto favorito validando duplicados

DELIMITER $$

CREATE PROCEDURE agregar_producto_favorito(
    IN p_customer_id INT,
    IN p_company_id VARCHAR(20),
    IN p_product_id INT
)
BEGIN
    DECLARE v_favorite_id INT;

    SELECT id INTO v_favorite_id
    FROM favorites
    WHERE customer_id = p_customer_id AND company_id = p_company_id
    LIMIT 1;


    IF v_favorite_id IS NULL THEN
        INSERT INTO favorites (customer_id, company_id)
        VALUES (p_customer_id, p_company_id);
        SET v_favorite_id = LAST_INSERT_ID();
    END IF;


    IF NOT EXISTS (
        SELECT 1 FROM details_favorites
        WHERE favorite_id = v_favorite_id AND product_id = p_product_id
    ) THEN
        INSERT INTO details_favorites (favorite_id, product_id)
        VALUES (v_favorite_id, p_product_id);
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso:
CALL agregar_producto_favorito(21, 'CMP019', 2);

-- comprobacion de el procedimiento almacenado 3
SELECT * FROM details_favorites WHERE favorite_id IN (
    SELECT id FROM favorites WHERE customer_id = 21 AND company_id = 'CMP019'
);


-- 4. Generar resumen mensual de calificaciones por empresa

-- Crear tabla de resumen si no existe
CREATE TABLE IF NOT EXISTS resumen_calificaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id VARCHAR(20),
    mes YEAR,
    mes_numero INT,
    promedio_rating DOUBLE,
    total_calificaciones INT,
    generado_en DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE PROCEDURE generar_resumen_mensual_calificaciones()
BEGIN
    -- Elimina los resúmenes del mes actual para evitar duplicados
    DELETE FROM resumen_calificaciones
    WHERE mes = YEAR(CURDATE()) AND mes_numero = MONTH(CURDATE());

    -- Inserta el resumen mensual por empresa
    INSERT INTO resumen_calificaciones (company_id, mes, mes_numero, promedio_rating, total_calificaciones)
    SELECT
        c.id AS company_id,
        YEAR(r.created_at) AS mes,
        MONTH(r.created_at) AS mes_numero,
        AVG(r.rating) AS promedio_rating,
        COUNT(*) AS total_calificaciones
    FROM companies c
    JOIN companyproducts cp ON cp.company_id = c.id
    JOIN rates r ON r.product_id = cp.product_id
    WHERE YEAR(r.created_at) = YEAR(CURDATE())
      AND MONTH(r.created_at) = MONTH(CURDATE())
    GROUP BY c.id, YEAR(r.created_at), MONTH(r.created_at);
END$$

DELIMITER ;

-- llamada del procedimiento almacenado 4
CALL generar_resumen_mensual_calificaciones();

-- comprobacion de el procedimiento almacenado 4
SELECT * FROM resumen_calificaciones WHERE mes = YEAR(CURDATE()) AND mes_numero = MONTH(CURDATE());


-- 5. Calcular beneficios activos por membresía


ALTER TABLE membershipperiods ADD COLUMN start_date DATE;

ALTER TABLE membershipperiods ADD COLUMN end_date DATE;

UPDATE membershipperiods
SET start_date = DATE_ADD('2025-01-01', INTERVAL FLOOR(RAND() * 180) DAY);


UPDATE membershipperiods
SET end_date = DATE_ADD(start_date, INTERVAL FLOOR(RAND() * 180) DAY);


DELIMITER $$
CREATE PROCEDURE beneficios_activos_por_membresia(IN p_membership_id INT)
BEGIN
    SELECT b.id, b.description, b.detail
    FROM membershipbenefits mb
    JOIN benefits b ON mb.benefit_id = b.id
    JOIN membershipperiods mp ON mp.membership_id = mb.membership_id
    WHERE mb.membership_id = p_membership_id
      AND CURDATE() BETWEEN mp.start_date AND mp.end_date;
END$$
DELIMITER ;

-- Llamada del procedimiento almacenado 5

CALL beneficios_activos_por_membresia(1);


-- 6. Eliminar productos huérfanos
DELIMITER $$
CREATE PROCEDURE eliminar_productos_huerfanos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT product_id FROM rates)
      AND id NOT IN (SELECT DISTINCT product_id FROM companyproducts)
      AND id NOT IN (SELECT DISTINCT product_id FROM details_favorites);
END$$
DELIMITER ;

--comprobacion de el procedimiento almacenado 6

SELECT * FROM products
WHERE id NOT IN (SELECT DISTINCT product_id FROM rates)
  AND id NOT IN (SELECT DISTINCT product_id FROM companyproducts)
  AND id NOT IN (SELECT DISTINCT product_id FROM details_favorites);

-- llamada del procedimiento almacenado 6:

CALL eliminar_productos_huerfanos();

-- revision de los productos sin relaciones eliminados

SELECT * FROM products;


-- 7. Actualizar precios de productos por categoría
DELIMITER $$
CREATE PROCEDURE actualizar_precios_por_categoria(IN p_categoria_id INT, IN p_factor DOUBLE)
BEGIN
    UPDATE companyproducts cp
    JOIN products p ON cp.product_id = p.id
    SET cp.price = cp.price * p_factor
    WHERE p.category_id = p_categoria_id;
END$$
DELIMITER ;

-- comprobacion de el procedimiento almacenado 7 antes de realizar la llamada 

SELECT * FROM companyproducts WHERE product_id IN (SELECT id FROM products WHERE categoryid = 2);

-- llamada del procedimiento almacenado 7

CALL actualizar_precios_por_categoria(2, 1.10);

-- comprobacion de el procedimiento almacenado 7 despues de realizar la llamada

SELECT * FROM companyproducts WHERE product_id IN (SELECT id FROM products WHERE categoryid = 2);


-- 8. Validar inconsistencia entre rates y quality_products

-- Creacion tabla de calidad de productos
CREATE TABLE quality_products (
    product_id INT PRIMARY KEY,
    quality_level VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Insertar o actualizar niveles de calidad basados en calificaciones

REPLACE INTO quality_products (product_id, quality_level)
SELECT
    p.id,
    CASE
        WHEN p.average_rating >= 4.5 THEN 'Alta'
        WHEN p.average_rating >= 3.0 THEN 'Media'
        WHEN p.average_rating > 0 THEN 'Baja'
        WHEN p.average_rating = 0 AND p.price >= 1000 THEN 'Alta'
        WHEN p.average_rating = 0 AND p.price >= 500 THEN 'Media'
        ELSE 'Baja'
    END AS quality_level
FROM products p;

DELIMITER $$
CREATE PROCEDURE validar_inconsistencias_rates_quality()
BEGIN
    INSERT INTO errores_log (error_desc)
    SELECT CONCAT('Rate sin quality_product: rate_id=', r.id)
    FROM rates r
    LEFT JOIN quality_products q ON r.product_id = q.product_id
    WHERE q.product_id IS NULL;
END$$
DELIMITER ;


-- Creacion tabla de errores
CREATE TABLE IF NOT EXISTS errores_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    error_desc VARCHAR(255),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- Llamada del procedimiento almacenado 8

CALL validar_inconsistencias_rates_quality();

-- comprobacion de el procedimiento almacenado 8

SELECT * FROM errores_log WHERE error_desc LIKE 'Rate sin quality_product%';


-- 9. Asignar beneficios a nuevas audiencias

DELIMITER $$
CREATE PROCEDURE asignar_beneficio_audiencia(IN p_benefit_id INT, IN p_audience_id INT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM audiencebenefits
        WHERE benefit_id = p_benefit_id AND audience_id = p_audience_id
    ) THEN
        INSERT INTO audiencebenefits (audience_id, benefit_id)
        VALUES (p_audience_id, p_benefit_id);
    END IF;
END$$
DELIMITER;

-- Llamada del procedimiento almacenado 9
CALL asignar_beneficio_audiencia(4, 3);

-- comprobacion de el procedimiento almacenado 9
SELECT * FROM audiencebenefits
WHERE audience_id = 3 AND benefit_id = 4;

-- 10. Activar planes de membresía vencidos con pago confirmado

ALTER TABLE membershipperiods ADD COLUMN status VARCHAR(20) DEFAULT 'INACTIVA';

DELIMITER $$
CREATE PROCEDURE activar_membresias_vencidas()
BEGIN
    UPDATE membershipperiods
    SET status = 'ACTIVA'
    WHERE end_date < CURDATE()
      AND status <> 'ACTIVA';
END$$
DELIMITER ;

-- Comprobación de el procedimiento almacenado 10 antes de la llamada

SELECT * FROM membershipperiods;

-- Llamada del procedimiento almacenado 10
CALL activar_membresias_vencidas();

-- Comprobación de el procedimiento almacenado 10 después de la llamada
SELECT * FROM membershipperiods WHERE status = 'ACTIVA';


-- 11. Listar productos favoritos del cliente con su calificación
DELIMITER $$
CREATE PROCEDURE favoritos_con_rating(IN p_customer_id INT)
BEGIN
    SELECT p.id AS product_id, p.name, AVG(r.rating) AS promedio_rating
    FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    JOIN products p ON df.product_id = p.id
    LEFT JOIN rates r ON r.product_id = p.id
    WHERE f.customer_id = p_customer_id
    GROUP BY p.id, p.name;
END$$
DELIMITER ;

-- Llamada del procedimiento almacenado 11

CALL favoritos_con_rating(21);



-- 12. Registrar encuesta y sus preguntas asociadas
-- Supone que recibes el título y un JSON con las preguntas

ALTER TABLE polls ADD COLUMN title VARCHAR(255) DEFAULT NULL;

ALTER TABLE polls ADD COLUMN status VARCHAR(20) DEFAULT 'activa';

CREATE TABLE IF NOT EXISTS poll_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    poll_id INT,
    question_text VARCHAR(255)
);

ALTER TABLE polls_companies DROP FOREIGN KEY polls_companies_ibfk_2;
ALTER TABLE pollproducts DROP FOREIGN KEY pollproducts_ibfk_1;
ALTER TABLE customerpollratings DROP FOREIGN KEY customerpollratings_ibfk_2;
ALTER TABLE category_poll_links DROP FOREIGN KEY category_poll_links_ibfk_3;

ALTER TABLE polls MODIFY COLUMN id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE polls_companies
ADD CONSTRAINT polls_companies_ibfk_2 FOREIGN KEY (poll_id) REFERENCES polls(id);

registrar_encuesta_con_preguntas(
    'Encuesta de Prueba Final',
    '[{"text":"¿Estás satisfecho con el servicio?"},{"text":"¿Volverías a usar la plataforma?"}]'
    );



-- 13. Eliminar favoritos antiguos sin calificaciones

-- para comprobar el funcionamiento de este procedimiento se realizan inserciones de prueba

INSERT INTO companies (id, name)
VALUES ('CMP900', 'Empresa Prueba');


INSERT INTO customers (id, name)
VALUES (900, 'Cliente Prueba');


INSERT INTO products (id, name)
VALUES
  (900, 'Producto sin calificación'),
  (901, 'Producto con calificación');


INSERT INTO favorites (id, customer_id, company_id, created_at)
VALUES (900, 900, 'CMP900', '2023-06-15');

INSERT INTO details_favorites (favorite_id, product_id)
VALUES
  (900, 900),  -- producto sin calificación
  (900, 901);  -- producto con calificación

INSERT INTO rates (id, product_id, customer_id, rating, created_at)
VALUES (900, 901, 900, 5, NOW());


DELIMITER $$
CREATE PROCEDURE eliminar_favoritos_antiguos_sin_calificacion()
BEGIN
    DELETE df FROM details_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    LEFT JOIN rates r ON df.product_id = r.product_id AND f.customer_id = r.customer_id
    WHERE r.id IS NULL
      AND f.created_at < DATE_SUB(CURDATE(), INTERVAL 12 MONTH);
END$$
DELIMITER ;


-- Verificar antes del procedimiento
SELECT * FROM details_favorites;

-- llamada del procedimiento almacenado 13
CALL eliminar_favoritos_antiguos_sin_calificacion();

-- Verificar después del procedimiento
SELECT * FROM favorites WHERE id = 900;
SELECT * FROM details_favorites WHERE favorite_id = 900;



-- 14. Asociar beneficios automáticamente por audiencia
DELIMITER $$
CREATE PROCEDURE asociar_beneficios_por_audiencia(IN p_audience_id INT)
BEGIN
    INSERT IGNORE INTO audiencebenefits (audience_id, benefit_id)
    SELECT p_audience_id, b.id
    FROM benefits b
    WHERE NOT EXISTS (
        SELECT 1 FROM audiencebenefits ab
        WHERE ab.audience_id = p_audience_id AND ab.benefit_id = b.id
    );
END$$
DELIMITER ;

-- Llamada del procedimiento almacenado 14
CALL asociar_beneficios_por_audiencia(2);

-- Comprobación de el procedimiento almacenado 14
SELECT * FROM audiencebenefits WHERE audience_id = 2;


-- 15. Historial de cambios de precio
CREATE TABLE IF NOT EXISTS historial_precios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    old_price DOUBLE,
    new_price DOUBLE,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE PROCEDURE registrar_cambio_precio(
    IN p_product_id INT,
    IN p_new_price DOUBLE
)
BEGIN
    DECLARE v_old_price DOUBLE;
    SELECT price INTO v_old_price FROM products WHERE id = p_product_id;
    IF v_old_price <> p_new_price THEN
        INSERT INTO historial_precios (product_id, old_price, new_price)
        VALUES (p_product_id, v_old_price, p_new_price);
        UPDATE products SET price = p_new_price WHERE id = p_product_id;
    END IF;
END$$
DELIMITER ;

-- Verifica el precio actual del producto con id = 1
SELECT id, name, price FROM products WHERE id = 1;

-- Verifica si ya hay cambios registrados en el historial
SELECT * FROM historial_precios WHERE product_id = 1 ORDER BY id DESC;

-- Llamada del procedimiento almacenado 15
CALL registrar_cambio_precio(1, 99.99);

-- Verifica el historial de cambios de precio después de la llamada
SELECT * FROM historial_precios WHERE product_id = 1 ORDER BY id DESC;


-- 16. Registrar encuesta activa automáticamente
DELIMITER $$
CREATE PROCEDURE registrar_encuesta_activa(IN p_title VARCHAR(100))
BEGIN
    INSERT INTO polls (title, status, created_at)
    VALUES (p_title, 'activa', NOW());
END$$
DELIMITER ;

-- Comprobación de el procedimiento almacenado 16 antes de la llamada

SELECT * FROM polls;

-- Llamada del procedimiento almacenado 16
CALL registrar_encuesta_activa('Encuesta Feedback General');

-- comprobacion de el procedimiento almacenado 16 despues de la llamada

SELECT * FROM polls;


-- 17. Actualizar unidad de medida de productos sin afectar ventas
DELIMITER $$
CREATE PROCEDURE actualizar_unidad_si_no_ventas(
    IN p_product_id INT,
    IN p_unit_id INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sales WHERE product_id = p_product_id
    ) THEN
        UPDATE products SET unit_id = p_unit_id WHERE id = p_product_id;
    END IF;
END$$
DELIMITER ;

-- Comprobación de el procedimiento almacenado 17 antes de la llamada
SELECT id, name, unit_id FROM products;

-- Llamada del procedimiento almacenado 17
CALL actualizar_unidad_si_no_ventas(1, 2);

-- Comprobación de el procedimiento almacenado 17 después de la llamada
SELECT id, name, unit_id FROM products LIMIT 10;


-- 18. Recalcular promedios de calidad semanalmente

DELIMITER $$
CREATE PROCEDURE recalcular_promedios_calidad()
BEGIN
    UPDATE products p
    SET average_rating = (
        SELECT AVG(r.rating) FROM rates r WHERE r.product_id = p.id
    );
END$$
DELIMITER ;

-- comprobacion de el procedimiento almacenado 18 antes de la llamada
SELECT id, average_rating FROM products;

-- Llamada del procedimiento almacenado 18
CALL recalcular_promedios_calidad();

-- comprobacion de el procedimiento almacenado 18 despues de la llamada
SELECT id, average_rating FROM products;


-- 19. Validar claves foráneas entre calificaciones y encuestas

-- se realiza inserciones de prueba para comprobar el funcionamiento del procedimiento almacenado

INSERT INTO rates (customer_id, product_id, poll_id, rating) VALUES
(1, 1, 1, 4.0),       
(2, 2, 4, 3.5),       
(900, 900, 999, 2.0),
(1, 1, NULL, 5.0);  


DELIMITER $$
CREATE PROCEDURE validar_claves_rates_polls()
BEGIN
    INSERT INTO errores_log (error_desc)
    SELECT CONCAT('Rate con poll_id inexistente: rate_id=', r.id)
    FROM rates r
    LEFT JOIN polls p ON r.poll_id = p.id
    WHERE r.poll_id IS NOT NULL AND p.id IS NULL;
END$$
DELIMITER ;

-- Llamada del procedimiento almacenado 19
CALL validar_claves_rates_polls();


-- Comprobación de el procedimiento almacenado 19 después de la llamada
SELECT * FROM errores_log;



-- 20. Generar el top 10 de productos más calificados por ciudad
DELIMITER $$
CREATE PROCEDURE top10_productos_calificados_por_ciudad(IN p_city_code VARCHAR(6))
BEGIN
    SELECT p.id AS product_id, p.name, COUNT(r.id) AS total_calificaciones
    FROM products p
    JOIN companyproducts cp ON cp.product_id = p.id
    JOIN companies c ON c.id = cp.company_id
    JOIN rates r ON r.product_id = p.id
    WHERE c.city_id = p_city_code
    GROUP BY p.id, p.name
    ORDER BY total_calificaciones DESC
    LIMIT 10;
END$$
DELIMITER ;

-- Llamada del procedimiento almacenado 20

CALL top10_productos_calificados_por_ciudad('11001');

