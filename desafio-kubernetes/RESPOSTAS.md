# RESPOSTAS

## Desafio docker

**1. Execute o comando `hostname` em um container usando a imagem `alpine`. Certifique-se que o container será removido após a execução.**
```
docker container run --rm -ti alpine hostname
```

**2. Crie um container com a imagem `nginx` (versão 1.22), expondo a porta 80 do container para a porta 8080 do host.**
```
docker container run -d -p 8080:80 nginx:1.22
```

**3. Faça o mesmo que a questão anterior (2), mas utilizando a porta 90 no container. O arquivo de configuração do nginx deve existir no host e ser read-only no container.**

Primeiro, aproveitei o container criado na questão anterior para copiar o arquivo de configuração para ser usado como modelo.
Criei o arquivo `default.conf` no meu host, no diretório `/mnt/nginx_conf/conf.d`, e alterei a configuração da porta do nginx para porta 90. 
```
server {
    listen       90;
    listen  [::]:90;
    server_name  localhost;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
                ...
                ...
                ...
```

Por último, subi um novo container com o seguinte comando:
```
docker container run -d -p 8080:90 --name nginx -v /mnt/nginx_conf/conf.d:/etc/nginx/conf.d:ro nginx:1.22
```
Com isso, faço o bind do diretório `/mnt/nginx_conf/conf.d`com o `/etc/nginx/conf.d` do container, com a propriedade 'read-only'.
```
root@STENIO-PC:~# docker container ls
CONTAINER ID   IMAGE        COMMAND                  CREATED              STATUS              PORTS                          NAMES
370e87c8bda4   nginx:1.22   "/docker-entrypoint.…"   About a minute ago   Up About a minute   80/tcp, 0.0.0.0:8080->90/tcp   nginx
root@STENIO-PC:~# curl localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

**4. Construa uma imagem para executar o programa**


Resposta:
```
mkdir ./meuPython
cd ./meuPython
touch hello_world.py Dockerfile

cat <<EOF > hello_world.py
def main():
   print('Hello World in Python!')

if __name__ == '__main__':
  main()
EOF

cat <<EOF > Dockerfile
FROM python

WORKDIR /app
ADD . /app
LABEL description="Hello World"

CMD ["python", "./hello_world.py"]
EOF

docker image build -t hello_world_py:1.0 .
docker container run hello_world_py:1.0
```

**5. Execute um container da imagem `nginx` com limite de memória 128MB e 1/2 CPU.**
```
docker container run -d -m 128M --cpus="0.5" nginx
```

**6. Qual o comando usado para limpar recursos como imagens, containers parados, cache de build e networks não utilizadas?**

`docker system prune` é o comando que remove imagens, contêineres e redes. Os volumes não são removidos por padrão e você deve especificar o sinalizador --volumes para o sistema docker remover para remover volumes.

**7. Como você faria para extrair os comandos Dockerfile de uma imagem?**

É possível fazer isso usando a imagem `alpine/dfimage` disponível no dockerhub. Essa imagem usa uma ferramenta chamada "Whaler", que é um programa Go projetado para fazer engenharia reversa de imagens docker no Dockerfile que o criou.
```
# Exemplo de uso

$ alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm alpine/dfimage"
$ dfimage -sV=1.36 nginx:latest
```

referência: https://hub.docker.com/r/alpine/dfimage





 
# Desafio Kubernetes

**1 - com uma unica linha de comando capture somente linhas que contenham "erro" do log do pod `serverweb` no namespace `meusite` que tenha a label `app: ovo`.**

```
kubectl logs -n meusite -l app=ovo | grep -i 'error'
```
__________________________

**2 - crie o manifesto de um recurso que seja executado em todos os nós do cluster com a imagem `nginx:latest` com nome `meu-spread`, nao sobreponha ou remova qualquer taint de qualquer um dos nós.**

```yaml
apiVersion: apps/v1
kind: DaemonSet   
metadata:
  name: meu-spread
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: meu-spread
        image: nginx:latest
        ports:
        - containerPort: 80
      tolerations:
      - key:
        operator: "Exists"
