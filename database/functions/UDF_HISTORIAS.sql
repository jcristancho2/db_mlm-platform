-- 1. Promedio ponderado de calidad de un producto (más peso a calificaciones recientes)
DELIMITER $$
CREATE FUNCTION promedio_ponderado_calidad(producto INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE resultado DOUBLE;
    SELECT SUM(rating * POW(0.95, DATEDIFF(NOW(), created_at))) / SUM(POW(0.95, DATEDIFF(NOW(), created_at)))
    INTO resultado
    FROM rates
    WHERE product_id = producto;
    RETURN resultado;
END$$
DELIMITER ;

-- 2. ¿Una calificación es reciente? (últimos 30 días)
DELIMITER $$
CREATE FUNCTION es_calificacion_reciente(fecha DATETIME)
RETURNS BOOLEAN
DETERMINISTIC
RETURN fecha >= DATE_SUB(NOW(), INTERVAL 30 DAY);
$$
DELIMITER ;

-- 3. Nombre de la empresa que vende un producto
DELIMITER $$
CREATE FUNCTION obtener_empresa_producto(pid INT)
RETURNS VARCHAR(80)
DETERMINISTIC
RETURN (
    SELECT co.name
    FROM companyproducts cp
    JOIN companies co ON cp.company_id = co.id
    WHERE cp.product_id = pid
    LIMIT 1
);
$$
DELIMITER ;

-- 4. ¿Cliente tiene membresía activa?
DELIMITER $$
CREATE FUNCTION tiene_membresia_activa(cid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
    SELECT 1 FROM membershipperiods
    WHERE customer_id = cid AND CURDATE() BETWEEN start_date AND end_date
);
$$
DELIMITER ;

-- 5. ¿Ciudad supera X empresas?
DELIMITER $$
CREATE FUNCTION ciudad_supera_empresas(city VARCHAR(6), limite INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN (
    (SELECT COUNT(*) FROM companies WHERE city_id = city) > limite
);
$$
DELIMITER ;

-- 6. Descripción textual de la calificación
DELIMITER $$
CREATE FUNCTION descripcion_calificacion(valor DOUBLE)
RETURNS VARCHAR(20)
DETERMINISTIC
RETURN (
    CASE
        WHEN valor >= 4.5 THEN 'Excelente'
        WHEN valor >= 4 THEN 'Muy bueno'
        WHEN valor >= 3 THEN 'Bueno'
        WHEN valor >= 2 THEN 'Regular'
        ELSE 'Deficiente'
    END
);
$$
DELIMITER ;

-- 7. Estado de un producto según su promedio de calificaciones
DELIMITER $$
CREATE FUNCTION estado_producto(pid INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE prom DOUBLE;
    SELECT AVG(rating) INTO prom FROM rates WHERE product_id = pid;
    RETURN (
        CASE
            WHEN prom >= 4.5 THEN 'Óptimo'
            WHEN prom >= 3 THEN 'Aceptable'
            ELSE 'Crítico'
        END
    );
END$$
DELIMITER ;

-- 8. ¿Es favorito?
DELIMITER $$
CREATE FUNCTION es_favorito(cid INT, pid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
    SELECT 1 FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    WHERE f.customer_id = cid AND df.product_id = pid
);
$$
DELIMITER ;

-- 9. ¿Beneficio asignado a audiencia?
DELIMITER $$
CREATE FUNCTION beneficio_asignado_audiencia(benefit INT, audience INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
    SELECT 1 FROM audiencebenefits
    WHERE benefit_id = benefit AND audience_id = audience
);
$$
DELIMITER ;

-- 10. ¿Fecha dentro de membresía activa?
DELIMITER $$
CREATE FUNCTION fecha_en_membresia(fecha DATE, cid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
    SELECT 1 FROM membershipperiods
    WHERE customer_id = cid AND fecha BETWEEN start_date AND end_date
);
$$
DELIMITER ;

-- 11. Porcentaje de calificaciones positivas de un producto
DELIMITER $$
CREATE FUNCTION porcentaje_positivas(pid INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE total INT;
    DECLARE positivas INT;
    SELECT COUNT(*) INTO total FROM rates WHERE product_id = pid;
    SELECT COUNT(*) INTO positivas FROM rates WHERE product_id = pid AND rating >= 4;
    IF total = 0 THEN RETURN 0; END IF;
    RETURN (positivas / total) * 100;
END$$
DELIMITER ;

-- 12. Edad de una calificación en días
DELIMITER $$
CREATE FUNCTION edad_calificacion(fecha DATETIME)
RETURNS INT
DETERMINISTIC
RETURN DATEDIFF(CURRENT_DATE, fecha);
$$
DELIMITER ;

-- 13. Cantidad de productos únicos por empresa
DELIMITER $$
CREATE FUNCTION productos_por_empresa(cid VARCHAR(20))
RETURNS INT
DETERMINISTIC
RETURN (
    SELECT COUNT(DISTINCT product_id) FROM companyproducts WHERE company_id = cid
);
$$
DELIMITER ;

-- 14. Nivel de actividad de un cliente
DELIMITER $$
CREATE FUNCTION nivel_actividad_cliente(cid INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM rates WHERE customer_id = cid;
    RETURN (
        CASE
            WHEN total >= 10 THEN 'Frecuente'
            WHEN total >= 3 THEN 'Esporádico'
            ELSE 'Inactivo'
        END
    );
END$$
DELIMITER ;

-- 15. Precio promedio ponderado de un producto (por favoritos)
DELIMITER $$
CREATE FUNCTION precio_promedio_ponderado(pid INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE total INT;
    DECLARE suma DOUBLE;
    SELECT COUNT(*) INTO total FROM details_favorites WHERE product_id = pid;
    SELECT SUM(p.price) INTO suma FROM details_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    JOIN products p ON df.product_id = p.id
    WHERE df.product_id = pid;
    IF total = 0 THEN RETURN 0; END IF;
    RETURN suma / total;
END$$
DELIMITER ;

-- 16. ¿Beneficio asignado a más de una audiencia o membresía?
DELIMITER $$
CREATE FUNCTION beneficio_mas_de_una(benefit INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN (
    (SELECT COUNT(*) FROM audiencebenefits WHERE benefit_id = benefit) +
    (SELECT COUNT(*) FROM membershipbenefits WHERE benefit_id = benefit)
) > 1;
$$
DELIMITER ;

-- 17. Índice de variedad de una ciudad (empresas * productos)
DELIMITER $$
CREATE FUNCTION indice_variedad_ciudad(city VARCHAR(6))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE empresas INT;
    DECLARE productos INT;
    SELECT COUNT(*) INTO empresas FROM companies WHERE city_id = city;
    SELECT COUNT(DISTINCT cp.product_id) INTO productos
    FROM companies co
    JOIN companyproducts cp ON co.id = cp.company_id
    WHERE co.city_id = city;
    RETURN empresas * productos;
END$$
DELIMITER ;

-- 18. ¿Producto debe ser desactivado por baja calificación?
DELIMITER $$
CREATE FUNCTION desactivar_producto(pid INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE prom DOUBLE;
    SELECT AVG(rating) INTO prom FROM rates WHERE product_id = pid;
    RETURN prom < 2.5;
END$$
DELIMITER ;

-- 19. Índice de popularidad de un producto (favoritos + ratings)
DELIMITER $$
CREATE FUNCTION indice_popularidad(pid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE favs INT;
    DECLARE rats INT;
    SELECT COUNT(*) INTO favs FROM details_favorites WHERE product_id = pid;
    SELECT COUNT(*) INTO rats FROM rates WHERE product_id = pid;
    RETURN favs + rats;
END$$
DELIMITER ;

-- 20. Código único basado en nombre y fecha de creación
DELIMITER $$
CREATE FUNCTION codigo_unico_producto(pid INT)
RETURNS VARCHAR(100)
DETERMINISTIC
RETURN (
    SELECT CONCAT(LEFT(name,3), '_', DATE_FORMAT(created_at, '%Y%m%d'))
    FROM products WHERE id = pid
);
$$
DELIMITER ;

-- comprobacion de las historias de usuario

SELECT promedio_ponderado_calidad(1);
SELECT es_calificacion_reciente(NOW());
SELECT obtener_empresa_producto(1);
SELECT tiene_membresia_activa(1);
SELECT ciudad_supera_empresas('08001', 2);
SELECT descripcion_calificacion(4.2);
SELECT estado_producto(1);
SELECT es_favorito(1, 1);
SELECT beneficio_asignado_audiencia(1, 1);
SELECT fecha_en_membresia(CURDATE(), 1);
SELECT porcentaje_positivas(1);
SELECT edad_calificacion(NOW());
SELECT productos_por_empresa('9001');
SELECT nivel_actividad_cliente(1);
SELECT precio_promedio_ponderado(1);
SELECT beneficio_mas_de_una(1);
SELECT indice_variedad_ciudad('08001');
SELECT desactivar_producto(1);
SELECT indice_popularidad(1);
SELECT codigo_unico_producto(1);
