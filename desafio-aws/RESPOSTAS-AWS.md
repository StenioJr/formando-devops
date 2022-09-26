## Respostas Desafio AWS

### 1- Setup de ambiente

Stack do ambiente criado conforme orientações
![](./Imagens-respostas/desafio-aws-1.png) 

### 2 - Networking

O erro é devido o Security Group estar liberando as portas TCP no intervalo 81 - 8080, para origem 0.0.0.0/1.
Para corrigir e deixar o servidor web acessível, é necessário alterar a regra de entrada para liberar HTTP, na porta 80, para qualquer origem 0.0.0.0/0. Após isso, a página ficou acessível.

![](./Imagens-respostas/desafio-aws-2.png) 

![](./Imagens-respostas/desafio-aws-3.png)

### 3 - EC2 Access

Seguindo [esse tutorial da AWS](https://aws.amazon.com/pt/premiumsupport/knowledge-center/ec2-windows-replace-lost-key-pair/), posso substituir o par de chaves perdidos na instância que está rodando por meio de uma automação pronta do Systems Manager.

Vou no item `Automação > Executar` e escolho o documento `AWSSupport-ResetAccess`.
![](./Imagens-respostas/desafio-aws-4.png) 

coloco o id da minha instância `i-076e83ec1d3d9ae9c`, executo e aguardo a conclusão.
![](./Imagens-respostas/desafio-aws-6.png) 

Após isso, vou em `Systems Manager > Parameter Store` e lá estará a nova chave privada criptografada que usarei para acessar a instância. Copio o conteúdo da chave, crio um arquivo de texto na minha máquina local chamado `chave.pem` e altero as permissões para 400. Após isso, preciso alterar o Security Group do servidor web para permitir acesso via SSH do meu IP, e poderei acessar normalmente a instância, e incluir meu nome no arquivo `/var/www/html/index.html`. 
![](./Imagens-respostas/desafio-aws-7.png) 