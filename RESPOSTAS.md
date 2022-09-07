

## 1- Kernel e Boot Loader  

Para reativar a permissão no sudo para o usuário vagrant será necessário que eu tenha primeiro acesso como root, para que possa alterar as configurações.

Para redefinir a senha do root, tenho que ir no virtualbox, reiniciar a máquina, e na tela do grub aperto a tecla `E` para editar a inicialização. Nos comandos terei que alterar o `ro` para `rw init=/sysroot/bin/sh`, para que abra um terminal sh como root antes da inicialização do sistema. Após isso saio salvando com `ctrl+x`.

No terminal será necessário os seguintes comandos para definir a senha do root:
```
chroot /sysroot
passwd root
#defino a senha
touch /.autorelabel
exit
```

A partir daqui, terei criado uma nova senha como root, e poderei acessar a máquina e alterar o arquivo `/etc/sudoers.d/vagrant`, e tiro o comentário da linha `vagrant ALL=(ALL) NOPASSWD: ALL` e salvo. A partir de agora o usuário vagrant está com sudo habilitado.


## 2 - Usuários 

Primeiro, crio o grupo getup com gid 2222. Depois, crio o usuário getup pertencente ao grupo 2222, e só então adiciono o usuário getup ao grupo bin.

    sudo groupadd getup -g 2222
    sudo useradd getup -u 1111 -g 2222
    sudo gpasswd -a getup bin
    
Para permitir sudo para todos os comandos sem pedir senha, posso criar uma copia do arquivo '/etc/sudoers.d/vagrant' e fazer as alterações no arquivo, substituindo vagrant para getup.

    cp /etc/sudoers.d/vagrant /etc/sudoers.d/getup



## 3 - SSH 

### 3.1 - Autenticação confiável

Para desabilitar a autenticação por senha é necessário editar o arquivo `/etc/ssh/sshd_config`. Altero os parâmetros `PubkeyAuthentication` para `yes` e `PasswordAuthentication` para `no`.

### 3.2 - Criação de chaves

Para criar um par de chaves ecdsa:

    ssh-keygen -t ecdsa -b 521 

Com isso, será gerado o arquivo `id_ecdsa` (chave privada) e `id_ecdsa.pub` (chave pública) no diretório `~/.ssh/`. Para testar o acesso via ssh usando o par de chaves, posso incluir a chave pública no arquivo `authorized_keys`.

`cat ~/.ssh/id_ecdsa.pub >> ~/authorized_keys`

Após incluir a chave, acesso usando `ssh vagrant@localhost`, insiro a passphrase usada na criação da chave e estarei logado.

### 3.3 - Análise de logs e configurações ssh

Primeiro, transfiro via scp o arquivo da chave:

    scp -P 2222 id_rsa-desafio-linux-devel.gz.b64 vagrant@127.0.0.1:/home/vagrant
    
Decodifico e descompacto o arquivo

    base64 -d id_rsa-desafio-devel.gz.b64 > id_rsa-desafio-devel.gz
    gzip -d id_rsa-desafio-devel.gz

O arquivo da chave privada apresenta formato inválido ao tentar acessar via ssh. Pela dica dada sobre a criação em SO com fim de linha de forma diferente, se trata do fim de linha com `\r`, ao invés de apenas `\n` nos sistemas unix. Dessa forma, é necessário remover a string `\r` do meu arquivo.

    tr -d '\r' < id_rsa-desafio-linux-devel > id_rsa-corrigido 

Ao tentar o comando `ssh -i id_rsa-corrigido devel@localhost` não aparece mais o erro no formato da chave, mas ainda não tenho permissão para logar.

Ao verificar os logs de autenticação, com `tail -f /var/log/secure`, e tentar logar novamente, vejo o erro "Authentication refused: bad ownership or modes for file /home/devel/.ssh/authorized_keys". Logo, corrigindo as permissões do diretório com `chmod 644 home/devel/.ssh/authorized_keys` corrijo o problema e consigo logar normalmente com o usuário devel usando a chave privada. 


## 4 - Systemd  

Ao tentar inicializar o nginx dá um erro, que pôde ser identificado acessando o arquivo de log `/var/log/ngninxerror.log`.
Estava faltando `;` na linha 42 do arquivo `/etc/nginx/nginx.conf`, e também altero a porta de listen do servidor para porta 80. Após a correção da sintaxe, ao fazer o teste do `nginx -t` mostra como se estivesse tudo certo. No entanto, ao tentar iniciar o serviço com `systemctl start nginx` continua apresenta um erro.

