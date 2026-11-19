-- ============================================================
-- Zoilo's Bites & Go Management System
-- MySQL schema generated from the ERD (Crow's Foot notation)
-- ============================================================

DROP DATABASE IF EXISTS zoilos_bites_and_go;
CREATE DATABASE zoilos_bites_and_go
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE zoilos_bites_and_go;

-- ------------------------------------------------------------
-- OWNER
-- ------------------------------------------------------------
CREATE TABLE owner (
    owner_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    owner_name  VARCHAR(100) NOT NULL,
    position    VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL,
    PRIMARY KEY (owner_id),
    UNIQUE KEY uq_owner_email (email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- STAFF  (OWNER employs STAFF: 1 : many)
-- ------------------------------------------------------------
CREATE TABLE staff (
    staff_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_name  VARCHAR(100) NOT NULL,
    owner_id    INT UNSIGNED NOT NULL,
    PRIMARY KEY (staff_id),
    CONSTRAINT fk_staff_owner
        FOREIGN KEY (owner_id) REFERENCES owner (owner_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PRODUCT  (OWNER manages PRODUCT: 1 : many)
-- ------------------------------------------------------------
CREATE TABLE product (
    product_id    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    product_name  VARCHAR(100)  NOT NULL,
    product_type  VARCHAR(50)   NOT NULL,
    price         DECIMAL(10,2) NOT NULL,
    owner_id      INT UNSIGNED  NOT NULL,
    PRIMARY KEY (product_id),
    CONSTRAINT chk_product_price CHECK (price >= 0),
    CONSTRAINT fk_product_owner
        FOREIGN KEY (owner_id) REFERENCES owner (owner_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- CUSTOMER
-- ------------------------------------------------------------
CREATE TABLE customer (
    customer_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_name    VARCHAR(100) NOT NULL,
    address          VARCHAR(255) NULL,
    contact_number   VARCHAR(20)  NULL,
    customer_group   VARCHAR(50)  NULL,
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- CUSTOMER_ORDER  (CUSTOMER places CUSTOMER_ORDER: 1 : many)
-- ------------------------------------------------------------
CREATE TABLE customer_order (
    order_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_date    DATE         NOT NULL,
    order_time    TIME         NOT NULL,
    order_status  VARCHAR(20)  NOT NULL DEFAULT 'Pending',
    customer_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (order_id),
    CONSTRAINT chk_order_status
        CHECK (order_status IN ('Pending', 'Completed', 'Cancelled')),
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ORDER_ITEM  (resolves CUSTOMER_ORDER many : many PRODUCT)
-- ------------------------------------------------------------
CREATE TABLE order_item (
    order_id    INT UNSIGNED NOT NULL,
    product_id  INT UNSIGNED NOT NULL,
    quantity    INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_order_item_qty CHECK (quantity > 0),
    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id) REFERENCES customer_order (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_item_product
        FOREIGN KEY (product_id) REFERENCES product (product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- DAILY_CLOSING
-- ------------------------------------------------------------
CREATE TABLE daily_closing (
    closing_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    closing_date    DATE          NOT NULL,
    total_sales     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_expenses  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (closing_id),
    UNIQUE KEY uq_closing_date (closing_date)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- EXPENSE  (DAILY_CLOSING lists EXPENSE: 1 : many)
-- ------------------------------------------------------------
CREATE TABLE expense (
    expense_id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    expense_description  VARCHAR(255)  NOT NULL,
    expense_amount       DECIMAL(10,2) NOT NULL,
    closing_id           INT UNSIGNED  NOT NULL,
    PRIMARY KEY (expense_id),
    CONSTRAINT chk_expense_amount CHECK (expense_amount >= 0),
    CONSTRAINT fk_expense_closing
        FOREIGN KEY (closing_id) REFERENCES daily_closing (closing_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- SALE
--   CUSTOMER_ORDER produces SALE : 1 : 1  (UNIQUE order_id)
--   DAILY_CLOSING  totals   SALE : 1 : many
-- ------------------------------------------------------------
CREATE TABLE sale (
    sale_id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    amount          DECIMAL(10,2) NOT NULL,
    payment_status  VARCHAR(20)   NOT NULL DEFAULT 'Unpaid',
    order_id        INT UNSIGNED  NOT NULL,
    closing_id      INT UNSIGNED  NOT NULL,
    PRIMARY KEY (sale_id),
    UNIQUE KEY uq_sale_order (order_id),
    CONSTRAINT chk_sale_amount CHECK (amount >= 0),
    CONSTRAINT chk_sale_payment
        CHECK (payment_status IN ('Unpaid', 'Paid', 'Partial')),
    CONSTRAINT fk_sale_order
        FOREIGN KEY (order_id) REFERENCES customer_order (order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sale_closing
        FOREIGN KEY (closing_id) REFERENCES daily_closing (closing_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- STOCK_ITEM
-- ------------------------------------------------------------
CREATE TABLE stock_item (
    stock_item_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    item_name      VARCHAR(100) NOT NULL,
    minimum_level  INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (stock_item_id),
    UNIQUE KEY uq_stock_item_name (item_name)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- STOCK_CHECK
-- ------------------------------------------------------------
CREATE TABLE stock_check (
    check_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    check_date  DATE         NOT NULL,
    PRIMARY KEY (check_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- STOCK_CHECK_DETAIL  (resolves STOCK_CHECK many : many STOCK_ITEM)
-- ------------------------------------------------------------
CREATE TABLE stock_check_detail (
    check_id       INT UNSIGNED NOT NULL,
    stock_item_id  INT UNSIGNED NOT NULL,
    quantity_left  INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (check_id, stock_item_id),
    CONSTRAINT fk_scd_check
        FOREIGN KEY (check_id) REFERENCES stock_check (check_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_scd_stock_item
        FOREIGN KEY (stock_item_id) REFERENCES stock_item (stock_item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Helpful indexes for common lookups
-- ------------------------------------------------------------
CREATE INDEX idx_order_date     ON customer_order (order_date);
CREATE INDEX idx_order_status   ON customer_order (order_status);
CREATE INDEX idx_sale_closing   ON sale (closing_id);
CREATE INDEX idx_expense_closing ON expense (closing_id);
