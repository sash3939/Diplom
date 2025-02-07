# Создание тестового приложения
<details>
	<summary></summary>
      <br>

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

</details>

---
## Решение:

Подготовим тестовое приложение.

Созададим отдельный git репозиторий `Application` с простым nginx конфигом, который будет отдавать статические данные:

Клонируем репозиторий:
```bash
git clone https://github.com/sash3939/Application.git
```

Создадим в этом репозитории файл содержащую HTML-код ниже:  
index.html
```html
<html>
<head>
Hello, I am Aleksandr
</head>
<body>
<h1>DevOps/h1>
</body>
</html>
```

Создадим Dockerfile, который будет запускать веб-сервер Nginx в фоне с индекс страницей:  
Dockerfile
```Dockerfile
FROM nginx:1.27-alpine

COPY index.html /usr/share/nginx/html
```

Загрузим файлы в [Git-репозиторий](https://github.com/sash3939/Application.git).

Создадим папку для приложения `mkdir mynginx` и скопируем в нее ранее созданые файлы.  
В этой папке выполним сборку приложения:
<details>
	<summary></summary>
      <br>

```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/3-Creating-test-application/mynginx# sudo docker build -t sash39/nginx:v1 .
[+] Building 21.0s (7/7) FINISHED                                                                                                     docker:default
 => [internal] load build definition from Dockerfile                                                                                            0.0s
 => => transferring dockerfile: 99B                                                                                                             0.0s
 => [internal] load metadata for docker.io/library/nginx:1.27-alpine                                                                            6.9s
 => [internal] load .dockerignore                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                 0.0s
 => [internal] load build context                                                                                                               0.0s
 => => transferring context: 31B                                                                                                                0.0s
 => [1/2] FROM docker.io/library/nginx:1.27-alpine@sha256:814a8e88df978ade80e584cc5b333144b9372a8e3c98872d07137dbf3b44d0e4                     13.8s
 => => resolve docker.io/library/nginx:1.27-alpine@sha256:814a8e88df978ade80e584cc5b333144b9372a8e3c98872d07137dbf3b44d0e4                      0.0s
 => => sha256:814a8e88df978ade80e584cc5b333144b9372a8e3c98872d07137dbf3b44d0e4 10.36kB / 10.36kB                                                0.0s
 => => sha256:93f9c72967dbcfaffe724ae5ba471e9568c9bbe67271f53266c84f3c83a409e3 11.23kB / 11.23kB                                                0.0s
 => => sha256:679a5fd058f6ca754a561846fe27927e408074431d63556e8fc588fc38be6901 2.50kB / 2.50kB                                                  0.0s
 => => sha256:66a3d608f3fa52124f8463e9467f170c784abd549e8216aa45c6960b00b4b79b 3.63MB / 3.63MB                                                  4.4s
 => => sha256:58290db888fa6af2884ef0423f4968e17479e82804d125b4e9e7de5ee13d5a35 1.78MB / 1.78MB                                                  3.6s
 => => sha256:5d777e0071f6faf34b4215b907c08927d0f9ab503df5d5eada0868e48c03e99a 628B / 628B                                                      4.3s
 => => sha256:dbcfe8732ee679051780db1b6d2ea76f946c4518047ead6b87efc4d65662bb8d 956B / 956B                                                      4.4s
 => => sha256:37d775ecfbb935921bc194da16ebb1f5c80e1152b184861bf9ac703d220bbd8e 405B / 405B                                                      4.7s
 => => extracting sha256:66a3d608f3fa52124f8463e9467f170c784abd549e8216aa45c6960b00b4b79b                                                       0.1s
 => => sha256:e0350d1fd4dd6324588387625d61066d21828c7e9ce9cc67f2b5f5e531dfc678 1.21kB / 1.21kB                                                  4.8s
 => => sha256:1f4aa363b71aa73f854818db3c0b64093049973d63d526f7739fc715278ff243 1.40kB / 1.40kB                                                  4.8s
 => => extracting sha256:58290db888fa6af2884ef0423f4968e17479e82804d125b4e9e7de5ee13d5a35                                                       0.1s
 => => sha256:e74fff0a393a1c45595f12f609ce27e37a33082e4286cc498044712b5b48a128 15.10MB / 15.10MB                                               12.8s
 => => extracting sha256:5d777e0071f6faf34b4215b907c08927d0f9ab503df5d5eada0868e48c03e99a                                                       0.0s
 => => extracting sha256:dbcfe8732ee679051780db1b6d2ea76f946c4518047ead6b87efc4d65662bb8d                                                       0.0s
 => => extracting sha256:37d775ecfbb935921bc194da16ebb1f5c80e1152b184861bf9ac703d220bbd8e                                                       0.0s
 => => extracting sha256:e0350d1fd4dd6324588387625d61066d21828c7e9ce9cc67f2b5f5e531dfc678                                                       0.0s
 => => extracting sha256:1f4aa363b71aa73f854818db3c0b64093049973d63d526f7739fc715278ff243                                                       0.0s
 => => extracting sha256:e74fff0a393a1c45595f12f609ce27e37a33082e4286cc498044712b5b48a128                                                       0.8s
 => [2/2] COPY index.html /usr/share/nginx/html                                                                                                 0.1s
 => exporting to image                                                                                                                          0.0s
 => => exporting layers                                                                                                                         0.0s
 => => writing image sha256:ce58a25026cd644e58729b0ca59096bd591bf3ed41e8dd822a75523e49af6f99                                                    0.0s
 => => naming to docker.io/sash39/nginx:v1                                                                                                      0.0s
```

</details>

Проверим, что образ создался:
```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/3-Creating-test-application/mynginx# sudo docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
sash39/nginx   v1        1a39fed7c9f0   46 seconds ago   47MB

```

Запустим docker-контейнер с созданным образом и проверим его  работоспособность:
```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/3-Creating-test-application/mynginx# docker run -d sash39/nginx:v1
9b913389d956167691c368a7df01287f3413485523996a5c16afcba2d94ab059
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/3-Creating-test-application/mynginx# docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS     NAMES
9b913389d956   sash39/nginx:v1   "/docker-entrypoint.…"   3 seconds ago   Up 3 seconds   80/tcp    tender_mclaren
```

Загрузим созданный образ в реестре, предварительно нужно авторизоваться с помощью docker login на DockerHub  [Docker Hub](https://hub.docker.com/repository/docker/sash39/nginx/tags/v1/sha256-383afd13e0bed5e82ac274f82d19ce939ccbd0b2f53a90853aa8b37a0c26edab):
```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/3-Creating-test-application/mynginx# sudo docker push sash39/nginx:v1
The push refers to repository [docker.io/sash39/nginx]
7fbbc436633f: Pushed 
16f5cd97d8ef: Pushed
28d40eb13793: Pushed
2ee64cbdc81d: Pushed
a0bde08c3815: Pushed
3be2be874bba: Pushed
fb5df5db7bbd: Pushed
eadc278e8f9e: Pushed
9dca7439e1b3: Pushed
b895814e9e64: Pushed
v1: digest: sha256:c3fe44c7dfd3ebea48fdcdf4646eec2736565dc19fe96d488b3c55d59a77585b size: 2196
```
