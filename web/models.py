from sqlalchemy import Column, Integer, String, Numeric, DateTime, SmallInteger, ForeignKey
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Customer(Base):
    __tablename__ = "customer"
    customer_id = Column(Integer, primary_key=True)
    first_name  = Column(String)
    last_name   = Column(String)
    email       = Column(String)


class Payment(Base):
    __tablename__ = "payment"
    payment_id  = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey("customer.customer_id"))
    amount      = Column(Numeric)
    payment_date = Column(DateTime)


class Rental(Base):
    __tablename__ = "rental"
    rental_id    = Column(Integer, primary_key=True)
    rental_date  = Column(DateTime)
    inventory_id = Column(Integer, ForeignKey("inventory.inventory_id"))
    customer_id  = Column(Integer, ForeignKey("customer.customer_id"))


class Inventory(Base):
    __tablename__ = "inventory"
    inventory_id = Column(Integer, primary_key=True)
    film_id      = Column(Integer, ForeignKey("film.film_id"))


class Film(Base):
    __tablename__ = "film"
    film_id = Column(Integer, primary_key=True)
    title   = Column(String)


class FilmCategory(Base):
    __tablename__ = "film_category"
    film_id     = Column(Integer, ForeignKey("film.film_id"), primary_key=True)
    category_id = Column(Integer, ForeignKey("category.category_id"), primary_key=True)


class Category(Base):
    __tablename__ = "category"
    category_id = Column(Integer, primary_key=True)
    name        = Column(String)