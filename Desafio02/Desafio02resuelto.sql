--Primer ejercicio agregando nombres y categorias 
CREATE OR REPLACE VIEW vista_peliculas_info AS
SELECT
    f.film_id,
    f.title AS nombre_pelicula,

    -- Concatenar nombres de actores
    (
        SELECT GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ')
        FROM film_actor fa
        JOIN actor a ON fa.actor_id = a.actor_id
        WHERE fa.film_id = f.film_id
    ) AS actores,

    -- Concatenar categorías
   (
        SELECT GROUP_CONCAT(c.name SEPARATOR ', ')
        FROM film_category fc
        JOIN category c ON fc.category_id = c.category_id
        WHERE fc.film_id = f.film_id
    ) AS categorias, 

    -- Ciudad y país de la tienda
ci.city AS ciudad,
    co.country AS pais

FROM film f
JOIN inventory i ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY f.film_id, s.store_id;

--Segundo ejercicio corregido 
CREATE OR REPLACE VIEW vista_ganancias_pelicula_tienda AS
SELECT
    s.store_id,
    f.film_id,
    f.title AS nombre_pelicula,
    CONCAT(ci.city, ', ', co.country) AS tienda_ubicacion,
    SUM(p.amount) AS total_ganancias
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY s.store_id, f.film_id, ci.city, co.country;



--Tercer ejercicio corregido 

DELIMITER $$

CREATE PROCEDURE sp_generar_compra (
    IN p_film_id INT,
    IN p_customer_id INT,
    IN p_staff_id INT,
    OUT p_payment_id INT,
    OUT p_total_out DECIMAL(5,2)
)
BEGIN
    DECLARE v_inventory_id INT;
    DECLARE v_rental_id INT;
    DECLARE v_amount DECIMAL(5,2);
    DECLARE v_payment_date DATETIME;

    -- Obtener un inventory_id disponible para esa película
    SELECT inventory_id
    INTO v_inventory_id
    FROM inventory
    WHERE film_id = p_film_id
    LIMIT 1;

    -- Validar que haya inventario
    IF v_inventory_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay inventario disponible para esta película.';
    END IF;

    -- Insertar en rental
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    VALUES (NOW(), v_inventory_id, p_customer_id, NULL, p_staff_id);

    SET v_rental_id = LAST_INSERT_ID();

    -- Obtener el precio (rental_rate) de la película
    SELECT rental_rate INTO v_amount
    FROM film
    WHERE film_id = p_film_id;

    SET v_payment_date = NOW();

    -- Insertar en payment
    INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
    VALUES (p_customer_id, p_staff_id, v_rental_id, v_amount, v_payment_date);

    -- Devolver valores por OUT
    SET p_payment_id = LAST_INSERT_ID();
    SET p_total_out = v_amount;
END$$

DELIMITER ;

-- Declarar las variables
SET @id_compra = 0;
SET @total_pago = 0;

-- Ejecutar el procedimiento
CALL sp_generar_compra(7, 3, 1, @id_compra, @total_pago);

-- Ver el resultado
SELECT @id_compra AS id_compra, @total_pago AS total_pagado;

--Para ver los resultados se utilizó

SELECT * FROM vista_peliculas_info; --para ver las peliculas con la info
SELECT * FROM `vista_ganancias_pelicula_tienda` --para ver las ganancias de las peliculas 

