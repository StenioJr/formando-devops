Este arquivo contém apenas a resposta do item 4.
____

### 4 - Assumindo Recursos

Para assumir recursos existentes posso usar o comando `terraform import`, que faz o terraform assimilar um recurso existente para o meu state.

ex: `terraform import aws_instance.exemplo i-abcd1234`

`terraform import [tipo.nome] [identificador]`

Para saber como é o identificador de cada recurso no meu cloud provider, tenho que ir na documentação e pesquisar sobre aquele tipo de recurso. 
Geralmente no final da página tem uma seção com o nome import, onde mostra como é feito.

Se for um recurso com o mesmo nome que eu já tenho no meu código, ele já associa imediatamente. Se for de um nome que eu ainda não tiver definido no meu código, devo configurar ele anteriormente.

Uso o comando `terraform state pull > estado.import` e pego o estado atual do que foi importado para copiar, como por exemplo o valor da ami e o instance type, e posso incluir no meu código. 

