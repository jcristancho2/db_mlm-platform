

-- 1. Obtener el promedio de calificación por producto
CREATE OR REPLACE VIEW promedio_calificacion_por_producto AS
SELECT product_id, AVG(rating) AS promedio
FROM rates
GROUP BY product_id;

-- 2. Contar cuántos productos ha calificado cada cliente
CREATE OR REPLACE VIEW productos_calificados_por_cliente AS
SELECT customer_id, COUNT(DISTINCT product_id) AS total_calificados
FROM rates
GROUP BY customer_id;

-- 3. Sumar el total de beneficios asignados por audiencia
CREATE OR REPLACE VIEW total_beneficios_por_audiencia AS
SELECT audience_id, COUNT(*) AS total_beneficios
FROM audiencebenefits
GROUP BY audience_id;

-- 4. Calcular la media de productos por empresa
CREATE OR REPLACE VIEW media_productos_por_empresa AS
SELECT AVG(productos) AS media
FROM (
    SELECT company_id, COUNT(*) AS productos
    FROM companyproducts
    GROUP BY company_id
) sub;

-- 5. Contar el total de empresas por ciudad
CREATE OR REPLACE VIEW total_empresas_por_ciudad AS
SELECT city_id, COUNT(*) AS total_empresas
FROM companies
GROUP BY city_id;

-- 6. Calcular el promedio de precios por unidad de medida
CREATE OR REPLACE VIEW promedio_precio_por_unidad AS
SELECT unitmeasure_id, AVG(price) AS promedio_precio
FROM companyproducts
GROUP BY unitmeasure_id;

-- 7. Contar cuántos clientes hay por ciudad
CREATE OR REPLACE VIEW total_clientes_por_ciudad AS
SELECT city_id, COUNT(*) AS total_clientes
FROM customers
GROUP BY city_id;

-- 8. Calcular planes de membresía por periodo
CREATE OR REPLACE VIEW planes_membresia_por_periodo AS
SELECT period_id, COUNT(*) AS total_planes
FROM membershipperiods
GROUP BY period_id;

-- 9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos
CREATE OR REPLACE VIEW promedio_calificaciones_favoritos_cliente AS
SELECT f.customer_id, AVG(r.rating) AS promedio
FROM favorites f
JOIN details_favorites df ON f.id = df.favorite_id
JOIN rates r ON df.product_id = r.product_id AND f.customer_id = r.customer_id
GROUP BY f.customer_id;

-- 10. Consultar la fecha más reciente en que se calificó un producto
CREATE OR REPLACE VIEW fecha_ultima_calificacion_producto AS
SELECT product_id, MAX(created_at) AS ultima_calificacion
FROM rates
GROUP BY product_id;

-- 11. Obtener la desviación estándar de precios por categoría
CREATE OR REPLACE VIEW desviacion_precio_por_categoria AS
SELECT p.category_id, STDDEV(cp.price) AS desviacion
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
GROUP BY p.category_id;

-- 12. Contar cuántas veces un producto fue favorito
CREATE OR REPLACE VIEW veces_producto_favorito AS
SELECT product_id, COUNT(*) AS veces_favorito
FROM details_favorites
GROUP BY product_id;

-- 13. Calcular el porcentaje de productos evaluados
CREATE OR REPLACE VIEW porcentaje_productos_evaluados AS
SELECT 
    (SELECT COUNT(DISTINCT product_id) FROM rates) / (SELECT COUNT(*) FROM products) * 100 AS porcentaje_evaluados;

-- 14. Ver el promedio de rating por encuesta
CREATE OR REPLACE VIEW promedio_rating_por_encuesta AS
SELECT poll_id, AVG(rating) AS promedio
FROM rates
GROUP BY poll_id;

-- 15. Calcular el promedio y total de beneficios por plan
CREATE OR REPLACE VIEW promedio_total_beneficios_por_plan AS
SELECT membership_id, COUNT(*) AS total_beneficios
FROM membershipbenefits
GROUP BY membership_id;

