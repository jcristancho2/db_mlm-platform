-- 1. Productos cuyo precio está por encima del promedio de su categoría
SELECT p.name, p.price
FROM products p
WHERE p.price > (
    SELECT AVG(price) FROM products WHERE category_id = p.category_id
);

-- 2. Empresas que tienen más productos que la media de empresas
SELECT co.name, COUNT(cp.product_id) AS total_productos
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY co.id
HAVING total_productos > (
    SELECT AVG(productos_por_empresa) FROM (
        SELECT COUNT(cp2.product_id) AS productos_por_empresa
        FROM companies co2
        JOIN companyproducts cp2 ON co2.id = cp2.company_id
        GROUP BY co2.id
    ) sub
);

-- 3. Mis productos favoritos que han sido calificados por otros clientes
SELECT p.name
FROM favorites f
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
WHERE EXISTS (
    SELECT 1 FROM customerpollratings cr
    JOIN pollproducts pp ON cr.poll_id = pp.poll_id
    WHERE pp.product_id = p.id AND cr.customer_id <> f.customer_id
);

-- 4. Productos con el mayor número de veces añadidos como favoritos
SELECT p.name, COUNT(df.favorite_id) AS veces_favorito
FROM products p
JOIN details_favorites df ON p.id = df.product_id
GROUP BY p.id
HAVING veces_favorito = (
    SELECT MAX(favoritos) FROM (
        SELECT COUNT(df2.favorite_id) AS favoritos
        FROM details_favorites df2
        GROUP BY df2.product_id
    ) sub
);

-- 5. Clientes cuyo correo no aparece en rates ni en quality_products
SELECT cu.name, cu.email
FROM customers cu
WHERE cu.email NOT IN (
    SELECT cu2.email FROM customerpollratings cr
    JOIN customers cu2 ON cr.customer_id = cu2.id
)
AND cu.email NOT IN (
    SELECT cu3.email FROM quality_products qp
    JOIN customers cu3 ON qp.customer_id = cu3.id
);

-- 6. Productos con una calificación inferior al mínimo de su categoría
SELECT p.name, AVG(cr.rating) AS promedio
FROM products p
JOIN pollproducts pp ON p.id = pp.product_id
JOIN customerpollratings cr ON pp.poll_id = cr.poll_id
GROUP BY p.id
HAVING promedio < (
    SELECT MIN(avg_rating) FROM (
        SELECT AVG(cr2.rating) AS avg_rating
        FROM products p2
        JOIN pollproducts pp2 ON p2.id = pp2.product_id
        JOIN customerpollratings cr2 ON pp2.poll_id = cr2.poll_id
        WHERE p2.category_id = p.category_id
        GROUP BY p2.id
    ) sub
);

-- 7. Ciudades que no tienen clientes registrados
SELECT c.name
FROM citiesormunicipalities c
WHERE c.code NOT IN (
    SELECT city_id FROM customers
);

-- 8. Productos que no han sido evaluados en ninguna encuesta
SELECT p.name
FROM products p
WHERE p.id NOT IN (
    SELECT product_id FROM pollproducts
);

-- 9. Beneficios que no están asignados a ninguna audiencia
SELECT b.description
FROM benefits b
WHERE b.id NOT IN (
    SELECT benefit_id FROM audiencebenefits
);

-- 10. Mis productos favoritos que no están disponibles actualmente en ninguna empresa
SELECT p.name
FROM favorites f
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
WHERE p.id NOT IN (
    SELECT product_id FROM companyproducts
)
AND f.customer_id = 29;

-- 11. Productos vendidos en empresas cuya ciudad tiene menos de tres empresas registradas
SELECT p.name
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies co ON cp.company_id = co.id
WHERE co.city_id IN (
    SELECT city_id FROM companies
    GROUP BY city_id
    HAVING COUNT(id) < 3
);

-- 12. Productos con calidad superior al promedio de todos los productos
SELECT p.name, AVG(qp.quality_score) AS promedio_calidad
FROM products p
JOIN quality_products qp ON p.id = qp.product_id
GROUP BY p.id
HAVING promedio_calidad > (
    SELECT AVG(quality_score) FROM quality_products
);

-- 13. Empresas que sólo venden productos de una única categoría
SELECT co.name
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
JOIN products p ON cp.product_id = p.id
GROUP BY co.id
HAVING COUNT(DISTINCT p.category_id) = 1;

-- 14. Productos con el mayor precio entre todas las empresas
SELECT p.name, MAX(cp.price) AS precio_maximo
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
GROUP BY p.id;

-- 15. Algún producto de mis favoritos calificado por otro cliente con más de 4 estrellas
SELECT p.name
FROM favorites f
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
WHERE EXISTS (
    SELECT 1 FROM customerpollratings cr
    JOIN pollproducts pp ON cr.poll_id = pp.poll_id
    WHERE pp.product_id = p.id AND cr.customer_id <> f.customer_id AND cr.rating > 4
)
AND f.customer_id = 30;

-- 16. Productos sin imagen asignada pero sí han sido calificados
SELECT p.name
FROM products p
JOIN pollproducts pp ON p.id = pp.product_id
JOIN customerpollratings cr ON pp.poll_id = cr.poll_id
WHERE p.image IS NULL OR p.image = '';

-- 17. Planes de membresía sin periodo vigente
SELECT m.name
FROM memberships m
WHERE m.id NOT IN (
    SELECT membership_id FROM membershipperiods WHERE CURDATE() BETWEEN start_date AND end_date
);

-- 18. Beneficios compartidos por más de una audiencia
SELECT b.description
FROM benefits b
JOIN audiencebenefits ab ON b.id = ab.benefit_id
GROUP BY b.id
HAVING COUNT(ab.audience_id) > 1;

-- 19. Empresas cuyos productos no tienen unidad de medida definida
SELECT co.name
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
WHERE cp.unitmeasure_id IS NULL
GROUP BY co.id;

-- 20. Clientes con membresía activa y sin productos favoritos
SELECT cu.name
FROM customers cu
WHERE EXISTS (
    SELECT 1 FROM membershipperiods mp
    WHERE mp.customer_id = cu.id AND CURDATE() BETWEEN mp.start_date AND mp.end_date
)
AND cu.id NOT IN (
    SELECT customer_id FROM favorites
);