```
```
root@STENIO-PC:~# kubectl create -f questao2.yaml 
daemonset.apps/meu-spread created
root@STENIO-PC:~# kubectl get pods -o wide 
NAME               READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
meu-spread-97hmh   1/1     Running   0          30s   10.244.0.13   meuk8s-control-plane   <none>           <none>
meu-spread-txsgv   1/1     Running   0          30s   10.244.1.20   meuk8s-worker          <none>           <none>
```

Para garantir que cada nó irá rodar uma cópia do pod uso o DaemonSet. Além disso, para ignorar o efeito de taints é usando `tolerations`. Um `key` vazia com o `operator: "Exists"` corresponde a todas as chaves, valores e efeitos, o que significa que ignorará qualquer taint.
<!-- https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
There are two special cases:

An empty key with operator Exists matches all keys, values and effects which means this will tolerate everything.An empty effect matches all effects with key key1. -->
__________________________

**3 - crie um deploy `meu-webserver` com a imagem `nginx:latest` e um initContainer com a imagem `alpine`. O initContainer deve criar um arquivo /app/index.html, tenha o conteudo "HelloGetup" e compartilhe com o container de nginx que só poderá ser inicializado se o arquivo foi criado.**

```yaml
apiVersion: apps/v1  
kind: Deployment     
metadata:
  name: meu-webserver
  labels:
    app: nginx       
spec:
  replicas: 1        
  selector:
    matchLabels:     
      app: nginx     
  template:
    metadata:        
      labels:        
        app: nginx
    spec:
      containers:
      - name: meu-webserver
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: volume-nginx
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: init
        image: alpine
        command: ["sh", "-c", "echo HelloGetup > /app/index.html"]
        volumeMounts:
        - name: volume-nginx
          mountPath: "/app"
      volumes:
      - name: volume-nginx
        emptyDir: {}
```
Para que seja possível a utilização do arquivo criado pelo InitContainer, é necessário o uso de um volume e montá-lo em ambos os containers.
__________________________

**4 - crie um deploy chamado `meuweb` com a imagem `nginx:1.16` que seja executado exclusivamente no node master.**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meuweb
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.16
        ports:
        - containerPort: 80
      nodeSelector:
        kubernetes.io/hostname: meuk8s-control-plane
      tolerations:
      - key:
        operator: "Exists"   
```
Para fazer o que foi pedido na questão usei o node selector com o label do meu node control plane `kubernetes.io/hostname: meuk8s-control-plane` e usei o tolerations para que o taint seja ignorado.

```
root@STENIO-PC:~# kubectl create -f questao4.yml
deployment.apps/meuweb created
root@STENIO-PC:~# kubectl get pods -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
meuweb-6966b968cd-g2fpf   1/1     Running   0          43s   10.244.0.17   meuk8s-control-plane   <none>           <none>
root@STENIO-PC:~# kubectl scale --replicas=5 deployment meuweb
deployment.apps/meuweb scaled
root@STENIO-PC:~# kubectl get pods -o wide
NAME                      READY   STATUS    RESTARTS   AGE    IP            NODE                   NOMINATED NODE   READINESS GATES
meuweb-6966b968cd-2jrnc   1/1     Running   0          58s    10.244.0.20   meuk8s-control-plane   <none>           <none>
meuweb-6966b968cd-dl56c   1/1     Running   0          58s    10.244.0.19   meuk8s-control-plane   <none>           <none>
meuweb-6966b968cd-g2fpf   1/1     Running   0          113s   10.244.0.17   meuk8s-control-plane   <none>           <none>
meuweb-6966b968cd-jp68l   1/1     Running   0          58s    10.244.0.21   meuk8s-control-plane   <none>           <none>
meuweb-6966b968cd-sc6kp   1/1     Running   0          58s    10.244.0.18   meuk8s-control-plane   <none>           <none>
```


____________________________
**5 - com uma unica linha de comando altere a imagem desse pod `meuweb` para `nginx:1.19` e salve o comando aqui no repositorio.**
```
kubectl set image deploy meuweb nginx=nginx:1.19
```
___________________________


6 - quais linhas de comando para instalar o ingress-nginx controller usando helm, com os seguintes parametros;

    helm repository : https://kubernetes.github.io/ingress-nginx

    values do ingress-nginx : 
    controller:
      hostPort:
        enabled: true
      service:
        type: NodePort
      updateStrategy:
        type: Recreate

7 - quais as linhas de comando para: 

- criar um deploy chamado `pombo` com a imagem de `nginx:1.11.9-alpine` com 4 réplicas;

