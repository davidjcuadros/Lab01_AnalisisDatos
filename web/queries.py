from sqlalchemy import select, func
from sqlalchemy import over
from models import Rental, Inventory, Film, FilmCategory, Category, Customer, Payment

def q1_peliculasMasAlquiladasPorCategoria(session):

    rentals_per_film = (
        select(
            Category.name.label("category"),
            Film.film_id,
            Film.title,
            func.count(Rental.rental_id).label("total_rentals")
        )
        .join(Inventory, Rental.inventory_id == Inventory.inventory_id)
        .join(Film, Inventory.film_id == Film.film_id)
        .join(FilmCategory, Film.film_id == FilmCategory.film_id)
        .join(Category, FilmCategory.category_id == Category.category_id)
        .group_by(Category.name, Film.film_id, Film.title)
        .subquery()
    )

    ranked = (
        select(
            rentals_per_film.c.category,
            rentals_per_film.c.title,
            rentals_per_film.c.total_rentals,
            func.row_number().over(
                partition_by=rentals_per_film.c.category,
                order_by=rentals_per_film.c.total_rentals.desc()
            ).label("rn")
        )
        .subquery()
    )

    stmt = select(
        ranked.c.category,
        ranked.c.title,
        ranked.c.total_rentals
    ).where(ranked.c.rn == 1)

    return session.execute(stmt).all()

def q2_clienteMayorGastoAlPromedio(session):

    sub_totals = (
        select(
            func.sum(Payment.amount).label("total_per_customer")
        )
        .group_by(Payment.customer_id)
        .subquery()
    )

    avg_total = select(
        func.avg(sub_totals.c.total_per_customer)
    ).scalar_subquery()

    stmt = (
        select(
            Customer.customer_id,
            func.concat(Customer.first_name, " ", Customer.last_name).label("customer_name"),
            func.sum(Payment.amount).label("total_spent")
        )
        .join(Payment, Customer.customer_id == Payment.customer_id)
        .group_by(Customer.customer_id, Customer.first_name, Customer.last_name)
        .having(func.sum(Payment.amount) > avg_total)
    )

    return session.execute(stmt).all()
def q3_peliculasMasAlquiladasAlPromedio(session):

    film_rentals = (
        select(
            Film.film_id,
            Film.title,
            Category.category_id,
            Category.name.label("category_name"),
            func.count(Rental.rental_id).label("total_rentals")
        )
        .join(Inventory, Rental.inventory_id == Inventory.inventory_id)
        .join(Film, Inventory.film_id == Film.film_id)
        .join(FilmCategory, Film.film_id == FilmCategory.film_id)
        .join(Category, FilmCategory.category_id == Category.category_id)
        .group_by(Film.film_id, Film.title, Category.category_id, Category.name)
        .subquery()
    )

    category_avg = (
        select(
            film_rentals.c.category_id,
            func.avg(film_rentals.c.total_rentals).label("avg_rentals")
        )
        .group_by(film_rentals.c.category_id)
        .subquery()
    )

    stmt = (
        select(
            film_rentals.c.category_name,
            film_rentals.c.title,
            film_rentals.c.total_rentals
        )
        .join(category_avg,
              film_rentals.c.category_id == category_avg.c.category_id)
        .where(
            film_rentals.c.total_rentals > category_avg.c.avg_rentals
        )
    )

    return session.execute(stmt).all()

def q4_clientesAlquilaronSolo1Trimestre(session):

    sub_q2 = (
        select(Rental.customer_id)
        .where(func.extract("quarter", Rental.rental_date) == 2)
    )

    stmt = (
        select(
            Customer.customer_id,
            func.concat(Customer.first_name, " ", Customer.last_name)
        )
        .join(Rental, Customer.customer_id == Rental.customer_id)
        .where(func.extract("quarter", Rental.rental_date) == 1)
        .where(Customer.customer_id.not_in(sub_q2))
        .distinct()
    )

    return session.execute(stmt).all()

