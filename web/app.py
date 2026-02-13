import os
from flask import Flask, request, render_template_string
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from queries import (
    q1_peliculasMasAlquiladasPorCategoria,
    q2_clienteMayorGastoAlPromedio,
    q3_peliculasMasAlquiladasAlPromedio,
    q4_clientesAlquilaronSolo1Trimestre,
)

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:1234@db:5432/sakila"
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)
app = Flask(__name__)

HTML = """
<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<title>Lab No. 1 - Sakila – Consultas</title>
<style>
body { font-family: Arial, sans-serif; margin: 24px; }
.box { border: 1px solid #ddd; padding: 16px; margin-bottom: 16px; border-radius: 8px; }
input, select { padding: 6px; }
table { border-collapse: collapse; width: 100%; margin-top: 10px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background: #f5f5f5; }
.muted { color: #666; font-size: 0.9em; }
button { padding: 8px 16px; cursor: pointer; background: #4a90d9; color: white;
         border: none; border-radius: 4px; font-size: 14px; }
button:hover { background: #357abd; }
.error { color: #c0392b; background: #fdecea; padding: 10px;
         border-radius: 4px; margin-top: 10px; }
</style>
</head>
<body>
<h1>Sakila – Consultas SQLAlchemy</h1>
<p class="muted">David Julián Cuadros</p>

<!-- Q1 -->
<div class="box">
  <h2>Q1 · Película más alquilada por categoría</h2>
  <p class="muted">Devuelve, para cada categoría, el título con más alquileres.</p>
  <form method="get" action="/">
    <input type="hidden" name="view" value="q1"/>
    <button type="submit">Ejecutar Q1</button>
  </form>
  {% if view == "q1" %}
    {% if error %}
      <p class="error">{{ error }}</p>
    {% else %}
      <table>
        <tr><th>Categoría</th><th>Título</th><th>Total alquileres</th></tr>
        {% for r in rows %}
        <tr>
          <td>{{ r[0] }}</td>
          <td>{{ r[1] }}</td>
          <td>{{ r[2] }}</td>
        </tr>
        {% endfor %}
      </table>
      {% if rows|length == 0 %}<p class="muted">Sin resultados.</p>{% endif %}
    {% endif %}
  {% endif %}
</div>

<!-- Q2 -->
<div class="box">
  <h2>Q2 · Clientes cuyo gasto supera el promedio</h2>
  <p class="muted">Lista los clientes cuyo total pagado es mayor al promedio general.</p>
  <form method="get" action="/">
    <input type="hidden" name="view" value="q2"/>
    <button type="submit">Ejecutar Q2</button>
  </form>
  {% if view == "q2" %}
    {% if error %}
      <p class="error">{{ error }}</p>
    {% else %}
      <table>
        <tr><th>ID Cliente</th><th>Nombre</th><th>Total gastado</th></tr>
        {% for r in rows %}
        <tr>
          <td>{{ r[0] }}</td>
          <td>{{ r[1] }}</td>
          <td>{{ "%.2f"|format(r[2]) }}</td>
        </tr>
        {% endfor %}
      </table>
      {% if rows|length == 0 %}<p class="muted">Sin resultados.</p>{% endif %}
    {% endif %}
  {% endif %}
</div>

<!-- Q3 -->
<div class="box">
  <h2>Q3 · Películas con más alquileres que el promedio de su categoría</h2>
  <p class="muted">Muestra títulos que superan la media de alquileres dentro de su categoría.</p>
  <form method="get" action="/">
    <input type="hidden" name="view" value="q3"/>
    <button type="submit">Ejecutar Q3</button>
  </form>
  {% if view == "q3" %}
    {% if error %}
      <p class="error">{{ error }}</p>
    {% else %}
      <table>
        <tr><th>Categoría</th><th>Título</th><th>Total alquileres</th></tr>
        {% for r in rows %}
        <tr>
          <td>{{ r[0] }}</td>
          <td>{{ r[1] }}</td>
          <td>{{ r[2] }}</td>
        </tr>
        {% endfor %}
      </table>
      {% if rows|length == 0 %}<p class="muted">Sin resultados.</p>{% endif %}
    {% endif %}
  {% endif %}
</div>

<!-- Q4 -->
<div class="box">
  <h2>Q4 · Clientes que alquilaron solo en el 1.er trimestre</h2>
  <p class="muted">Clientes con alquileres en Q1 pero ninguno en Q2.</p>
  <p class="muted">Se hizo una modificación de los datos para que tuvieramos algún resultado dado que ningún cliente cumplía con los requisitos solicitados. </p>
  <form method="get" action="/">
    <input type="hidden" name="view" value="q4"/>
    <button type="submit">Ejecutar Q4</button>
  </form>
  {% if view == "q4" %}
    {% if error %}
      <p class="error">{{ error }}</p>
    {% else %}
      <table>
        <tr><th>ID Cliente</th><th>Nombre completo</th></tr>
        {% for r in rows %}
        <tr>
          <td>{{ r[0] }}</td>
          <td>{{ r[1] }}</td>
        </tr>
        {% endfor %}
      </table>
      {% if rows|length == 0 %}<p class="muted">Sin resultados.</p>{% endif %}
    {% endif %}
  {% endif %}
</div>

</body>
</html>
"""

QUERY_MAP = {
    "q1": q1_peliculasMasAlquiladasPorCategoria,
    "q2": q2_clienteMayorGastoAlPromedio,
    "q3": q3_peliculasMasAlquiladasAlPromedio,
    "q4": q4_clientesAlquilaronSolo1Trimestre,
}

@app.get("/")
def index():
    view = request.args.get("view", "")
    rows = []
    error = None

    if view in QUERY_MAP:
        try:
            with Session(engine) as session:
                rows = QUERY_MAP[view](session)
        except Exception as e:
            error = str(e)

    return render_template_string(
        HTML,
        view=view,
        rows=rows,
        error=error,
    )

@app.get("/health")
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)