-- 1 registrar una nueva calificacion y actualziar el promedio

ALTER TABLE product ADD COLUMN average_rating FLOAT DOUBLE DEFAULT 0;

CREATE TABLE IF NOT EXISTS rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    rating DOUBLE DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(id),
    FOREIGN KEY (customer_id) REFERENCES customer(id)
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