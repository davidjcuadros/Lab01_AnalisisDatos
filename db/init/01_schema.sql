-- PostgreSQL Schema (converted from MySQL)
-- VERSION WITHOUT PostGIS - uses POINT type instead of GEOMETRY

-- Disable constraints temporarily
SET CONSTRAINTS ALL DEFERRED;

-- Create sequences for auto-increment
CREATE SEQUENCE actor_actor_id_seq;
CREATE SEQUENCE language_language_id_seq;
CREATE SEQUENCE category_category_id_seq;
CREATE SEQUENCE country_country_id_seq;
CREATE SEQUENCE city_city_id_seq;
CREATE SEQUENCE address_address_id_seq;
CREATE SEQUENCE film_film_id_seq;
CREATE SEQUENCE store_store_id_seq;
CREATE SEQUENCE customer_customer_id_seq;
CREATE SEQUENCE inventory_inventory_id_seq;
CREATE SEQUENCE payment_payment_id_seq;
CREATE SEQUENCE rental_rental_id_seq;
CREATE SEQUENCE staff_staff_id_seq;

-- Actor table
CREATE TABLE actor (
  actor_id SMALLINT NOT NULL DEFAULT nextval('actor_actor_id_seq'),
  first_name VARCHAR(45) NOT NULL,
  last_name VARCHAR(45) NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (actor_id)
);

CREATE INDEX idx_actor_last_name ON actor(last_name);

-- Trigger for auto-update timestamp
CREATE OR REPLACE FUNCTION update_last_update_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.last_update = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_actor_last_update BEFORE UPDATE ON actor
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Language table
CREATE TABLE language (
  language_id SMALLINT NOT NULL DEFAULT nextval('language_language_id_seq'),
  name CHAR(20) NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (language_id)
);

CREATE TRIGGER update_language_last_update BEFORE UPDATE ON language
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Category table
CREATE TABLE category (
  category_id SMALLINT NOT NULL DEFAULT nextval('category_category_id_seq'),
  name VARCHAR(25) NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_id)
);

CREATE TRIGGER update_category_last_update BEFORE UPDATE ON category
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Country table
CREATE TABLE country (
  country_id SMALLINT NOT NULL DEFAULT nextval('country_country_id_seq'),
  country VARCHAR(50) NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (country_id)
);