Ao executar `systemctl status nginx.service` mostra que o erro está no arquivo `/lib/systemd/system/nginx.service` que impede a inicialização do serviço. Removendo a linha `ExecStartPre=/usr/bin/rm -f /run/nginx.pid`, que estava removendo o pid do nginx, e removendo o parametro `-BROKEN` o arquivo fica corrigido.
Faço o reload do daemon systemctl e starto o nginx com sucesso 
```
systemctl daemon-reload
systemctl start nginx    
[vagrant@centos8 ~]$ curl http://127.0.0.1
Duas palavrinhas pra você: para, béns!
```

## 5 - SSL  

### 5.1 - Criação de certificados 

Primeiro, crio um CA root self-signed
`openssl req -x509 -sha256 -days 1825 -newkey rsa:2048 -keyout rootCA.key -out rootCA.crt`

Depois, crio um arquivo `desafio.local.ext` com o conteúdo:
```
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = www.desafio.local
```

Já para a criação do certificado do site:
```
_#crio a chave privada sem criptografia e o Certificate Signing Request (CSR).
#No CSR insiro informações sobre o domínio, incluindo o CN www.desafio.local_

openssl req -newkey rsa:2048 -nodes -keyout desafio.local.key -out desafio.local.csr
openssl x509 -signkey desafio.local.key -in desafio.local.csr -req -days 365 -out desafio.local.crt
```

Assino o certificado para o site desafio.local usando o CA criado anteriormente
```
openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -in desafio.local.csr -out desafio.local.crt -days 365 -CAcreateserial -extfile desafio.local.ext
```
### 5.2 - Uso de certificados

cp ./desafio.local.crt /etc/pki/nginx/
cp ./desafio.local.key /etc/pki/nginx/private/

vim /etc/nginx/nginx.conf

nginx -t 
systemctl restart nginx

vim /etc/hosts
curl --cacert ~/rootCA.crt https://www.desafio.local


________________________________________________________________________

## 6 - Rede

### 6.1 - Firewall

ping já está funcionando

### 6.2 - HTTP

curl -D - https://httpbin.org/response-headers?hello=world

A opção -D trás os headers. Posso também ter mais informações incluindo o -v (verbose)

______________________________________________________________________________

## Logs

No diretório /etc/logrotate.d/ criei o arquivo nginx com a seguinte configuração:

/var/log/nginx/*.log {
    daily
    rotate 7
    create
    dateext
    compress
    copytruncate
}

Dessa forma terei os logs rotacionados diariamente, e mantendo 1 semana de log.

Testando o logrotate com "logrotate -f /etc/logrotate.d/nginx" vejo que ja está fazendo o rotacionamento de logs. 

Para garantir que o logrotate seja executado diariamente, é importante incluir na configuração do crontab. Assim, crio o arquivo logrotate no /etc/cron.d/ para ser executado diariamente na hora desejada.

0 3 * * * root /usr/sbin/logrotate /etc/logrotate.d/nginx

O logrotate do nginx será executado sempre as 3 da manhã.
-------------------------------------------------------------------------------

## 7 - Filesystem

### 7.1 - Expandir Partição LVM

Com pvdisplay e lvdisplay vejo que o disco /dev/sdb1 corresponte a partição montada como mount /dev/mapper/data_vg-data_lv

Desmonto o disco com "umount  /dev/mapper/data_vg-data_lv"
Uso "cfdisk /dev/sdb" e faço o resize do /dev/sdb1 para 5 Gi
Depois uso "pvresize /dev/sdb1" para expandir o volume físico para o novo tamanho
"lvextend /dev/data_vg/data_lv -l+100%FREE" expande o volume lógico para o tamanho máximo disponível
"resize2fs /dev/data_vg/data_lv"
"mount /dev/data_vg/data_lv /data" monta novamente o sistema de arquivos

### 7.2 - Criar partição LVM 

cfdisk /dev/sdb
crio uma nova partição com o tamanho do disco de 5G e faço o write antes de sair

pvcreate /dev/sdb2 
Crio o volume físico

vgcreate vg-sdb2 /dev/sdb2

lvcreate -l 100%VG vg-sdb2 -n lv-sdb2
mkfs.ext4 /dev/vg-sdb2/lv-sdb2

### 7.3 - Criar partição XFS 

Necessário instalar o pacote xfsprogs, que contém o comando mkfs.xfs

yum update && yum upgrade -y
yum install xfsprogs

Depoís mkfs.xfs /dev/sdc para formatar com xfs


    

   