-- 16. Obtener media y varianza de precios por empresa
CREATE OR REPLACE VIEW media_varianza_precio_por_empresa AS
SELECT company_id, AVG(price) AS media, VARIANCE(price) AS varianza
FROM companyproducts
GROUP BY company_id;

-- 17. Ver total de productos disponibles en la ciudad del cliente
CREATE OR REPLACE VIEW total_productos_por_ciudad_cliente AS
SELECT cu.id AS customer_id, cu.city_id, COUNT(DISTINCT cp.product_id) AS total_productos
FROM customers cu
JOIN companies co ON cu.city_id = co.city_id
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY cu.id, cu.city_id;

-- 18. Contar productos únicos por tipo de empresa
CREATE OR REPLACE VIEW productos_unicos_por_tipo_empresa AS
SELECT co.type_id, COUNT(DISTINCT cp.product_id) AS total_productos
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY co.type_id;

-- 19. Ver total de clientes sin correo electrónico registrado
CREATE OR REPLACE VIEW total_clientes_sin_email AS
SELECT COUNT(*) AS total_sin_email
FROM customers
WHERE email IS NULL;

-- 20. Empresa con más productos calificados
CREATE OR REPLACE VIEW empresa_mas_productos_calificados AS
SELECT co.id AS company_id, co.name, COUNT(DISTINCT r.product_id) AS productos_calificados
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
JOIN rates r ON cp.product_id = r.product_id
GROUP BY co.id, co.name
ORDER BY productos_calificados DESC
LIMIT 1;


-- PARA COMPROBAR SI LAS FUNCIONES AGREGADAS ESTAN ALMACENADAS EN LA BASE DE DATOS 

SHOW FULL TABLES IN mlm_platform WHERE TABLE_TYPE = 'VIEW';

-- VISUALIZAR EL RESULTADO DE CADA FUNCION AGREGADA

-- 1. Promedio de calificación por producto
SELECT * FROM promedio_calificacion_por_producto;

-- 2. Total de productos calificados por cliente
SELECT * FROM productos_calificados_por_cliente;

-- 3. Total de beneficios asignados por audiencia
SELECT * FROM total_beneficios_por_audiencia;

-- 4. Media de productos por empresa
SELECT * FROM media_productos_por_empresa;

-- 5. Total de empresas por ciudad
SELECT * FROM total_empresas_por_ciudad;

-- 6. Promedio de precios por unidad de medida
SELECT * FROM promedio_precio_por_unidad;

-- 7. Total de clientes por ciudad
SELECT * FROM total_clientes_por_ciudad;

-- 8. Total de planes de membresía por periodo
SELECT * FROM planes_membresia_por_periodo;

-- 9. Promedio de calificaciones a productos favoritos por cliente
SELECT * FROM promedio_calificaciones_favoritos_cliente;

-- 10. Fecha más reciente de calificación de cada producto
SELECT * FROM fecha_ultima_calificacion_producto;

-- 11. Desviación estándar del precio por categoría
SELECT * FROM desviacion_precio_por_categoria;

-- 12. Veces que un producto fue añadido como favorito
SELECT * FROM veces_producto_favorito;

-- 13. Porcentaje de productos evaluados
SELECT * FROM porcentaje_productos_evaluados;

-- 14. Promedio de rating por encuesta
SELECT * FROM promedio_rating_por_encuesta;

-- 15. Total de beneficios por plan de membresía
SELECT * FROM promedio_total_beneficios_por_plan;

-- 16. Media y varianza de precios por empresa
SELECT * FROM media_varianza_precio_por_empresa;

-- 17. Total de productos disponibles en la ciudad del cliente
SELECT * FROM total_productos_por_ciudad_cliente;

-- 18. Total de productos únicos por tipo de empresa
SELECT * FROM productos_unicos_por_tipo_empresa;

-- 19. Total de clientes sin email registrado
SELECT * FROM total_clientes_sin_email;

-- 20. Empresa con más productos calificados
SELECT * FROM empresa_mas_productos_calificados;


