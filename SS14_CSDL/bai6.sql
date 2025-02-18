CREATE DATABASE ss14_second;
USE ss14_second;
-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
) engine = 'InnoDB';
drop table employees;
-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);
drop table salaries;
-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
) ;
drop table salary_history;
-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);
-- cau 2
DELIMITER $$
CREATE TRIGGER check_phone_length_before_update
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.phone) != 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có 10 chữ số';
    END IF;
END $$
DELIMITER ;
-- cau 3
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);
-- cau 4
DELIMITER $$
CREATE TRIGGER create_welcome_notification
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO notifications (employee_id, message)
    VALUES (NEW.employee_id, 'Chào mừng');
END $$
DELIMITER ;
-- cau 5
set autocommit = 0;
DELIMITER $$
CREATE PROCEDURE AddNewEmployeeWithPhone(
    IN emp_name VARCHAR(255),
    IN emp_email VARCHAR(255),
    IN emp_phone VARCHAR(20),
    IN emp_hire_date DATE,
    IN emp_department_id INT
)
BEGIN
    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
    END;
    START TRANSACTION;
    IF (SELECT COUNT(*) FROM employees WHERE email = emp_email) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email đã tồn tại';
    END IF;
    IF LENGTH(emp_phone) != 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có 10 chữ số';
    END IF;
    INSERT INTO employees (name, email, phone, hire_date, department_id)
		VALUES (emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);
    INSERT INTO notifications (employee_id, message)
		VALUES (LAST_INSERT_ID(), 'Chào mừng');
    COMMIT;
END $$
DELIMITER ;
--
CALL AddNewEmployeeWithPhone('Nguyen Van A', 'nguyenvana@example.com', '0912345678', '2025-02-19', 1);
select * from employees;
select * from notifications;



