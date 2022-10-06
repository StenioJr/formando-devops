locals {
    data             = formatdate("DD/MM/YYYY, ", timestamp())
    divisivel        = [for i in range(1,100) : i if i%var.divisor == 0]
    lista_divisiveis = join(", ", local.divisivel)
}

resource "local_file" "alo_mundo" {
  content  = templatefile("./alo_mundo.txt.tpl", {nome = var.nome, data = local.data, div = var.divisor, divisiveis = local.lista_divisiveis})
  filename = "./alo_mundo.txt"
}