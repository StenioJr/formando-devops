variable "divisor" {
  type = number

  validation {
    condition     = var.divisor != 0
    error_message = "Não existe divisão por 0, escolha outro divisor!"
  }
  
}

variable "nome" {
  type = string
}