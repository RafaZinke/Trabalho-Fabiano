import unittest

from app import calcular


class TestCalculo(unittest.TestCase):
    def dados(self, **alteracoes):
        entrada = {
            "salario": "3000.00",
            "dias": 15,
            "decimo": 6,
            "ferias": 6,
            "integrais": "0.00",
            "aviso": 0,
            "extras": "0.00",
            "descontos": "0.00",
        }
        entrada.update(alteracoes)
        return entrada

    def test_calculo_basico(self):
        _, parcelas, bruto, total = calcular(self.dados())

        self.assertEqual(parcelas["saldo_salarial"], "1500.00")
        self.assertEqual(parcelas["decimo_terceiro"], "1500.00")
        self.assertEqual(parcelas["ferias_proporcionais"], "1500.00")
        self.assertEqual(parcelas["terco_ferias_proporcionais"], "500.00")
        self.assertEqual(bruto, "5000.00")
        self.assertEqual(total, "5000.00")

    def test_rejeita_avos_acima_de_doze(self):
        with self.assertRaises(ValueError):
            calcular(self.dados(decimo=13))

    def test_rejeita_salario_negativo(self):
        with self.assertRaises(ValueError):
            calcular(self.dados(salario="-3000"))

    def test_aplica_desconto(self):
        _, _, _, total = calcular(self.dados(descontos="100.00"))
        self.assertEqual(total, "4900.00")


if __name__ == "__main__":
    unittest.main()