`kubectl create deployment pombo --image=nginx:1.11.9-alpine --replicas=4`

- alterar a imagem para `nginx:1.16` e registre na annotation automaticamente;

`kubectl set image deployment pombo nginx=nginx:1.16 --record` 

- alterar a imagem para 1.19 e registre novamente; 

`kubectl set image deployment pombo nginx=nginx:1.19 --record`

- imprimir a historia de alterações desse deploy;

`kubectl rollout history deployment pombo`

  - voltar para versão 1.11.9-alpine baseado no historico que voce registrou.

`kubectl rollout undo deployment pombo --to-revision=1`

- criar um ingress chamado `web` para esse deploy

`kubectl create ingress web --class=default --rule="pombo.com/*=pombo:80"` 
___________________________

8 - linhas de comando para; 

- criar um deploy chamado `guardaroupa` com a imagem `redis`;

`kubectl create deployment guardaroupa --image=redis` 

- criar um serviço do tipo ClusterIP desse redis com as devidas portas.

`kubectl expose deployment guardaroupa --type=ClusterIP --port=6379` 
___________________________

9 - crie um recurso para aplicação stateful com os seguintes parametros:

    - nome : meusiteset
    - imagem nginx 
    - no namespace backend
    - com 3 réplicas
    - disco de 1Gi
    - montado em /data
    - sufixo dos pvc: data

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: meusiteset
  namespace: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: volume-nginx
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: volume-nginx
    spec:
      accessModes: [ "ReadWriteMany" ]
      resources:
        requests:
          storage: 1Gi
```

10 - crie um recurso com 2 replicas, chamado `balaclava` com a imagem `redis`, usando as labels nos pods, replicaset e deployment, `backend=balaclava` e `minhachave=semvalor` no namespace `backend`.


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: balaclava
  namespace: balaclava
  labels:
    backend: balaclava
    minhachave: semvalor
spec:
  replicas: 2
  selector:
    matchLabels:
      backend: balaclava
  template:
    metadata:
      labels:
        backend: balaclava
        minhachave: semvalor
    spec:
      containers:
      - name: balaclava
        image: redis
        ports:
        - containerPort: 6379 
```


___________________________
11 - linha de comando para listar todos os serviços do cluster do tipo `LoadBalancer` mostrando tambem `selectors`.

`kubectl get service -o wide | grep LoadBalancer` 
___________________________

12 - com uma linha de comando, crie uma secret chamada `meusegredo` no namespace `segredosdesucesso` com os dados, `segredo=azul` e com o conteudo do texto abaixo.

```bash
   # cat chave-secreta
     aW5ncmVzcy1uZ2lueCAgIGluZ3Jlc3MtbmdpbngtY29udHJvbGxlciAgICAgICAgICAgICAgICAg
     ICAgICAgICAgICAgTG9hZEJhbGFuY2VyICAgMTAuMjMzLjE3Ljg0ICAgIDE5Mi4xNjguMS4zNSAg
     IDgwOjMxOTE2L1RDUCw0NDM6MzE3OTQvVENQICAgICAyM2ggICBhcHAua3ViZXJuZXRlcy5pby9j
     b21wb25lbnQ9Y29udHJvbGxlcixhcHAua3ViZXJuZXRlcy5pby9pbnN0YW5jZT1pbmdyZXNzLW5n
     aW54LGFwcC5rdWJlcm5ldGVzLmlvL25hbWU9aW5ncmVzcy1uZ
```
```
kubectl create secret generic -n segredosdesucesso meusegredo --from-literal=segredo=azul --from-file=chave-secreta
```

13 - qual a linha de comando para criar um configmap chamado `configsite` no namespace `site`. Deve conter uma entrada `index.html` que contenha seu nome.
```
kubectl create configmap -n site configsite --from-literal=index.html=Stenio
```

14 - crie um recurso chamado `meudeploy`, com a imagem `nginx:latest`, que utilize a secret criada no exercicio 11 como arquivos no diretorio `/app`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: meudeploy
  name: meudeploy
spec:
  selector:
    matchLabels:
      app: meudeploy
  template:
    metadata:
      labels:
        app: meudeploy
    spec:
      containers:
      - image: nginx:latest
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: secret
          mountPath: "/app"
      volumes:
      - name: secret
        secret:
          secretName: meusegredo
