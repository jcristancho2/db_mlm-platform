
CREATE DATABASE mlm_platform;

USE mlm_platform;


CREATE TABLE IF NOT EXISTS countries (
    isocode VARCHAR(6) PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    alfaitwo VARCHAR(2) UNIQUE,
    alfaisothree VARCHAR(4) UNIQUE
);

CREATE TABLE IF NOT EXISTS subdivisioncategories (
    id INT PRIMARY KEY,
    description VARCHAR(40) UNIQUE
);

CREATE TABLE IF NOT EXISTS stateregions (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    country_id VARCHAR(6),
    codeust16 VARCHAR(10) UNIQUE,
    subdivision_id INT,
    FOREIGN KEY (country_id) REFERENCES countries(isocode),
    FOREIGN KEY (subdivision_id) REFERENCES subdivisioncategories(id)
);

CREATE TABLE IF NOT EXISTS citiesormunicipalities (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(100) UNIQUE,
    statereg_id VARCHAR(6),
    FOREIGN KEY (statereg_id) REFERENCES stateregions(code)
);

CREATE TABLE IF NOT EXISTS typesidentifications (
    id INT PRIMARY KEY,
    description VARCHAR(60),
    sufix VARCHAR(5),
    UNIQUE(description, sufix)
);

CREATE TABLE IF NOT EXISTS audiences (
    id INT PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS categories (
    id INT PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS unitofmeasure (
    id INT PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(20) PRIMARY KEY,
    type_id INT,
    name VARCHAR(80) UNIQUE,
    category_id INT,
    city_id VARCHAR(6),
    audience_id INT,
    cellphone VARCHAR(15),
    email VARCHAR(80),
    status VARCHAR(20) DEFAULT 'ACTIVA',
    FOREIGN KEY (type_id) REFERENCES typesidentifications(id),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);

CREATE TABLE IF NOT EXISTS customers (
    id INT PRIMARY KEY,
    name VARCHAR(80),
    city_id VARCHAR(6),
    audience_id INT,
    cellphone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    address VARCHAR(120),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);

CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    detail TEXT,
    price  DOUBLE DEFAULT 0,
    category_id INT,
    unit_id INT,
    average_rating DOUBLE DEFAULT 0,
    image VARCHAR(80),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS companyproducts (
    company_id VARCHAR(20),
    product_id INT,
    price  DOUBLE DEFAULT 0 DEFAULT 0,
    unitmeasure_id INT NOT NULL,
    PRIMARY KEY (company_id, product_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (unitmeasure_id) REFERENCES unitofmeasure(id)
);

CREATE TABLE IF NOT EXISTS favorites (
    id INT PRIMARY KEY,
    customer_id INT,
    company_id VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);

CREATE TABLE IF NOT EXISTS details_favorites (
    favorite_id INT,
    product_id INT,
    PRIMARY KEY (favorite_id, product_id),
    FOREIGN KEY (favorite_id) REFERENCES favorites(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS polls (
    id INT PRIMARY KEY,
    name VARCHAR(80) UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories_polls (
    id INT PRIMARY KEY,
    name VARCHAR(80) UNIQUE
);

CREATE TABLE IF NOT EXISTS polls_companies (
    company_id VARCHAR(20),
    poll_id INT,
    PRIMARY KEY (company_id, poll_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS pollproducts (
    poll_id INT,
    product_id INT,
    PRIMARY KEY (poll_id, product_id),
    FOREIGN KEY (poll_id) REFERENCES polls(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS customerpollratings (
    customer_id INT,
    poll_id INT,
    daterating DATETIME,
    rating  DOUBLE DEFAULT 0,
    PRIMARY KEY (customer_id, poll_id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS category_poll_links (
    company_id VARCHAR(20),
    categorypoll_id INT,
    poll_id INT,
    daterating DATETIME,
    rating  DOUBLE DEFAULT 0,
    PRIMARY KEY (company_id, categorypoll_id, poll_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (categorypoll_id) REFERENCES categories_polls(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS memberships (
    id INT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS periods (
    id INT PRIMARY KEY,
    name VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS membershipperiods (
    membership_id INT NOT NULL,
    period_id INT NOT NULL,
    customer_id INT NOT NULL,
    price DOUBLE DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'INACTIVA',
    PRIMARY KEY (membership_id, period_id, customer_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (period_id) REFERENCES periods(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);


CREATE TABLE IF NOT EXISTS benefits (
    id INT PRIMARY KEY,
    description VARCHAR(80),
    detail TEXT
);

CREATE TABLE IF NOT EXISTS membershipbenefits (
    membership_id INT,
    benefit_id INT,
    PRIMARY KEY (membership_id, benefit_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);

CREATE TABLE IF NOT EXISTS audiencebenefits (
    audience_id INT,
    benefit_id INT,
    PRIMARY KEY (audience_id, benefit_id),
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);


CREATE TABLE IF NOT EXISTS quality_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT,
    quality_level VARCHAR(10) NOT NULL CHECK (
        LOWER(quality_level) IN ('alta', 'media', 'baja')
    ),
    evaluated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    quality_score DOUBLE DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    poll_id INT,
    rating DOUBLE CHECK (rating BETWEEN 0 AND 5),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATETIME DEFAULT CURRENT_TIMESTAMP
);
