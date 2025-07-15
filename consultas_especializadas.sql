-- 1. Productos con empresa asociada y precio más bajo por ciudad
SELECT c.name AS ciudad, co.name AS empresa, p.name AS producto, MIN(cp.price) AS precio_minimo
FROM companyproducts cp
JOIN companies co ON cp.company_id = co.id
JOIN products p ON cp.product_id = p.id
JOIN citiesormunicipalities c ON co.city_id = c.code
GROUP BY c.name, co.name, p.name;

-- 2. Top 5 clientes que más productos han calificado en los últimos 6 meses
SELECT cu.name AS cliente, cu.email, COUNT(*) AS total_calificaciones
FROM customerpollratings cr
JOIN customers cu ON cr.customer_id = cu.id
WHERE cr.daterating >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY cu.id
ORDER BY total_calificaciones DESC
LIMIT 5;

-- 3. Distribución de productos por categoría y unidad de medida
SELECT cat.description AS categoria, um.description AS unidad_medida, COUNT(cp.product_id) AS cantidad_productos
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
JOIN categories cat ON p.category_id = cat.id
JOIN unitofmeasure um ON cp.unitmeasure_id = um.id
GROUP BY cat.description, um.description;

-- 4. Productos con calificaciones superiores al promedio general
SELECT p.name AS producto, AVG(cr.rating) AS promedio_producto
FROM customerpollratings cr
JOIN products p ON cr.poll_id IN (SELECT poll_id FROM pollproducts WHERE product_id = p.id)
GROUP BY p.id
HAVING promedio_producto > (SELECT AVG(rating) FROM customerpollratings);

-- 5. Empresas que no han recibido ninguna calificación
SELECT co.name AS empresa, co.email
FROM companies co
LEFT JOIN polls_companies pc ON co.id = pc.company_id
LEFT JOIN customerpollratings cr ON pc.poll_id = cr.poll_id
WHERE cr.poll_id IS NULL;

-- 6. Productos añadidos como favoritos por más de 10 clientes distintos
SELECT p.name AS producto, COUNT(DISTINCT f.customer_id) AS total_clientes
FROM details_favorites df
JOIN favorites f ON df.favorite_id = f.id
JOIN products p ON df.product_id = p.id
GROUP BY p.id
HAVING total_clientes > 10;

-- 7. Empresas activas por ciudad y categoría
SELECT c.name AS ciudad, cat.description AS categoria, co.name AS empresa
FROM companies co
JOIN citiesormunicipalities c ON co.city_id = c.code
JOIN categories cat ON co.category_id = cat.id
WHERE co.status = 'ACTIVA'
GROUP BY c.name, cat.description, co.name;

-- 8. Los 10 productos más calificados en cada ciudad
SELECT ci.name AS ciudad, p.name AS producto, COUNT(cr.rating) AS total_calificaciones
FROM customerpollratings cr
JOIN products p ON cr.poll_id IN (SELECT poll_id FROM pollproducts WHERE product_id = p.id)
JOIN companies co ON EXISTS (SELECT 1 FROM companyproducts cp WHERE cp.product_id = p.id AND cp.company_id = co.id)
JOIN citiesormunicipalities ci ON co.city_id = ci.code
GROUP BY ci.name, p.id
ORDER BY ci.name, total_calificaciones DESC
LIMIT 10;

-- 9. Productos sin unidad de medida asignada
SELECT p.name AS producto, co.name AS empresa
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
JOIN companies co ON cp.company_id = co.id
WHERE cp.unitmeasure_id IS NULL;

-- 10. Planes de membresía sin beneficios registrados
SELECT m.name AS membresia
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id
WHERE mb.benefit_id IS NULL;

-- 11. Productos de una categoría específica con su promedio de calificación
SELECT p.name AS producto, AVG(cr.rating) AS promedio_calificacion
FROM products p
JOIN customerpollratings cr ON cr.poll_id IN (SELECT poll_id FROM pollproducts WHERE product_id = p.id)
WHERE p.category_id = ? -- Reemplaza ? por el id de la categoría deseada
GROUP BY p.id;

-- 12. Clientes que han comprado productos de más de una empresa
SELECT cu.name AS cliente, cu.email, COUNT(DISTINCT cp.company_id) AS empresas_distintas
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN companyproducts cp ON df.product_id = cp.product_id
GROUP BY cu.id
HAVING empresas_distintas > 1;

-- 13. Ciudades con más clientes activos
SELECT c.name AS ciudad, COUNT(cu.id) AS clientes_activos
FROM citiesormunicipalities c
JOIN customers cu ON cu.city_id = c.code
GROUP BY c.code
ORDER BY clientes_activos DESC;

-- 14. Ranking de productos por empresa basado en la media de quality_products
SELECT co.name AS empresa, p.name AS producto, AVG(qp.quality_score) AS promedio_calidad
FROM companyproducts cp
JOIN companies co ON cp.company_id = co.id
JOIN products p ON cp.product_id = p.id
JOIN quality_products qp ON qp.product_id = p.id
GROUP BY co.id, p.id
ORDER BY co.name, promedio_calidad DESC;

-- 15. Empresas que ofrecen más de cinco productos distintos
SELECT co.name AS empresa, COUNT(DISTINCT cp.product_id) AS productos_ofrecidos
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY co.id
HAVING productos_ofrecidos > 5;

-- 16. Productos favoritos que aún no han sido calificados
SELECT cu.name AS cliente, p.name AS producto
FROM favorites f
JOIN customers cu ON f.customer_id = cu.id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
LEFT JOIN customerpollratings cr ON cr.customer_id = cu.id AND cr.poll_id IN (SELECT poll_id FROM pollproducts WHERE product_id = p.id)
WHERE cr.rating IS NULL;

-- 17. Beneficios asignados a cada audiencia junto con su descripción
SELECT a.description AS audiencia, b.description AS beneficio, b.detail
FROM audiencebenefits ab
JOIN audiences a ON ab.audience_id = a.id
JOIN benefits b ON ab.benefit_id = b.id;

-- 18. Ciudades con empresas sin productos asociados
SELECT c.name AS ciudad, co.name AS empresa
FROM companies co
JOIN citiesormunicipalities c ON co.city_id = c.code
LEFT JOIN companyproducts cp ON co.id = cp.company_id
WHERE cp.product_id IS NULL;

-- 19. Empresas con productos duplicados por nombre
SELECT co.name AS empresa, p.name AS producto, COUNT(*) AS duplicados
FROM companyproducts cp
JOIN companies co ON cp.company_id = co.id
JOIN products p ON cp.product_id = p.id
GROUP BY co.id, p.name
HAVING duplicados > 1;

-- 20. Vista resumen de clientes, productos favoritos y promedio de calificación recibido
SELECT cu.name AS cliente, p.name AS producto_favorito, AVG(cr.rating) AS promedio_calificacion
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
LEFT JOIN customerpollratings cr ON cr.poll_id IN (SELECT poll_id FROM pollproducts WHERE product_id = p.id)
GROUP BY cu.id, p.id;