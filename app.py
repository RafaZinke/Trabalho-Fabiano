import os
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory
from sqlalchemy import DateTime, Integer, Numeric, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

ROOT = Path(__file__).resolve().parent
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///simulacoes.db")

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
Session = sessionmaker(engine)


class Base(DeclarativeBase):
    pass


class Simulacao(Base):
    __tablename__ = "simulacoes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    criada_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    salario: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    dias: Mapped[int] = mapped_column(Integer)
    decimo: Mapped[int] = mapped_column(Integer)
    ferias: Mapped[int] = mapped_column(Integer)
    integrais: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    aviso: Mapped[int] = mapped_column(Integer)
    extras: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    descontos: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2))


Base.metadata.create_all(engine)
app = Flask(__name__)


def valor(dados, campo, minimo, maximo):
    try:
        numero = Decimal(str(dados[campo]))
    except (KeyError, TypeError, ValueError, InvalidOperation):
        raise ValueError(f"{campo}: valor inválido")

    if not numero.is_finite() or not minimo <= numero <= maximo:
        raise ValueError(f"{campo}: fora do intervalo permitido")

    return numero


def inteiro(dados, campo, maximo):
    numero = valor(dados, campo, 0, maximo)

    if numero != numero.to_integral_value():
        raise ValueError(f"{campo}: informe um número inteiro")

    return int(numero)


def moeda(numero):
    return numero.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def calcular(dados):
    salario = valor(dados, "salario", Decimal("0.01"), 10000000)

    if salario != moeda(salario):
        raise ValueError("salario: use no máximo duas casas decimais")

    dias = inteiro(dados, "dias", 30)
    decimo = inteiro(dados, "decimo", 12)
    ferias = inteiro(dados, "ferias", 12)
    aviso = inteiro(dados, "aviso", 90)

    valores = {}

    for campo in ("integrais", "extras", "descontos"):
        numero = valor(dados, campo, 0, 10000000)

        if numero != moeda(numero):
            raise ValueError(f"{campo}: use no máximo duas casas decimais")

        valores[campo] = numero

    ferias_proporcionais = moeda(salario * ferias / 12)
    ferias_integrais = valores["integrais"]

    parcelas = {
        "saldo_salarial": moeda(salario * dias / 30),
        "decimo_terceiro": moeda(salario * decimo / 12),
        "ferias_proporcionais": ferias_proporcionais,
        "terco_ferias_proporcionais": moeda(ferias_proporcionais / 3),
        "ferias_integrais": ferias_integrais,
        "terco_ferias_integrais": moeda(ferias_integrais / 3),
        "aviso_indenizado": moeda(salario * aviso / 30),
        "outras_verbas": valores["extras"],
    }

    bruto = sum(parcelas.values())
    total = bruto - valores["descontos"]

    entrada = {
        "salario": salario,
        "dias": dias,
        "decimo": decimo,
        "ferias": ferias,
        "integrais": ferias_integrais,
        "aviso": aviso,
        "extras": valores["extras"],
        "descontos": valores["descontos"],
    }

    parcelas_json = {nome: str(quantia) for nome, quantia in parcelas.items()}

    return entrada, parcelas_json, str(bruto), str(total)


@app.get("/")
def pagina_inicial():
    return send_from_directory(ROOT, "index.html")


@app.get("/health")
def verificar_saude():
    with Session() as session:
        session.execute(select(1))

    return jsonify(status="ok")


@app.get("/api/simulacoes")
def listar_simulacoes():
    with Session() as session:
        registros = session.scalars(
            select(Simulacao).order_by(Simulacao.id.desc()).limit(50)
        ).all()

        return jsonify([
            {
                "id": registro.id,
                "criada_em": registro.criada_em.isoformat(),
                "salario": str(registro.salario),
                "total": str(registro.total),
            }
            for registro in registros
        ])


@app.post("/api/simulacoes")
def criar_simulacao():
    dados = request.get_json(silent=True)

    if not isinstance(dados, dict):
        return jsonify(erro="Envie um objeto JSON"), 400

    try:
        entrada, parcelas, bruto, total = calcular(dados)
    except ValueError as erro:
        return jsonify(erro=str(erro)), 400

    with Session.begin() as session:
        registro = Simulacao(**entrada, total=Decimal(total))
        session.add(registro)
        session.flush()
        identificador = registro.id

    return jsonify(
        id=identificador,
        parcelas=parcelas,
        bruto=bruto,
        total=total,
    ), 201


@app.delete("/api/simulacoes/<int:identificador>")
def excluir_simulacao(identificador):
    with Session.begin() as session:
        registro = session.get(Simulacao, identificador)

        if registro is None:
            return jsonify(erro="Simulação não encontrada"), 404

        session.delete(registro)

    return "", 204


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000)