```

15 - crie um recurso chamado `depconfigs`, com a imagem `nginx:latest`, que utilize o configMap criado no exercicio 12 e use seu index.html como pagina principal desse recurso.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: depconfigs
  name: depconfigs
  namespace: site
spec:
  selector:
    matchLabels:
      app: depconfigs
  template:
    metadata:
      labels:
        app: depconfigs
    spec:
      containers:
      - image: nginx:latest
        name: nginx
        volumeMounts:
        - name: meu-configmap
          mountPath: /usr/share/nginx/html
      volumes:
      - name: meu-configmap
        configMap:
          name: configsite
```

16 - crie um novo recurso chamado `meudeploy-2` com a imagem `nginx:1.16` , com a label `chaves=secretas` e que use todo conteudo da secret como variavel de ambiente criada no exercicio 11.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    chaves: secretas
  name: meudeploy-2
  namespace: segredosdesucesso
spec:
  selector:
    matchLabels:
      chaves: secretas
  template:
    metadata:
      labels:
        chaves: secretas
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
        ports:
        - containerPort: 80
        envFrom:
        - secretRef:
            name: meusegredo
```

17 - linhas de comando que;

- crie um namespace `cabeludo`;

`kubectl create namespace cabeludo`

- um deploy chamado `cabelo` usando a imagem `nginx:latest`; 

`kubectl create deployment -n cabeludo cabelo --image=nginx:latest`

- uma secret chamada `acesso` com as entradas `username: pavao` e `password: asabranca`;

`kubectl create secret generic -n cabeludo  --from-literal=username=pavao --from-literal=password=asabranca`

- exponha variaveis de ambiente chamados USUARIO para username e SENHA para a password.



18 - crie um deploy `redis` usando a imagem com o mesmo nome, no namespace `cachehits` e que tenha o ponto de montagem `/data/redis` de um volume chamado `app-cache` que NÂO deverá ser persistente.

```yaml
apiVersion: apps/v1   
kind: Deployment      
metadata:
  labels:
    app: redis        
  name: redis
  namespace: cachehits
spec:
  replicas: 1
  selector:
    matchLabels:      
      app: redis      
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - image: redis
        name: redis
        ports:
        - containerPort: 6379
        volumeMounts:
        - mountPath: /data/redis
          name: app-cache
      volumes:
      - name: app-cache
        emptyDir: {}
```


19 - com uma linha de comando escale um deploy chamado `basico` no namespace `azul` para 10 replicas.
```
kubectl scale --replicas=10 -n azul deployment basico
```

20 - com uma linha de comando, crie um autoscale de cpu com 90% de no minimo 2 e maximo de 5 pods para o deploy `site` no namespace `frontend`.
```
kubectl autoscale -n frontend deploy site --cpu-percent=90 --min=2 --max=5
```
21 - com uma linha de comando, descubra o conteudo da secret `piadas` no namespace `meussegredos` com a entrada `segredos`.

22 - marque o node o nó `k8s-worker1` do cluster para que nao aceite nenhum novo pod.
```
kubectl taint nodes k8s-worker1 key1=value1:NoSchedule
```

23 - esvazie totalmente e de uma unica vez esse mesmo nó com uma linha de comando.
```
kubectl drain k8s-worker1
```
_______

**24 - qual a maneira de garantir a criaçao de um pod ( sem usar o kubectl ou api do k8s ) em um nó especifico.**

Posso criar um pod estático, criando um manifesto diretamente no diretório `/etc/kubernetes/manifests`.  Os pods estáticos são gerenciados diretamente pelo  kubelet em um nó específico, sem que o servidor de API os observe. O kubelet observa cada Pod estático (e o reinicia se falhar).

____________
25 - criar uma serviceaccount `userx` no namespace `developer`. essa serviceaccount só pode ter permissao total sobre pods (inclusive logs) e deployments no namespace `developer`. descreva o processo para validar o acesso ao namespace do jeito que achar melhor.

26 - criar a key e certificado cliente para uma usuaria chamada `jane` e que tenha permissao somente de listar pods no namespace `frontend`. liste os comandos utilizados.

27 - qual o `kubectl get` que traz o status do scheduler, controller-manager e etcd ao mesmo tempo
```
kubectl get componentstatuses
```

 <!-- Falta responder:  17(ultimo item), 21, 25, 26 -->