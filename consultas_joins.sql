-- 1. Ver productos con la empresa que los vende
SELECT co.name AS empresa, p.name AS producto, cp.price
FROM companyproducts cp
JOIN companies co ON cp.company_id = co.id
JOIN products p ON cp.product_id = p.id;

-- 2. Mostrar productos favoritos con su empresa y categoría
SELECT cu.name AS cliente, p.name AS producto, co.name AS empresa, cat.description AS categoria
FROM favorites f
JOIN customers cu ON f.customer_id = cu.id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies co ON cp.company_id = co.id
JOIN categories cat ON p.category_id = cat.id;

-- 3. Ver empresas aunque no tengan productos
SELECT co.name AS empresa, p.name AS producto
FROM companies co
LEFT JOIN companyproducts cp ON co.id = cp.company_id
LEFT JOIN products p ON cp.product_id = p.id;

-- 4. Ver productos que fueron calificados (o no)
SELECT p.name AS producto, cr.rating
FROM products p
LEFT JOIN pollproducts pp ON p.id = pp.product_id
LEFT JOIN customerpollratings cr ON pp.poll_id = cr.poll_id;

-- 5. Ver productos con promedio de calificación y empresa
SELECT co.name AS empresa, p.name AS producto, AVG(cr.rating) AS promedio_calificacion
FROM companyproducts cp
JOIN companies co ON cp.company_id = co.id
JOIN products p ON cp.product_id = p.id
LEFT JOIN pollproducts pp ON p.id = pp.product_id
LEFT JOIN customerpollratings cr ON pp.poll_id = cr.poll_id
GROUP BY co.name, p.name;

-- 6. Ver clientes y sus calificaciones (si las tienen)
SELECT cu.name AS cliente, cr.rating
FROM customers cu
LEFT JOIN customerpollratings cr ON cu.id = cr.customer_id;

-- 7. Ver favoritos con la última calificación del cliente
SELECT cu.name AS cliente, p.name AS producto, cr.rating, cr.daterating
FROM favorites f
JOIN customers cu ON f.customer_id = cu.id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
LEFT JOIN customerpollratings cr ON cr.customer_id = cu.id AND cr.poll_id IN (
    SELECT poll_id FROM pollproducts WHERE product_id = p.id
)
WHERE cr.daterating = (
    SELECT MAX(cr2.daterating)
    FROM customerpollratings cr2
    WHERE cr2.customer_id = cu.id AND cr2.poll_id IN (
        SELECT poll_id FROM pollproducts WHERE product_id = p.id
    )
);

-- 8. Ver beneficios incluidos en cada plan de membresía
SELECT m.name AS membresia, b.description AS beneficio
FROM memberships m
JOIN membershipbenefits mb ON m.id = mb.membership_id
JOIN benefits b ON mb.benefit_id = b.id;

-- 9. Ver clientes con membresía activa y sus beneficios
SELECT cu.name AS cliente, m.name AS membresia, b.description AS beneficio
FROM customers cu
JOIN memberships m ON cu.id = m.id -- Ajusta si hay tabla intermedia cliente-membresía
JOIN membershipperiods mp ON m.id = mp.membership_id
JOIN membershipbenefits mb ON m.id = mb.membership_id
JOIN benefits b ON mb.benefit_id = b.id
WHERE mp.period_id IN (
    SELECT id FROM periods WHERE CURDATE() BETWEEN start_date AND end_date
);

-- 10. Ver ciudades con cantidad de empresas
SELECT c.name AS ciudad, COUNT(co.id) AS total_empresas
FROM citiesormunicipalities c
LEFT JOIN companies co ON c.code = co.city_id
GROUP BY c.name;

-- 11. Ver encuestas con calificaciones
SELECT p.name AS encuesta, cr.rating
FROM polls p
LEFT JOIN customerpollratings cr ON p.id = cr.poll_id;

-- 12. Ver productos evaluados con datos del cliente
SELECT cu.name AS cliente, p.name AS producto, cr.daterating
FROM customerpollratings cr
JOIN pollproducts pp ON cr.poll_id = pp.poll_id
JOIN products p ON pp.product_id = p.id
JOIN customers cu ON cr.customer_id = cu.id;

-- 13. Ver productos con audiencia de la empresa
SELECT p.name AS producto, a.description AS audiencia
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies co ON cp.company_id = co.id
JOIN audiences a ON co.audience_id = a.id;

-- 14. Ver clientes con sus productos favoritos
SELECT cu.name AS cliente, p.name AS producto
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id;

-- 15. Ver planes, periodos, precios y beneficios
SELECT m.name AS membresia, pr.name AS periodo, mp.price, b.description AS beneficio
FROM memberships m
JOIN membershipperiods mp ON m.id = mp.membership_id
JOIN periods pr ON mp.period_id = pr.id
JOIN membershipbenefits mb ON m.id = mb.membership_id
JOIN benefits b ON mb.benefit_id = b.id;

-- 16. Ver combinaciones empresa-producto-cliente calificados
SELECT co.name AS empresa, p.name AS producto, cu.name AS cliente, cr.rating
FROM customerpollratings cr
JOIN pollproducts pp ON cr.poll_id = pp.poll_id
JOIN products p ON pp.product_id = p.id
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies co ON cp.company_id = co.id
JOIN customers cu ON cr.customer_id = cu.id;

-- 17. Comparar favoritos con productos calificados
SELECT cu.name AS cliente, p.name AS producto
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
JOIN pollproducts pp ON p.id = pp.product_id
JOIN customerpollratings cr ON cr.poll_id = pp.poll_id AND cr.customer_id = cu.id;

-- 18. Ver productos ordenados por categoría
SELECT cat.description AS categoria, p.name AS producto
FROM categories cat
JOIN products p ON cat.id = p.category_id
ORDER BY cat.description, p.name;

-- 19. Ver beneficios por audiencia, incluso vacíos
SELECT a.description AS audiencia, b.description AS beneficio
FROM audiences a
LEFT JOIN audiencebenefits ab ON a.id = ab.audience_id
LEFT JOIN benefits b ON ab.benefit_id = b.id;

-- 20. Ver datos cruzados entre calificaciones, encuestas, productos y clientes
SELECT cu.name AS cliente, p.name AS producto, po.name AS encuesta, cr.rating
FROM customerpollratings cr
JOIN customers cu ON cr.customer_id = cu.id
JOIN pollproducts pp ON cr.poll_id = pp.poll_id
JOIN products p ON pp.product_id = p.id
JOIN polls po ON cr.poll_id = po.id;