CREATE TRIGGER update_country_last_update BEFORE UPDATE ON country
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- City table
CREATE TABLE city (
  city_id SMALLINT NOT NULL DEFAULT nextval('city_city_id_seq'),
  city VARCHAR(50) NOT NULL,
  country_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (city_id),
  CONSTRAINT fk_city_country FOREIGN KEY (country_id) 
    REFERENCES country (country_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_country_id ON city(country_id);

CREATE TRIGGER update_city_last_update BEFORE UPDATE ON city
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Address table
-- Note: location field is TEXT to accept MySQL GEOMETRY data

-- If you need PostGIS, convert TEXT to GEOMETRY after data import
CREATE TABLE address (
  address_id SMALLINT NOT NULL DEFAULT nextval('address_address_id_seq'),
  address VARCHAR(50) NOT NULL,
  address2 VARCHAR(50) DEFAULT NULL,
  district VARCHAR(50) NOT NULL,  -- Changed from VARCHAR(20) to VARCHAR(50)
  city_id SMALLINT NOT NULL,
  postal_code VARCHAR(10) DEFAULT NULL,
  phone VARCHAR(20) NOT NULL DEFAULT '',  -- Added DEFAULT ''
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (address_id),
  CONSTRAINT fk_address_city FOREIGN KEY (city_id) 
    REFERENCES city (city_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_city_id ON address(city_id);

CREATE TRIGGER update_address_last_update BEFORE UPDATE ON address
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Film table
CREATE TABLE film (
  film_id SMALLINT NOT NULL DEFAULT nextval('film_film_id_seq'),
  title VARCHAR(128) NOT NULL,
  description TEXT DEFAULT NULL,
  release_year INTEGER DEFAULT NULL,
  language_id SMALLINT NOT NULL,
  original_language_id SMALLINT DEFAULT NULL,
  rental_duration SMALLINT NOT NULL DEFAULT 3,
  rental_rate DECIMAL(4,2) NOT NULL DEFAULT 4.99,
  length SMALLINT DEFAULT NULL,
  replacement_cost DECIMAL(5,2) NOT NULL DEFAULT 19.99,
  rating VARCHAR(10) DEFAULT 'G' CHECK (rating IN ('G','PG','PG-13','R','NC-17')),
  special_features TEXT DEFAULT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id),
  CONSTRAINT fk_film_language FOREIGN KEY (language_id) 
    REFERENCES language (language_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_film_language_original FOREIGN KEY (original_language_id) 
    REFERENCES language (language_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE INDEX idx_title ON film(title);
CREATE INDEX idx_fk_language_id ON film(language_id);
CREATE INDEX idx_fk_original_language_id ON film(original_language_id);

CREATE TRIGGER update_film_last_update BEFORE UPDATE ON film
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Staff table (created before store due to circular dependency)
CREATE TABLE staff (
  staff_id SMALLINT NOT NULL DEFAULT nextval('staff_staff_id_seq'),
  first_name VARCHAR(45) NOT NULL,
  last_name VARCHAR(45) NOT NULL,
  address_id SMALLINT NOT NULL,
  picture BYTEA DEFAULT NULL,
  email VARCHAR(50) DEFAULT NULL,
  store_id SMALLINT NOT NULL,
  active SMALLINT NOT NULL DEFAULT 1,
  username VARCHAR(16) NOT NULL,
  password VARCHAR(40) DEFAULT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (staff_id)
);

-- Store table
CREATE TABLE store (
  store_id SMALLINT NOT NULL DEFAULT nextval('store_store_id_seq'),
  manager_staff_id SMALLINT NOT NULL,
  address_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (store_id),
  CONSTRAINT fk_store_staff FOREIGN KEY (manager_staff_id) 
    REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_store_address FOREIGN KEY (address_id) 
    REFERENCES address (address_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX idx_unique_manager ON store(manager_staff_id);
CREATE INDEX idx_fk_address_id ON store(address_id);

CREATE TRIGGER update_store_last_update BEFORE UPDATE ON store
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Add foreign keys to staff table
ALTER TABLE staff
  ADD CONSTRAINT fk_staff_store FOREIGN KEY (store_id) 
    REFERENCES store (store_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT fk_staff_address FOREIGN KEY (address_id) 
    REFERENCES address (address_id) ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX idx_fk_store_id ON staff(store_id);
CREATE INDEX idx_fk_address_id_staff ON staff(address_id);

CREATE TRIGGER update_staff_last_update BEFORE UPDATE ON staff
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Customer table
CREATE TABLE customer (
  customer_id SMALLINT NOT NULL DEFAULT nextval('customer_customer_id_seq'),
  store_id SMALLINT NOT NULL,
  first_name VARCHAR(45) NOT NULL,
  last_name VARCHAR(45) NOT NULL,
  email VARCHAR(50) DEFAULT NULL,
  address_id SMALLINT NOT NULL,
  active SMALLINT NOT NULL DEFAULT 1,
  create_date TIMESTAMP NOT NULL,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  CONSTRAINT fk_customer_address FOREIGN KEY (address_id) 
    REFERENCES address (address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_customer_store FOREIGN KEY (store_id) 
    REFERENCES store (store_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_store_id_customer ON customer(store_id);
CREATE INDEX idx_fk_address_id_customer ON customer(address_id);
CREATE INDEX idx_last_name ON customer(last_name);

CREATE TRIGGER update_customer_last_update BEFORE UPDATE ON customer
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Film_actor table
CREATE TABLE film_actor (
  actor_id SMALLINT NOT NULL,
  film_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (actor_id, film_id),
  CONSTRAINT fk_film_actor_actor FOREIGN KEY (actor_id) 
    REFERENCES actor (actor_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_film_actor_film FOREIGN KEY (film_id) 
    REFERENCES film (film_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_film_id ON film_actor(film_id);

CREATE TRIGGER update_film_actor_last_update BEFORE UPDATE ON film_actor
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Film_category table
CREATE TABLE film_category (
  film_id SMALLINT NOT NULL,
  category_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id, category_id),
  CONSTRAINT fk_film_category_film FOREIGN KEY (film_id) 
    REFERENCES film (film_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_film_category_category FOREIGN KEY (category_id) 
    REFERENCES category (category_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TRIGGER update_film_category_last_update BEFORE UPDATE ON film_category
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Inventory table
CREATE TABLE inventory (
  inventory_id INTEGER NOT NULL DEFAULT nextval('inventory_inventory_id_seq'),
  film_id SMALLINT NOT NULL,
  store_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (inventory_id),
  CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) 
    REFERENCES store (store_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) 
    REFERENCES film (film_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_film_id_inventory ON inventory(film_id);
CREATE INDEX idx_store_id_film_id ON inventory(store_id, film_id);

CREATE TRIGGER update_inventory_last_update BEFORE UPDATE ON inventory
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Rental table
CREATE TABLE rental (
  rental_id INTEGER NOT NULL DEFAULT nextval('rental_rental_id_seq'),
  rental_date TIMESTAMP NOT NULL,
  inventory_id INTEGER NOT NULL,
  customer_id SMALLINT NOT NULL,
  return_date TIMESTAMP DEFAULT NULL,
  staff_id SMALLINT NOT NULL,
  last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (rental_id),
  CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) 
    REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_rental_inventory FOREIGN KEY (inventory_id) 
    REFERENCES inventory (inventory_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_rental_customer FOREIGN KEY (customer_id) 
    REFERENCES customer (customer_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX idx_rental_unique ON rental(rental_date, inventory_id, customer_id);
CREATE INDEX idx_fk_inventory_id ON rental(inventory_id);
CREATE INDEX idx_fk_customer_id ON rental(customer_id);
CREATE INDEX idx_fk_staff_id_rental ON rental(staff_id);

CREATE TRIGGER update_rental_last_update BEFORE UPDATE ON rental
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();

-- Payment table
CREATE TABLE payment (
  payment_id SMALLINT NOT NULL DEFAULT nextval('payment_payment_id_seq'),
  customer_id SMALLINT NOT NULL,
  staff_id SMALLINT NOT NULL,
  rental_id INTEGER DEFAULT NULL,
  amount DECIMAL(5,2) NOT NULL,
  payment_date TIMESTAMP NOT NULL,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payment_rental FOREIGN KEY (rental_id) 
    REFERENCES rental (rental_id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) 
    REFERENCES customer (customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) 
    REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_fk_staff_id_payment ON payment(staff_id);
CREATE INDEX idx_fk_customer_id_payment ON payment(customer_id);

CREATE TRIGGER update_payment_last_update BEFORE UPDATE ON payment
FOR EACH ROW EXECUTE FUNCTION update_last_update_column();