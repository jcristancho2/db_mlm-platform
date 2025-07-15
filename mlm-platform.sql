
CREATE DATABASE mlm_platform;

USE mlm_platform;


CREATE TABLE IF NOT EXISTS countries (
    isocode VARCHAR(6) PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    alfaitwo VARCHAR(2) UNIQUE,
    alfaisothree VARCHAR(4) UNIQUE
);

CREATE TABLE IF NOT EXISTS subdivisioncategories (
    id INTEGER PRIMARY KEY,
    description VARCHAR(40) UNIQUE
);

CREATE TABLE IF NOT EXISTS stateregions (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    country_id VARCHAR(6),
    codeust16 VARCHAR(10) UNIQUE,
    subdivision_id INTEGER,
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
    id INTEGER PRIMARY KEY,
    description VARCHAR(60),
    sufix VARCHAR(5),
    UNIQUE(description, sufix)
);

CREATE TABLE IF NOT EXISTS audiences (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS unitofmeasure (
    id INTEGER PRIMARY KEY,
    description VARCHAR(60) UNIQUE
);

CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(20) PRIMARY KEY,
    type_id INTEGER,
    name VARCHAR(80) UNIQUE,
    category_id INTEGER,
    city_id VARCHAR(6),
    audience_id INTEGER,
    cellphone VARCHAR(15),
    email VARCHAR(80),
    FOREIGN KEY (type_id) REFERENCES typesidentifications(id),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);

CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80),
    city_id VARCHAR(6),
    audience_id INTEGER,
    cellphone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    address VARCHAR(120),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code),
    FOREIGN KEY (audience_id) REFERENCES audiences(id)
);

CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    detail TEXT,
    price DOUBLE,
    category_id INTEGER,
    image VARCHAR(80),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS companyproducts (
    company_id VARCHAR(20),
    product_id INTEGER,
    price DOUBLE,
    unitmeasure_id INTEGER,
    PRIMARY KEY (company_id, product_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (unitmeasure_id) REFERENCES unitofmeasure(id)
);

CREATE TABLE IF NOT EXISTS favorites (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    company_id VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);

CREATE TABLE IF NOT EXISTS details_favorites (
    favorite_id INTEGER,
    product_id INTEGER,
    PRIMARY KEY (favorite_id, product_id),
    FOREIGN KEY (favorite_id) REFERENCES favorites(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS polls (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80) UNIQUE
);

CREATE TABLE IF NOT EXISTS categories_polls (
    id INTEGER PRIMARY KEY,
    name VARCHAR(80) UNIQUE
);

CREATE TABLE IF NOT EXISTS polls_companies (
    company_id VARCHAR(20),
    poll_id INTEGER,
    PRIMARY KEY (company_id, poll_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS pollproducts (
    poll_id INTEGER,
    product_id INTEGER,
    PRIMARY KEY (poll_id, product_id),
    FOREIGN KEY (poll_id) REFERENCES polls(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE IF NOT EXISTS customerpollratings (
    customer_id INTEGER,
    poll_id INTEGER,
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (customer_id, poll_id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS category_poll_links (
    company_id VARCHAR(20),
    categorypoll_id INTEGER,
    poll_id INTEGER,
    daterating DATETIME,
    rating DOUBLE,
    PRIMARY KEY (company_id, categorypoll_id, poll_id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (categorypoll_id) REFERENCES categories_polls(id),
    FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE IF NOT EXISTS memberships (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS periods (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS membershipperiods (
    membership_id INTEGER,
    period_id INTEGER,
    price DOUBLE,
    PRIMARY KEY (membership_id, period_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (period_id) REFERENCES periods(id)
);

CREATE TABLE IF NOT EXISTS benefits (
    id INTEGER PRIMARY KEY,
    description VARCHAR(80),
    detail TEXT
);

CREATE TABLE IF NOT EXISTS membershipbenefits (
    membership_id INTEGER,
    benefit_id INTEGER,
    PRIMARY KEY (membership_id, benefit_id),
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);

CREATE TABLE IF NOT EXISTS audiencebenefits (
    audience_id INTEGER,
    benefit_id INTEGER,
    PRIMARY KEY (audience_id, benefit_id),
    FOREIGN KEY (audience_id) REFERENCES audiences(id),
    FOREIGN KEY (benefit_id) REFERENCES benefits(id)
);
