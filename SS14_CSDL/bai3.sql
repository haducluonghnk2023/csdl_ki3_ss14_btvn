CREATE DATABASE ss14_first;
USE ss14_first;
-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- cau 2
DELIMITER //
CREATE PROCEDURE sp_create_order(
    IN customer_id INT,
    IN product_id INT,
    IN quantity INT,
    IN price DECIMAL(10,2)
)
BEGIN
    DECLARE stock INT;
    DECLARE orderID INT;
    START TRANSACTION;
    SELECT stock_quantity INTO stock FROM inventory WHERE product_id = product_id;
    IF stock < quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không đủ hàng trong kho!';
        ROLLBACK;
    ELSE
        INSERT INTO orders (customer_id, order_date, total_amount, status)
        VALUES (customer_id, NOW(), 0, 'Pending');
        SET orderID = LAST_INSERT_ID();
        INSERT INTO order_items (order_id, product_id, quantity, price)
        VALUES (orderID, product_id, quantity, price);
        UPDATE inventory SET stock_quantity = stock_quantity - quantity WHERE product_id = product_id;
        COMMIT;
    END IF;
END //
DELIMITER ;
-- cau 3
DELIMITER //
CREATE PROCEDURE sp_payment_order(
    IN order_id INT,
    IN payment_method VARCHAR(20)
)
BEGIN
    DECLARE order_status ENUM('Pending', 'Completed', 'Cancelled');
    DECLARE total_amount DECIMAL(10,2);
    START TRANSACTION;
    SELECT status, total_amount INTO order_status, total_amount FROM orders WHERE order_id = order_id;
    IF order_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ có thể thanh toán đơn hàng ở trạng thái Pending!';
        ROLLBACK;
    ELSE
        INSERT INTO payments (order_id, payment_date, amount, payment_method, status)
        VALUES (order_id, NOW(), total_amount, payment_method, 'Completed');
        UPDATE orders SET status = 'Completed' WHERE order_id = order_id;
        COMMIT;
    END IF;
END //
DELIMITER ;
-- cau 4
DELIMITER //
CREATE PROCEDURE sp_cancel_order(
    IN order_id INT
)
BEGIN
    DECLARE order_status ENUM('Pending', 'Completed', 'Cancelled');
    START TRANSACTION;
    SELECT status INTO order_status FROM orders WHERE order_id = order_id;
    IF order_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ có thể hủy đơn hàng ở trạng thái Pending!';
        ROLLBACK;
    ELSE
        UPDATE inventory i
        JOIN order_items oi ON i.product_id = oi.product_id
        SET i.stock_quantity = i.stock_quantity + oi.quantity
        WHERE oi.order_id = order_id;
        DELETE FROM order_items WHERE order_id = order_id;
        UPDATE orders SET status = 'Cancelled' WHERE order_id = order_id;
        COMMIT;
    END IF;
END //
DELIMITER ;

-- cau 5
DROP PROCEDURE IF EXISTS sp_create_order;
DROP PROCEDURE IF EXISTS sp_payment_order;
DROP PROCEDURE IF EXISTS sp_cancel_order;
