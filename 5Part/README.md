# Установка и настройка CI/CD
<details>
	<summary></summary>
      <br>

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

</details>

---
## Решение:

Настроим ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

### 5.1 Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.

Для автоматической сборки и docker-образа при коммите в репозиторий с тестовым приложением воспользуемся платформой CI/CD GitHub Actions.

Создадим в DockerHub секретный токен `my token`.  

<img width="950" alt="Personal Access Token" src="https://github.com/user-attachments/assets/7c58f06f-2e28-44b1-b9a7-3bf621e3e477" />


Добавим токен в `Settings -> Secrets and variables -> Actions secrets and variables` в переменную `MY_TOKEN_DOCKER_HUB`.  
В переменную `USER_DOCKER_HUB` добавим имя пользователя от Docker Hub `sash39`.   

<img width="1028" alt="Secrets for App" src="https://github.com/user-attachments/assets/0f647abc-469e-4129-a07b-f5ed7099cb2d" />



Далее, создадим `workflow` файл для автоматической сборки приложения nginx:  
Перейдем на вкладку `Actions`, выполним `New workflow`, затем `Simple workflow` (Config). Создадим файл `../.github/workflows/actions-build.yml`.  
При первом входе в раздел набираем в поисковой строке `Simple Workflow` и переходим в `Configure`  

<img width="1233" alt="Simple workflow" src="https://github.com/user-attachments/assets/e7f2138a-992a-42c6-8eca-da185a393ad7" />

[build.yml](https://github.com/sash3939/Application/blob/main/.github/workflows/build.yml)
```yml
name: Сборка Docker-образа

on:
  push:
    branches:
      - '*'
jobs:
  my_build_job:
    runs-on: ubuntu-latest

    steps:
      - name: Проверка кода
        uses: actions/checkout@v4

      - name: Вход на Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.USER_DOCKER_HUB }}
          password: ${{ secrets.MY_TOKEN_DOCKER_HUB }}

      - name: Сборка Docker-образа
        run: |
          docker build . --file Dockerfile --tag nginx:latest
          docker tag nginx:latest ${{ secrets.USER_DOCKER_HUB }}/nginx:latest

      - name: Push Docker-образа в Docker Hub
        run: |
          docker push ${{ secrets.USER_DOCKER_HUB }}/nginx:latest
```
  
Перед тем, как выполнить коммит, нам необходимо в своем приложении (заранее сделать git clone https://github.com/sash3939/Application.git к себе на локальную машину) создать манифест build.yaml, который затем отправить с помощью коммит в свой репозиторий [Application](https://github.com/sash3939/Application.git). После коммита автоматически начнется выполнение сборки образа и отправки его на DockerHub с использованием тех секретов, которые ранее мы прописали.


Перейдем в раздел **Actions**, где видим, что `Workflow file` успешно выполнился.
<img width="1277" alt="build done" src="https://github.com/user-attachments/assets/5b199a01-0365-4392-a63e-c718f83976ed" />



Лог выполнения `Workflow file`:
<details>
	<summary></summary>
      <br>

```
2025-02-07T07:23:49.4176043Z Current runner version: '2.322.0'
2025-02-07T07:23:49.4201002Z ##[group]Operating System
2025-02-07T07:23:49.4201777Z Ubuntu
2025-02-07T07:23:49.4202563Z 24.04.1
2025-02-07T07:23:49.4203066Z LTS
2025-02-07T07:23:49.4203531Z ##[endgroup]
2025-02-07T07:23:49.4204149Z ##[group]Runner Image
2025-02-07T07:23:49.4204746Z Image: ubuntu-24.04
2025-02-07T07:23:49.4205337Z Version: 20250202.1.0
2025-02-07T07:23:49.4206408Z Included Software: https://github.com/actions/runner-images/blob/ubuntu24/20250202.1/images/ubuntu/Ubuntu2404-Readme.md
2025-02-07T07:23:49.4207747Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu24%2F20250202.1
2025-02-07T07:23:49.4208693Z ##[endgroup]
2025-02-07T07:23:49.4209266Z ##[group]Runner Image Provisioner
2025-02-07T07:23:49.4209874Z 2.0.422.1
2025-02-07T07:23:49.4210433Z ##[endgroup]
2025-02-07T07:23:49.4211550Z ##[group]GITHUB_TOKEN Permissions
2025-02-07T07:23:49.4213714Z Contents: read
2025-02-07T07:23:49.4214303Z Metadata: read
2025-02-07T07:23:49.4215159Z Packages: read
2025-02-07T07:23:49.4215757Z ##[endgroup]
2025-02-07T07:23:49.4218697Z Secret source: Actions
2025-02-07T07:23:49.4219504Z Prepare workflow directory
2025-02-07T07:23:49.4523848Z Prepare all required actions
2025-02-07T07:23:49.4560041Z Getting action download info
2025-02-07T07:23:49.6156011Z ##[group]Download immutable action package 'actions/checkout@v4'
2025-02-07T07:23:49.6157221Z Version: 4.2.2
2025-02-07T07:23:49.6158213Z Digest: sha256:ccb2698953eaebd21c7bf6268a94f9c26518a7e38e27e0b83c1fe1ad049819b1
2025-02-07T07:23:49.6159453Z Source commit SHA: 11bd71901bbe5b1630ceea73d27597364c9af683
2025-02-07T07:23:49.6160241Z ##[endgroup]
2025-02-07T07:23:49.6942619Z ##[group]Download immutable action package 'docker/login-action@v2'
2025-02-07T07:23:49.6943451Z Version: 2.2.0
2025-02-07T07:23:49.6944283Z Digest: sha256:074da69a9e77797ae469f40db0f64632c02629b61bfa229f2fa803f41a464283
2025-02-07T07:23:49.6945316Z Source commit SHA: 465a07811f14bebb1938fbed4728c6a1ff8901fc
2025-02-07T07:23:49.6946070Z ##[endgroup]
2025-02-07T07:23:49.9719269Z Complete job name: my_build_job
2025-02-07T07:23:50.0477392Z ##[group]Run actions/checkout@v4
2025-02-07T07:23:50.0478322Z with:
2025-02-07T07:23:50.0478813Z   repository: ***39/Application
2025-02-07T07:23:50.0479442Z   token: ***
2025-02-07T07:23:50.0479856Z   ssh-strict: true
2025-02-07T07:23:50.0480283Z   ssh-user: git
2025-02-07T07:23:50.0480716Z   persist-credentials: true
2025-02-07T07:23:50.0481188Z   clean: true
2025-02-07T07:23:50.0481628Z   sparse-checkout-cone-mode: true
2025-02-07T07:23:50.0482436Z   fetch-depth: 1
2025-02-07T07:23:50.0482913Z   fetch-tags: false
2025-02-07T07:23:50.0483365Z   show-progress: true
2025-02-07T07:23:50.0483805Z   lfs: false
2025-02-07T07:23:50.0484206Z   submodules: false
2025-02-07T07:23:50.0484680Z   set-safe-directory: true
2025-02-07T07:23:50.0485832Z ##[endgroup]
2025-02-07T07:23:50.2223351Z Syncing repository: ***39/Application
2025-02-07T07:23:50.2225426Z ##[group]Getting Git version info
2025-02-07T07:23:50.2226377Z Working directory is '/home/runner/work/Application/Application'
2025-02-07T07:23:50.2227581Z [command]/usr/bin/git version
2025-02-07T07:23:50.2276996Z git version 2.48.1
2025-02-07T07:23:50.2304431Z ##[endgroup]
2025-02-07T07:23:50.2318019Z Temporarily overriding HOME='/home/runner/work/_temp/c44dc855-0056-428b-9e10-dc7aea74b8b1' before making global git config changes
2025-02-07T07:23:50.2320267Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T07:23:50.2330110Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T07:23:50.2364732Z Deleting the contents of '/home/runner/work/Application/Application'
2025-02-07T07:23:50.2368920Z ##[group]Initializing the repository
2025-02-07T07:23:50.2373755Z [command]/usr/bin/git init /home/runner/work/Application/Application
2025-02-07T07:23:50.2438526Z hint: Using 'master' as the name for the initial branch. This default branch name
2025-02-07T07:23:50.2439876Z hint: is subject to change. To configure the initial branch name to use in all
2025-02-07T07:23:50.2441101Z hint: of your new repositories, which will suppress this warning, call:
2025-02-07T07:23:50.2441870Z hint:
2025-02-07T07:23:50.2442954Z hint: 	git config --global init.defaultBranch <name>
2025-02-07T07:23:50.2443742Z hint:
2025-02-07T07:23:50.2444357Z hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
2025-02-07T07:23:50.2446020Z hint: 'development'. The just-created branch can be renamed via this command:
2025-02-07T07:23:50.2447404Z hint:
2025-02-07T07:23:50.2448157Z hint: 	git branch -m <name>
2025-02-07T07:23:50.2449593Z Initialized empty Git repository in /home/runner/work/Application/Application/.git/
2025-02-07T07:23:50.2456862Z [command]/usr/bin/git remote add origin https://github.com/***39/Application
2025-02-07T07:23:50.2489290Z ##[endgroup]
2025-02-07T07:23:50.2490558Z ##[group]Disabling automatic garbage collection
2025-02-07T07:23:50.2494217Z [command]/usr/bin/git config --local gc.auto 0
2025-02-07T07:23:50.2523266Z ##[endgroup]
2025-02-07T07:23:50.2524578Z ##[group]Setting up auth
2025-02-07T07:23:50.2530737Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T07:23:50.2561896Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T07:23:50.2841464Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T07:23:50.2871891Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T07:23:50.3101153Z [command]/usr/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
2025-02-07T07:23:50.3136652Z ##[endgroup]
2025-02-07T07:23:50.3138046Z ##[group]Fetching the repository
2025-02-07T07:23:50.3147113Z [command]/usr/bin/git -c protocol.version=2 fetch --no-tags --prune --no-recurse-submodules --depth=1 origin +3a2654544d72bf6d50c44000dd162216d7e6b242:refs/remotes/origin/main
2025-02-07T07:23:50.5268708Z From https://github.com/***39/Application
2025-02-07T07:23:50.5269839Z  * [new ref]         3a2654544d72bf6d50c44000dd162216d7e6b242 -> origin/main
2025-02-07T07:23:50.5295050Z ##[endgroup]
2025-02-07T07:23:50.5296327Z ##[group]Determining the checkout info
2025-02-07T07:23:50.5298064Z ##[endgroup]
2025-02-07T07:23:50.5303587Z [command]/usr/bin/git sparse-checkout disable
2025-02-07T07:23:50.5351404Z [command]/usr/bin/git config --local --unset-all extensions.worktreeConfig
2025-02-07T07:23:50.5395226Z ##[group]Checking out the ref
2025-02-07T07:23:50.5396560Z [command]/usr/bin/git checkout --progress --force -B main refs/remotes/origin/main
2025-02-07T07:23:50.5438815Z Switched to a new branch 'main'
2025-02-07T07:23:50.5442313Z branch 'main' set up to track 'origin/main'.
2025-02-07T07:23:50.5447433Z ##[endgroup]
2025-02-07T07:23:50.5481031Z [command]/usr/bin/git log -1 --format=%H
2025-02-07T07:23:50.5506344Z 3a2654544d72bf6d50c44000dd162216d7e6b242
2025-02-07T07:23:50.5711055Z ##[group]Run docker/login-action@v2
2025-02-07T07:23:50.5711647Z with:
2025-02-07T07:23:50.5712413Z   username: ***
2025-02-07T07:23:50.5712940Z   password: ***
2025-02-07T07:23:50.5713352Z   ecr: auto
2025-02-07T07:23:50.5713742Z   logout: true
2025-02-07T07:23:50.5714163Z ##[endgroup]
2025-02-07T07:23:50.6663628Z Logging into Docker Hub...
2025-02-07T07:23:50.8817908Z Login Succeeded!
2025-02-07T07:23:50.8946887Z ##[group]Run docker build . --file Dockerfile --tag nginx:latest
2025-02-07T07:23:50.8948260Z ␛[36;1mdocker build . --file Dockerfile --tag nginx:latest␛[0m
2025-02-07T07:23:50.9027889Z ␛[36;1mdocker tag nginx:latest ***/nginx:latest␛[0m
2025-02-07T07:23:50.9067099Z shell: /usr/bin/bash -e {0}
2025-02-07T07:23:50.9068055Z ##[endgroup]
2025-02-07T07:23:51.4293359Z #0 building with "default" instance using docker driver
2025-02-07T07:23:51.4295162Z 
2025-02-07T07:23:51.4295518Z #1 [internal] load build definition from Dockerfile
2025-02-07T07:23:51.4296343Z #1 transferring dockerfile: 99B done
2025-02-07T07:23:51.4296786Z #1 DONE 0.0s
2025-02-07T07:23:51.4296984Z 
2025-02-07T07:23:51.4297260Z #2 [auth] library/nginx:pull token for registry-1.docker.io
2025-02-07T07:23:51.4297764Z #2 DONE 0.0s
2025-02-07T07:23:51.4297969Z 
2025-02-07T07:23:51.4298236Z #3 [internal] load metadata for docker.io/library/nginx:1.27-alpine
2025-02-07T07:23:52.0201032Z #3 DONE 0.8s
2025-02-07T07:23:52.1400472Z 
2025-02-07T07:23:52.1401600Z #4 [internal] load .dockerignore
2025-02-07T07:23:52.1403015Z #4 transferring context: 2B done
2025-02-07T07:23:52.1404979Z #4 DONE 0.0s
2025-02-07T07:23:52.1405470Z 
2025-02-07T07:23:52.1405741Z #5 [internal] load build context
2025-02-07T07:23:52.1406343Z #5 transferring context: 136B done
2025-02-07T07:23:52.1406926Z #5 DONE 0.0s
2025-02-07T07:23:52.1407504Z 
2025-02-07T07:23:52.1408239Z #6 [1/2] FROM docker.io/library/nginx:1.27-alpine@sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef
2025-02-07T07:23:52.1409797Z #6 resolve docker.io/library/nginx:1.27-alpine@sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef done
2025-02-07T07:23:52.1411521Z #6 sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 0B / 1.79MB 0.1s
2025-02-07T07:23:52.1412997Z #6 sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 0B / 956B 0.1s
2025-02-07T07:23:52.1414354Z #6 sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef 10.36kB / 10.36kB done
2025-02-07T07:23:52.1415679Z #6 sha256:6666d93f054a3f4315894b76f2023f3da2fcb5ceb5f8d91625cca81623edd2da 2.50kB / 2.50kB done
2025-02-07T07:23:52.1416940Z #6 sha256:d41a14a4ecff96bdae6253ad2f58d8f258786db438307846081e8d835b984111 11.23kB / 11.23kB done
2025-02-07T07:23:52.1418178Z #6 sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 0B / 3.64MB 0.1s
2025-02-07T07:23:52.1419458Z #6 sha256:f8813b38090d755304b9b62b790b0f19cd7eee409c3d0a3d495411be8eb35408 627B / 627B 0.1s done
2025-02-07T07:23:52.2909202Z #6 sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 1.79MB / 1.79MB 0.1s done
2025-02-07T07:23:52.2911648Z #6 sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 956B / 956B 0.2s done
2025-02-07T07:23:52.2913469Z #6 sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 3.64MB / 3.64MB 0.2s done
2025-02-07T07:23:52.2914733Z #6 extracting sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 0.1s done
2025-02-07T07:23:52.2915821Z #6 sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 0B / 404B 0.2s
2025-02-07T07:23:52.2916854Z #6 sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 0B / 1.21kB 0.2s
2025-02-07T07:23:52.2917795Z #6 sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 0B / 1.40kB 0.2s
2025-02-07T07:23:52.4393758Z #6 sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 404B / 404B 0.2s done
2025-02-07T07:23:52.4394998Z #6 sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 1.21kB / 1.21kB 0.2s done
2025-02-07T07:23:52.4396148Z #6 sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 1.40kB / 1.40kB 0.2s done
2025-02-07T07:23:52.4397252Z #6 extracting sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 0.1s done
2025-02-07T07:23:52.4398791Z #6 sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 15.37MB / 15.37MB 0.3s done
2025-02-07T07:23:52.5502846Z #6 extracting sha256:f8813b38090d755304b9b62b790b0f19cd7eee409c3d0a3d495411be8eb35408 done
2025-02-07T07:23:52.5505351Z #6 extracting sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 done
2025-02-07T07:23:52.5509330Z #6 extracting sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 done
2025-02-07T07:23:52.5513897Z #6 extracting sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708
2025-02-07T07:23:52.6746994Z #6 extracting sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 done
2025-02-07T07:23:52.6748116Z #6 extracting sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 done
2025-02-07T07:23:52.6749672Z #6 extracting sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 0.1s
2025-02-07T07:23:52.9971451Z #6 extracting sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 0.3s done
2025-02-07T07:23:52.9972457Z #6 DONE 1.0s
2025-02-07T07:23:53.1593748Z 
2025-02-07T07:23:53.1594270Z #7 [2/2] COPY index.html /usr/share/nginx/html
2025-02-07T07:23:54.0046443Z #7 DONE 0.0s
2025-02-07T07:23:54.0046693Z 
2025-02-07T07:23:54.0046812Z #8 exporting to image
2025-02-07T07:23:54.0047127Z #8 exporting layers
2025-02-07T07:23:54.0047458Z #8 exporting layers 1.0s done
2025-02-07T07:23:54.0308791Z #8 writing image sha256:5fbc458ff22feff39445d186c5c29b51b2bd0174a80f4fbdd55a0e0f4045cd52 done
2025-02-07T07:23:54.0309681Z #8 naming to docker.io/library/nginx:latest done
2025-02-07T07:23:54.0310153Z #8 DONE 1.0s
2025-02-07T07:23:54.0541047Z ##[group]Run docker push ***/nginx:latest
2025-02-07T07:23:54.0541451Z ␛[36;1mdocker push ***/nginx:latest␛[0m
2025-02-07T07:23:54.0570566Z shell: /usr/bin/bash -e {0}
2025-02-07T07:23:54.0570840Z ##[endgroup]
2025-02-07T07:23:54.0757176Z The push refers to repository [docker.io/***/nginx]
2025-02-07T07:23:54.1016048Z e08d2c0eede0: Preparing
2025-02-07T07:23:54.1016752Z 72120687062c: Preparing
2025-02-07T07:23:54.1017179Z 469fc702bc62: Preparing
2025-02-07T07:23:54.1017580Z 74964efcae21: Preparing
2025-02-07T07:23:54.1017967Z ad4f5bc987ca: Preparing
2025-02-07T07:23:54.1018405Z ef050c9a03b5: Preparing
2025-02-07T07:23:54.1018811Z 83c20bc61eb8: Preparing
2025-02-07T07:23:54.1019198Z 1024e8977b69: Preparing
2025-02-07T07:23:54.1019582Z a0904247e36a: Preparing
2025-02-07T07:23:54.1020012Z ef050c9a03b5: Waiting
2025-02-07T07:23:54.1020462Z 83c20bc61eb8: Waiting
2025-02-07T07:23:54.1020802Z 1024e8977b69: Waiting
2025-02-07T07:23:54.1021074Z a0904247e36a: Waiting
2025-02-07T07:23:54.2142751Z 74964efcae21: Layer already exists
2025-02-07T07:23:54.2254308Z ad4f5bc987ca: Layer already exists
2025-02-07T07:23:54.2266171Z 72120687062c: Layer already exists
2025-02-07T07:23:54.2282171Z 469fc702bc62: Layer already exists
2025-02-07T07:23:54.2878018Z ef050c9a03b5: Layer already exists
2025-02-07T07:23:54.3044791Z 83c20bc61eb8: Layer already exists
2025-02-07T07:23:54.3108349Z 1024e8977b69: Layer already exists
2025-02-07T07:23:54.3259332Z a0904247e36a: Layer already exists
2025-02-07T07:23:55.2640610Z e08d2c0eede0: Pushed
2025-02-07T07:23:57.0308108Z latest: digest: sha256:759c34cc8bbf237ff2e55d2f8c413d4f28a5d0f6dbc8d4cd75bb4dbd7c9b3ceb size: 2196
2025-02-07T07:23:57.0393605Z Post job cleanup.
2025-02-07T07:23:57.1367552Z [command]/usr/bin/docker logout 
2025-02-07T07:23:57.1489605Z Removing login credentials for https://index.docker.io/v1/
2025-02-07T07:23:57.1627114Z Post job cleanup.
2025-02-07T07:23:57.2566758Z [command]/usr/bin/git version
2025-02-07T07:23:57.2603209Z git version 2.48.1
2025-02-07T07:23:57.2647026Z Temporarily overriding HOME='/home/runner/work/_temp/dd89ece6-b9c9-4d8f-a08e-03701549de71' before making global git config changes
2025-02-07T07:23:57.2648348Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T07:23:57.2653619Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T07:23:57.2690005Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T07:23:57.2723404Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T07:23:57.2961763Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T07:23:57.2982906Z http.https://github.com/.extraheader
2025-02-07T07:23:57.2999106Z [command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
2025-02-07T07:23:57.3031556Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T07:23:57.3370175Z Cleaning up orphan processes
```

</details>


В свою очередь на `docker hub` появляется загруженный образ:  

<img width="1268" alt="change Docker hub after workflow" src="https://github.com/user-attachments/assets/78486c0a-7639-4142-ab96-7953dffdb70e" />


[ССЫЛКА_НА_ДОКЕРХАБ](https://hub.docker.com/repository/docker/sash39/nginx/general)

---
## 5.2 Автоматический деплой нового docker образа.  

В данном разделе настроим автоматичесикй деплой нового докер образа  
В первую очередь в нашем случае нам необходимо настроить подключение к кластеру
Для этого создадим 4 основные переменные, в значения которых внесем данные от нашего сервисного аккаунта (отдельный аккаунт для Kubernetes) и парметры id  

Создаем переменные

```
• YC_SA_KEY — IAM ключ сервисного аккаунта в формате JSON.

• YC_CLOUD_ID — ID облака в Яндекс Облаке.

• YC_FOLDER_ID — ID каталога в Яндекс Облаке.

• YC_CLUSTER_ID — ID Kubernetes-кластера в Яндекс Облаке.
```

<img width="988" alt="YC keys and IDs for deploy" src="https://github.com/user-attachments/assets/174318c8-97a2-4ac2-8996-827db961e73c" />


Cоздадим `workflow` файл для автоматической сборки приложения nginx при создании тега, а также его автоматического развертывания в кластер Kubernetes.  

[deploy.yml](https://github.com/sash3939/Application/blob/main/.github/workflows/deploy.yml)


```yml

name: Deploy to Yandex Cloud Kubernetes

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      # Шаг 1: Клонирование репозитория
      - name: Checkout code
        uses: actions/checkout@v4

      # Шаг 2: Установка Yandex CLI
      - name: Install Yandex Cloud CLI
        run: |
          curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
          echo "${HOME}/yandex-cloud/bin" >> $GITHUB_PATH

      # Шаг 3: Аутентификация в Yandex Cloud
      - name: Authenticate in Yandex Cloud
        env:
          YC_SERVICE_ACCOUNT_KEY: ${{ secrets.YC_SERVICE_ACCOUNT_KEY }}
          YC_CLOUD_ID: ${{ secrets.YC_CLOUD_ID }}
          YC_FOLDER_ID: ${{ secrets.YC_FOLDER_ID }}
        run: |
          echo "${YC_SERVICE_ACCOUNT_KEY}" > yc-sa-key.json
          yc config set service-account-key yc-sa-key.json
          yc config set cloud-id "${YC_CLOUD_ID}"
          yc config set folder-id "${YC_FOLDER_ID}"

      # Шаг 4: Установка kubectl
      - name: Install kubectl
        run: |
          sudo apt-get update
          sudo apt-get install -y kubectl

      # Шаг 5: Настройка подключения к Kubernetes
      - name: Configure kubectl
        env:
          YC_SERVICE_ACCOUNT_KEY: ${{ secrets.YC_SERVICE_ACCOUNT_KEY }}
          YC_CLUSTER_ID: ${{ secrets.YC_CLUSTER_ID }}
        run: |
          yc managed-kubernetes cluster get-credentials --id "${YC_CLUSTER_ID}" --external
          kubectl get nodes

      # Шаг 6: Деплой приложения
      - name: Deploy to Kubernetes
        run: |
          kubectl config view
          kubectl get nodes
          kubectl get pods --all-namespaces
          kubectl create deployment nginx --image=sash39/nginx:1.0.6
      - name: Expose Nginx Deployment
        run: |
          kubectl expose deployment nginx --type=LoadBalancer --port=80 --target-port=80

```
  
Выполним commit c лэйблом `v1.0.x` или `latest`.

Перейдем в раздел **Actions**, где видим, что `Workflow file` успешно выполнился.

<img width="1222" alt="after deploy github" src="https://github.com/user-attachments/assets/c20c2928-a9b4-4f61-9ceb-248abe2b4fbe" />  

Результат работы деплоя
<img width="1273" alt="deploy done" src="https://github.com/user-attachments/assets/3a11b530-0951-4077-ac5b-7e04b323e51e" />  

Лог выполнения `Workflow file` jobs `build`:
<details>
        <summary></summary>
      <br>

```
2025-02-07T07:23:49.4176043Z Current runner version: '2.322.0'
2025-02-07T07:23:49.4201002Z ##[group]Operating System
2025-02-07T07:23:49.4201777Z Ubuntu
2025-02-07T07:23:49.4202563Z 24.04.1
2025-02-07T07:23:49.4203066Z LTS
2025-02-07T07:23:49.4203531Z ##[endgroup]
2025-02-07T07:23:49.4204149Z ##[group]Runner Image
2025-02-07T07:23:49.4204746Z Image: ubuntu-24.04
2025-02-07T07:23:49.4205337Z Version: 20250202.1.0
2025-02-07T07:23:49.4206408Z Included Software: https://github.com/actions/runner-images/blob/ubuntu24/20250202.1/images/ubuntu/Ubuntu2404-Readme.md
2025-02-07T07:23:49.4207747Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu24%2F20250202.1
2025-02-07T07:23:49.4208693Z ##[endgroup]
2025-02-07T07:23:49.4209266Z ##[group]Runner Image Provisioner
2025-02-07T07:23:49.4209874Z 2.0.422.1
2025-02-07T07:23:49.4210433Z ##[endgroup]
2025-02-07T07:23:49.4211550Z ##[group]GITHUB_TOKEN Permissions
2025-02-07T07:23:49.4213714Z Contents: read
2025-02-07T07:23:49.4214303Z Metadata: read
2025-02-07T07:23:49.4215159Z Packages: read
2025-02-07T07:23:49.4215757Z ##[endgroup]
2025-02-07T07:23:49.4218697Z Secret source: Actions
2025-02-07T07:23:49.4219504Z Prepare workflow directory
2025-02-07T07:23:49.4523848Z Prepare all required actions
2025-02-07T07:23:49.4560041Z Getting action download info
2025-02-07T07:23:49.6156011Z ##[group]Download immutable action package 'actions/checkout@v4'
2025-02-07T07:23:49.6157221Z Version: 4.2.2
2025-02-07T07:23:49.6158213Z Digest: sha256:ccb2698953eaebd21c7bf6268a94f9c26518a7e38e27e0b83c1fe1ad049819b1
2025-02-07T07:23:49.6159453Z Source commit SHA: 11bd71901bbe5b1630ceea73d27597364c9af683
2025-02-07T07:23:49.6160241Z ##[endgroup]
2025-02-07T07:23:49.6942619Z ##[group]Download immutable action package 'docker/login-action@v2'
2025-02-07T07:23:49.6943451Z Version: 2.2.0
2025-02-07T07:23:49.6944283Z Digest: sha256:074da69a9e77797ae469f40db0f64632c02629b61bfa229f2fa803f41a464283
2025-02-07T07:23:49.6945316Z Source commit SHA: 465a07811f14bebb1938fbed4728c6a1ff8901fc
2025-02-07T07:23:49.6946070Z ##[endgroup]
2025-02-07T07:23:49.9719269Z Complete job name: my_build_job
2025-02-07T07:23:50.0477392Z ##[group]Run actions/checkout@v4
2025-02-07T07:23:50.0478322Z with:
2025-02-07T07:23:50.0478813Z   repository: ***39/Application
2025-02-07T07:23:50.0479442Z   token: ***
2025-02-07T07:23:50.0479856Z   ssh-strict: true
2025-02-07T07:23:50.0480283Z   ssh-user: git
2025-02-07T07:23:50.0480716Z   persist-credentials: true
2025-02-07T07:23:50.0481188Z   clean: true
2025-02-07T07:23:50.0481628Z   sparse-checkout-cone-mode: true
2025-02-07T07:23:50.0482436Z   fetch-depth: 1
2025-02-07T07:23:50.0482913Z   fetch-tags: false
2025-02-07T07:23:50.0483365Z   show-progress: true
2025-02-07T07:23:50.0483805Z   lfs: false
2025-02-07T07:23:50.0484206Z   submodules: false
2025-02-07T07:23:50.0484680Z   set-safe-directory: true
2025-02-07T07:23:50.0485832Z ##[endgroup]
2025-02-07T07:23:50.2223351Z Syncing repository: ***39/Application
2025-02-07T07:23:50.2225426Z ##[group]Getting Git version info
2025-02-07T07:23:50.2226377Z Working directory is '/home/runner/work/Application/Application'
2025-02-07T07:23:50.2227581Z [command]/usr/bin/git version
2025-02-07T07:23:50.2276996Z git version 2.48.1
2025-02-07T07:23:50.2304431Z ##[endgroup]
2025-02-07T07:23:50.2318019Z Temporarily overriding HOME='/home/runner/work/_temp/c44dc855-0056-428b-9e10-dc7aea74b8b1' before making global git config changes
2025-02-07T07:23:50.2320267Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T07:23:50.2330110Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T07:23:50.2364732Z Deleting the contents of '/home/runner/work/Application/Application'
2025-02-07T07:23:50.2368920Z ##[group]Initializing the repository
2025-02-07T07:23:50.2373755Z [command]/usr/bin/git init /home/runner/work/Application/Application
2025-02-07T07:23:50.2438526Z hint: Using 'master' as the name for the initial branch. This default branch name
2025-02-07T07:23:50.2439876Z hint: is subject to change. To configure the initial branch name to use in all
2025-02-07T07:23:50.2441101Z hint: of your new repositories, which will suppress this warning, call:
2025-02-07T07:23:50.2441870Z hint:
2025-02-07T07:23:50.2442954Z hint: 	git config --global init.defaultBranch <name>
2025-02-07T07:23:50.2443742Z hint:
2025-02-07T07:23:50.2444357Z hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
2025-02-07T07:23:50.2446020Z hint: 'development'. The just-created branch can be renamed via this command:
2025-02-07T07:23:50.2447404Z hint:
2025-02-07T07:23:50.2448157Z hint: 	git branch -m <name>
2025-02-07T07:23:50.2449593Z Initialized empty Git repository in /home/runner/work/Application/Application/.git/
2025-02-07T07:23:50.2456862Z [command]/usr/bin/git remote add origin https://github.com/***39/Application
2025-02-07T07:23:50.2489290Z ##[endgroup]
2025-02-07T07:23:50.2490558Z ##[group]Disabling automatic garbage collection
2025-02-07T07:23:50.2494217Z [command]/usr/bin/git config --local gc.auto 0
2025-02-07T07:23:50.2523266Z ##[endgroup]
2025-02-07T07:23:50.2524578Z ##[group]Setting up auth
2025-02-07T07:23:50.2530737Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T07:23:50.2561896Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T07:23:50.2841464Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T07:23:50.2871891Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T07:23:50.3101153Z [command]/usr/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
2025-02-07T07:23:50.3136652Z ##[endgroup]
2025-02-07T07:23:50.3138046Z ##[group]Fetching the repository
2025-02-07T07:23:50.3147113Z [command]/usr/bin/git -c protocol.version=2 fetch --no-tags --prune --no-recurse-submodules --depth=1 origin +3a2654544d72bf6d50c44000dd162216d7e6b242:refs/remotes/origin/main
2025-02-07T07:23:50.5268708Z From https://github.com/***39/Application
2025-02-07T07:23:50.5269839Z  * [new ref]         3a2654544d72bf6d50c44000dd162216d7e6b242 -> origin/main
2025-02-07T07:23:50.5295050Z ##[endgroup]
2025-02-07T07:23:50.5296327Z ##[group]Determining the checkout info
2025-02-07T07:23:50.5298064Z ##[endgroup]
2025-02-07T07:23:50.5303587Z [command]/usr/bin/git sparse-checkout disable
2025-02-07T07:23:50.5351404Z [command]/usr/bin/git config --local --unset-all extensions.worktreeConfig
2025-02-07T07:23:50.5395226Z ##[group]Checking out the ref
2025-02-07T07:23:50.5396560Z [command]/usr/bin/git checkout --progress --force -B main refs/remotes/origin/main
2025-02-07T07:23:50.5438815Z Switched to a new branch 'main'
2025-02-07T07:23:50.5442313Z branch 'main' set up to track 'origin/main'.
2025-02-07T07:23:50.5447433Z ##[endgroup]
2025-02-07T07:23:50.5481031Z [command]/usr/bin/git log -1 --format=%H
2025-02-07T07:23:50.5506344Z 3a2654544d72bf6d50c44000dd162216d7e6b242
2025-02-07T07:23:50.5711055Z ##[group]Run docker/login-action@v2
2025-02-07T07:23:50.5711647Z with:
2025-02-07T07:23:50.5712413Z   username: ***
2025-02-07T07:23:50.5712940Z   password: ***
2025-02-07T07:23:50.5713352Z   ecr: auto
2025-02-07T07:23:50.5713742Z   logout: true
2025-02-07T07:23:50.5714163Z ##[endgroup]
2025-02-07T07:23:50.6663628Z Logging into Docker Hub...
2025-02-07T07:23:50.8817908Z Login Succeeded!
2025-02-07T07:23:50.8946887Z ##[group]Run docker build . --file Dockerfile --tag nginx:latest
2025-02-07T07:23:50.8948260Z ␛[36;1mdocker build . --file Dockerfile --tag nginx:latest␛[0m
2025-02-07T07:23:50.9027889Z ␛[36;1mdocker tag nginx:latest ***/nginx:latest␛[0m
2025-02-07T07:23:50.9067099Z shell: /usr/bin/bash -e {0}
2025-02-07T07:23:50.9068055Z ##[endgroup]
2025-02-07T07:23:51.4293359Z #0 building with "default" instance using docker driver
2025-02-07T07:23:51.4295162Z 
2025-02-07T07:23:51.4295518Z #1 [internal] load build definition from Dockerfile
2025-02-07T07:23:51.4296343Z #1 transferring dockerfile: 99B done
2025-02-07T07:23:51.4296786Z #1 DONE 0.0s
2025-02-07T07:23:51.4296984Z 
2025-02-07T07:23:51.4297260Z #2 [auth] library/nginx:pull token for registry-1.docker.io
2025-02-07T07:23:51.4297764Z #2 DONE 0.0s
2025-02-07T07:23:51.4297969Z 
2025-02-07T07:23:51.4298236Z #3 [internal] load metadata for docker.io/library/nginx:1.27-alpine
2025-02-07T07:23:52.0201032Z #3 DONE 0.8s
2025-02-07T07:23:52.1400472Z 
2025-02-07T07:23:52.1401600Z #4 [internal] load .dockerignore
2025-02-07T07:23:52.1403015Z #4 transferring context: 2B done
2025-02-07T07:23:52.1404979Z #4 DONE 0.0s
2025-02-07T07:23:52.1405470Z 
2025-02-07T07:23:52.1405741Z #5 [internal] load build context
2025-02-07T07:23:52.1406343Z #5 transferring context: 136B done
2025-02-07T07:23:52.1406926Z #5 DONE 0.0s
2025-02-07T07:23:52.1407504Z 
2025-02-07T07:23:52.1408239Z #6 [1/2] FROM docker.io/library/nginx:1.27-alpine@sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef
2025-02-07T07:23:52.1409797Z #6 resolve docker.io/library/nginx:1.27-alpine@sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef done
2025-02-07T07:23:52.1411521Z #6 sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 0B / 1.79MB 0.1s
2025-02-07T07:23:52.1412997Z #6 sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 0B / 956B 0.1s
2025-02-07T07:23:52.1414354Z #6 sha256:b471bb609adc83f73c2d95148cf1bd683408739a3c09c0afc666ea2af0037aef 10.36kB / 10.36kB done
2025-02-07T07:23:52.1415679Z #6 sha256:6666d93f054a3f4315894b76f2023f3da2fcb5ceb5f8d91625cca81623edd2da 2.50kB / 2.50kB done
2025-02-07T07:23:52.1416940Z #6 sha256:d41a14a4ecff96bdae6253ad2f58d8f258786db438307846081e8d835b984111 11.23kB / 11.23kB done
2025-02-07T07:23:52.1418178Z #6 sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 0B / 3.64MB 0.1s
2025-02-07T07:23:52.1419458Z #6 sha256:f8813b38090d755304b9b62b790b0f19cd7eee409c3d0a3d495411be8eb35408 627B / 627B 0.1s done
2025-02-07T07:23:52.2909202Z #6 sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 1.79MB / 1.79MB 0.1s done
2025-02-07T07:23:52.2911648Z #6 sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 956B / 956B 0.2s done
2025-02-07T07:23:52.2913469Z #6 sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 3.64MB / 3.64MB 0.2s done
2025-02-07T07:23:52.2914733Z #6 extracting sha256:1f3e46996e2966e4faa5846e56e76e3748b7315e2ded61476c24403d592134f0 0.1s done
2025-02-07T07:23:52.2915821Z #6 sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 0B / 404B 0.2s
2025-02-07T07:23:52.2916854Z #6 sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 0B / 1.21kB 0.2s
2025-02-07T07:23:52.2917795Z #6 sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 0B / 1.40kB 0.2s
2025-02-07T07:23:52.4393758Z #6 sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 404B / 404B 0.2s done
2025-02-07T07:23:52.4394998Z #6 sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 1.21kB / 1.21kB 0.2s done
2025-02-07T07:23:52.4396148Z #6 sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 1.40kB / 1.40kB 0.2s done
2025-02-07T07:23:52.4397252Z #6 extracting sha256:5215a08fb124932f41461b5da64ff183d8772c8cfa6d2ba64447f60275113f1b 0.1s done
2025-02-07T07:23:52.4398791Z #6 sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 15.37MB / 15.37MB 0.3s done
2025-02-07T07:23:52.5502846Z #6 extracting sha256:f8813b38090d755304b9b62b790b0f19cd7eee409c3d0a3d495411be8eb35408 done
2025-02-07T07:23:52.5505351Z #6 extracting sha256:9f41882e104d5e4b0e443fc387e440da00594e400a8c6c8d426e86a910e11084 done
2025-02-07T07:23:52.5509330Z #6 extracting sha256:e92b9802c411990b7ff95ce238004213125726f1586227fe2665b765cd833602 done
2025-02-07T07:23:52.5513897Z #6 extracting sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708
2025-02-07T07:23:52.6746994Z #6 extracting sha256:4b56e0e1b50da94d716fc880809f96d5cb2751e0d9d9c680ae6c60e0f9239708 done
2025-02-07T07:23:52.6748116Z #6 extracting sha256:5281c445f8b7ca564e8124519f166a63c67a38074755a2d72738be7800dbbc78 done
2025-02-07T07:23:52.6749672Z #6 extracting sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 0.1s
2025-02-07T07:23:52.9971451Z #6 extracting sha256:a53100808f8943a9ff14b4843807b4141cca47498c4283d6aab09b76d9f77413 0.3s done
2025-02-07T07:23:52.9972457Z #6 DONE 1.0s
2025-02-07T07:23:53.1593748Z 
2025-02-07T07:23:53.1594270Z #7 [2/2] COPY index.html /usr/share/nginx/html
2025-02-07T07:23:54.0046443Z #7 DONE 0.0s
2025-02-07T07:23:54.0046693Z 
2025-02-07T07:23:54.0046812Z #8 exporting to image
2025-02-07T07:23:54.0047127Z #8 exporting layers
2025-02-07T07:23:54.0047458Z #8 exporting layers 1.0s done
2025-02-07T07:23:54.0308791Z #8 writing image sha256:5fbc458ff22feff39445d186c5c29b51b2bd0174a80f4fbdd55a0e0f4045cd52 done
2025-02-07T07:23:54.0309681Z #8 naming to docker.io/library/nginx:latest done
2025-02-07T07:23:54.0310153Z #8 DONE 1.0s
2025-02-07T07:23:54.0541047Z ##[group]Run docker push ***/nginx:latest
2025-02-07T07:23:54.0541451Z ␛[36;1mdocker push ***/nginx:latest␛[0m
2025-02-07T07:23:54.0570566Z shell: /usr/bin/bash -e {0}
2025-02-07T07:23:54.0570840Z ##[endgroup]
2025-02-07T07:23:54.0757176Z The push refers to repository [docker.io/***/nginx]
2025-02-07T07:23:54.1016048Z e08d2c0eede0: Preparing
2025-02-07T07:23:54.1016752Z 72120687062c: Preparing
2025-02-07T07:23:54.1017179Z 469fc702bc62: Preparing
2025-02-07T07:23:54.1017580Z 74964efcae21: Preparing
2025-02-07T07:23:54.1017967Z ad4f5bc987ca: Preparing
2025-02-07T07:23:54.1018405Z ef050c9a03b5: Preparing
2025-02-07T07:23:54.1018811Z 83c20bc61eb8: Preparing
2025-02-07T07:23:54.1019198Z 1024e8977b69: Preparing
2025-02-07T07:23:54.1019582Z a0904247e36a: Preparing
2025-02-07T07:23:54.1020012Z ef050c9a03b5: Waiting
2025-02-07T07:23:54.1020462Z 83c20bc61eb8: Waiting
2025-02-07T07:23:54.1020802Z 1024e8977b69: Waiting
2025-02-07T07:23:54.1021074Z a0904247e36a: Waiting
2025-02-07T07:23:54.2142751Z 74964efcae21: Layer already exists
2025-02-07T07:23:54.2254308Z ad4f5bc987ca: Layer already exists
2025-02-07T07:23:54.2266171Z 72120687062c: Layer already exists
2025-02-07T07:23:54.2282171Z 469fc702bc62: Layer already exists
2025-02-07T07:23:54.2878018Z ef050c9a03b5: Layer already exists
2025-02-07T07:23:54.3044791Z 83c20bc61eb8: Layer already exists
2025-02-07T07:23:54.3108349Z 1024e8977b69: Layer already exists
2025-02-07T07:23:54.3259332Z a0904247e36a: Layer already exists
2025-02-07T07:23:55.2640610Z e08d2c0eede0: Pushed
2025-02-07T07:23:57.0308108Z latest: digest: sha256:759c34cc8bbf237ff2e55d2f8c413d4f28a5d0f6dbc8d4cd75bb4dbd7c9b3ceb size: 2196
2025-02-07T07:23:57.0393605Z Post job cleanup.
2025-02-07T07:23:57.1367552Z [command]/usr/bin/docker logout 
2025-02-07T07:23:57.1489605Z Removing login credentials for https://index.docker.io/v1/
2025-02-07T07:23:57.1627114Z Post job cleanup.
2025-02-07T07:23:57.2566758Z [command]/usr/bin/git version
2025-02-07T07:23:57.2603209Z git version 2.48.1
2025-02-07T07:23:57.2647026Z Temporarily overriding HOME='/home/runner/work/_temp/dd89ece6-b9c9-4d8f-a08e-03701549de71' before making global git config changes
2025-02-07T07:23:57.2648348Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T07:23:57.2653619Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T07:23:57.2690005Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T07:23:57.2723404Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T07:23:57.2961763Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T07:23:57.2982906Z http.https://github.com/.extraheader
2025-02-07T07:23:57.2999106Z [command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
2025-02-07T07:23:57.3031556Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T07:23:57.3370175Z Cleaning up orphan processes


```
</details>

Лог выполнения `Workflow file` jobs `deploy`:
<details>
        <summary></summary>
      <br>

```
2025-02-07T11:22:13.7334667Z Current runner version: '2.322.0'
2025-02-07T11:22:13.7361798Z ##[group]Operating System
2025-02-07T11:22:13.7362768Z Ubuntu
2025-02-07T11:22:13.7363521Z 24.04.1
2025-02-07T11:22:13.7364181Z LTS
2025-02-07T11:22:13.7364863Z ##[endgroup]
2025-02-07T11:22:13.7365604Z ##[group]Runner Image
2025-02-07T11:22:13.7366437Z Image: ubuntu-24.04
2025-02-07T11:22:13.7367179Z Version: 20250202.1.0
2025-02-07T11:22:13.7368443Z Included Software: https://github.com/actions/runner-images/blob/ubuntu24/20250202.1/images/ubuntu/Ubuntu2404-Readme.md
2025-02-07T11:22:13.7370049Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu24%2F20250202.1
2025-02-07T11:22:13.7371407Z ##[endgroup]
2025-02-07T11:22:13.7372157Z ##[group]Runner Image Provisioner
2025-02-07T11:22:13.7372978Z 2.0.422.1
2025-02-07T11:22:13.7373670Z ##[endgroup]
2025-02-07T11:22:13.7375253Z ##[group]GITHUB_TOKEN Permissions
2025-02-07T11:22:13.7377268Z Contents: read
2025-02-07T11:22:13.7378132Z Metadata: read
2025-02-07T11:22:13.7379050Z Packages: read
2025-02-07T11:22:13.7379833Z ##[endgroup]
2025-02-07T11:22:13.7383217Z Secret source: Actions
2025-02-07T11:22:13.7384138Z Prepare workflow directory
2025-02-07T11:22:13.7697936Z Prepare all required actions
2025-02-07T11:22:13.7735289Z Getting action download info
2025-02-07T11:22:13.9102600Z ##[group]Download immutable action package 'actions/checkout@v4'
2025-02-07T11:22:13.9103894Z Version: 4.2.2
2025-02-07T11:22:13.9105094Z Digest: sha256:ccb2698953eaebd21c7bf6268a94f9c26518a7e38e27e0b83c1fe1ad049819b1
2025-02-07T11:22:13.9106528Z Source commit SHA: 11bd71901bbe5b1630ceea73d27597364c9af683
2025-02-07T11:22:13.9107450Z ##[endgroup]
2025-02-07T11:22:14.0695913Z Complete job name: deploy
2025-02-07T11:22:14.1435863Z ##[group]Run actions/checkout@v4
2025-02-07T11:22:14.1436831Z with:
2025-02-07T11:22:14.1437382Z   repository: sash3939/Application
2025-02-07T11:22:14.1438184Z   token: ***
2025-02-07T11:22:14.1438720Z   ssh-strict: true
2025-02-07T11:22:14.1439264Z   ssh-user: git
2025-02-07T11:22:14.1439840Z   persist-credentials: true
2025-02-07T11:22:14.1440424Z   clean: true
2025-02-07T11:22:14.1441131Z   sparse-checkout-cone-mode: true
2025-02-07T11:22:14.1441768Z   fetch-depth: 1
2025-02-07T11:22:14.1442301Z   fetch-tags: false
2025-02-07T11:22:14.1442841Z   show-progress: true
2025-02-07T11:22:14.1443397Z   lfs: false
2025-02-07T11:22:14.1443903Z   submodules: false
2025-02-07T11:22:14.1444463Z   set-safe-directory: true
2025-02-07T11:22:14.1445280Z ##[endgroup]
2025-02-07T11:22:14.3443480Z Syncing repository: sash3939/Application
2025-02-07T11:22:14.3445387Z ##[group]Getting Git version info
2025-02-07T11:22:14.3446256Z Working directory is '/home/runner/work/Application/Application'
2025-02-07T11:22:14.3447505Z [command]/usr/bin/git version
2025-02-07T11:22:14.3517890Z git version 2.48.1
2025-02-07T11:22:14.3546663Z ##[endgroup]
2025-02-07T11:22:14.3560384Z Temporarily overriding HOME='/home/runner/work/_temp/e55997f5-b3fd-48ff-aa74-ebaa4b9c430d' before making global git config changes
2025-02-07T11:22:14.3562180Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T11:22:14.3573411Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T11:22:14.3609828Z Deleting the contents of '/home/runner/work/Application/Application'
2025-02-07T11:22:14.3613996Z ##[group]Initializing the repository
2025-02-07T11:22:14.3618140Z [command]/usr/bin/git init /home/runner/work/Application/Application
2025-02-07T11:22:14.3716294Z hint: Using 'master' as the name for the initial branch. This default branch name
2025-02-07T11:22:14.3717670Z hint: is subject to change. To configure the initial branch name to use in all
2025-02-07T11:22:14.3718911Z hint: of your new repositories, which will suppress this warning, call:
2025-02-07T11:22:14.3719699Z hint:
2025-02-07T11:22:14.3720306Z hint: 	git config --global init.defaultBranch <name>
2025-02-07T11:22:14.3721614Z hint:
2025-02-07T11:22:14.3722856Z hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
2025-02-07T11:22:14.3724895Z hint: 'development'. The just-created branch can be renamed via this command:
2025-02-07T11:22:14.3726174Z hint:
2025-02-07T11:22:14.3726695Z hint: 	git branch -m <name>
2025-02-07T11:22:14.3727594Z Initialized empty Git repository in /home/runner/work/Application/Application/.git/
2025-02-07T11:22:14.3736179Z [command]/usr/bin/git remote add origin https://github.com/sash3939/Application
2025-02-07T11:22:14.3767944Z ##[endgroup]
2025-02-07T11:22:14.3768860Z ##[group]Disabling automatic garbage collection
2025-02-07T11:22:14.3771584Z [command]/usr/bin/git config --local gc.auto 0
2025-02-07T11:22:14.3799959Z ##[endgroup]
2025-02-07T11:22:14.3801081Z ##[group]Setting up auth
2025-02-07T11:22:14.3806351Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T11:22:14.3836765Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T11:22:14.4154096Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T11:22:14.4186021Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T11:22:14.4415901Z [command]/usr/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
2025-02-07T11:22:14.4451995Z ##[endgroup]
2025-02-07T11:22:14.4453616Z ##[group]Fetching the repository
2025-02-07T11:22:14.4462453Z [command]/usr/bin/git -c protocol.version=2 fetch --no-tags --prune --no-recurse-submodules --depth=1 origin +28df84e353b8a41aa6eda968a59aec33d84e95e6:refs/remotes/origin/main
2025-02-07T11:22:14.6727668Z From https://github.com/sash3939/Application
2025-02-07T11:22:14.6729465Z  * [new ref]         28df84e353b8a41aa6eda968a59aec33d84e95e6 -> origin/main
2025-02-07T11:22:14.6756053Z ##[endgroup]
2025-02-07T11:22:14.6757717Z ##[group]Determining the checkout info
2025-02-07T11:22:14.6759874Z ##[endgroup]
2025-02-07T11:22:14.6763955Z [command]/usr/bin/git sparse-checkout disable
2025-02-07T11:22:14.6808077Z [command]/usr/bin/git config --local --unset-all extensions.worktreeConfig
2025-02-07T11:22:14.6838806Z ##[group]Checking out the ref
2025-02-07T11:22:14.6843707Z [command]/usr/bin/git checkout --progress --force -B main refs/remotes/origin/main
2025-02-07T11:22:14.6893656Z Switched to a new branch 'main'
2025-02-07T11:22:14.6897850Z branch 'main' set up to track 'origin/main'.
2025-02-07T11:22:14.6904352Z ##[endgroup]
2025-02-07T11:22:14.6942336Z [command]/usr/bin/git log -1 --format=%H
2025-02-07T11:22:14.6966535Z 28df84e353b8a41aa6eda968a59aec33d84e95e6
2025-02-07T11:22:14.7321946Z ##[group]Run curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
2025-02-07T11:22:14.7325762Z ␛[36;1mcurl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash␛[0m
2025-02-07T11:22:14.7328791Z ␛[36;1mecho "$***HOME***/yandex-cloud/bin" >> $GITHUB_PATH␛[0m
2025-02-07T11:22:14.7363737Z shell: /usr/bin/bash -e ***0***
2025-02-07T11:22:14.7364708Z ##[endgroup]
2025-02-07T11:22:14.7520217Z   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
2025-02-07T11:22:14.7524783Z                                  Dload  Upload   Total   Spent    Left  Speed
2025-02-07T11:22:14.7526330Z 
2025-02-07T11:22:15.4212921Z   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
2025-02-07T11:22:15.4215370Z   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
2025-02-07T11:22:15.4217364Z 100  9872  100  9872    0     0  14744      0 --:--:-- --:--:-- --:--:-- 14734
2025-02-07T11:22:15.8409462Z Downloading yc 0.142.0
2025-02-07T11:22:15.8481465Z   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
2025-02-07T11:22:15.8483873Z                                  Dload  Upload   Total   Spent    Left  Speed
2025-02-07T11:22:15.8485297Z 
2025-02-07T11:22:16.4390384Z   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
2025-02-07T11:22:17.4161990Z   0 97.0M    0 48834    0     0  82627      0  0:20:31 --:--:--  0:20:31 82629
2025-02-07T11:22:18.4165033Z   5 97.0M    5 5481k    0     0  3495k      0  0:00:28  0:00:01  0:00:27 3493k
2025-02-07T11:22:19.4158147Z  34 97.0M   34 33.6M    0     0  13.1M      0  0:00:07  0:00:02  0:00:05 13.1M
2025-02-07T11:22:20.4164405Z  64 97.0M   64 62.3M    0     0  17.4M      0  0:00:05  0:00:03  0:00:02 17.4M
2025-02-07T11:22:20.6231221Z  93 97.0M   93 91.0M    0     0  19.9M      0  0:00:04  0:00:04 --:--:-- 19.9M
2025-02-07T11:22:20.6231965Z 100 97.0M  100 97.0M    0     0  20.3M      0  0:00:04  0:00:04 --:--:-- 23.1M
2025-02-07T11:22:20.7445065Z Yandex Cloud CLI 0.142.0 linux/amd64
2025-02-07T11:22:20.8876984Z 
2025-02-07T11:22:20.8877744Z yc PATH has been added to your '/home/runner/.bashrc' profile
2025-02-07T11:22:20.8902987Z yc bash completion has been added to your '/home/runner/.bashrc' profile.
2025-02-07T11:22:21.1461598Z To complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/runner/.bashrc"' in the current one
2025-02-07T11:22:21.1480171Z Now we have zsh completion. Type "echo 'source /home/runner/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install it
2025-02-07T11:22:21.1531634Z ##[group]Run echo "$***YC_SERVICE_ACCOUNT_KEY***" > yc-sa-key.json
2025-02-07T11:22:21.1532219Z ␛[36;1mecho "$***YC_SERVICE_ACCOUNT_KEY***" > yc-sa-key.json␛[0m
2025-02-07T11:22:21.1532658Z ␛[36;1myc config set service-account-key yc-sa-key.json␛[0m
2025-02-07T11:22:21.1533054Z ␛[36;1myc config set cloud-id "$***YC_CLOUD_ID***"␛[0m
2025-02-07T11:22:21.1533443Z ␛[36;1myc config set folder-id "$***YC_FOLDER_ID***"␛[0m
2025-02-07T11:22:21.1564786Z shell: /usr/bin/bash -e ***0***
2025-02-07T11:22:21.1565104Z env:
2025-02-07T11:22:21.1575061Z   YC_SERVICE_ACCOUNT_KEY: ***
2025-02-07T11:22:21.1575413Z   YC_CLOUD_ID: ***
2025-02-07T11:22:21.1575703Z   YC_FOLDER_ID: ***
2025-02-07T11:22:21.1575954Z ##[endgroup]
2025-02-07T11:22:21.5150284Z ##[group]Run sudo apt-get update
2025-02-07T11:22:21.5150664Z ␛[36;1msudo apt-get update␛[0m
2025-02-07T11:22:21.5151288Z ␛[36;1msudo apt-get install -y kubectl␛[0m
2025-02-07T11:22:21.5179302Z shell: /usr/bin/bash -e ***0***
2025-02-07T11:22:21.5179615Z ##[endgroup]
2025-02-07T11:22:21.5932439Z Get:1 file:/etc/apt/apt-mirrors.txt Mirrorlist [142 B]
2025-02-07T11:22:21.6265329Z Hit:2 http://azure.archive.ubuntu.com/ubuntu noble InRelease
2025-02-07T11:22:21.6266840Z Hit:6 https://packages.microsoft.com/repos/azure-cli noble InRelease
2025-02-07T11:22:21.6281583Z Get:7 https://packages.microsoft.com/ubuntu/24.04/prod noble InRelease [3600 B]
2025-02-07T11:22:21.6282826Z Get:3 http://azure.archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
2025-02-07T11:22:21.6331260Z Get:4 http://azure.archive.ubuntu.com/ubuntu noble-backports InRelease [126 kB]
2025-02-07T11:22:21.6355629Z Get:5 http://azure.archive.ubuntu.com/ubuntu noble-security InRelease [126 kB]
2025-02-07T11:22:21.8023818Z Get:8 https://packages.microsoft.com/ubuntu/24.04/prod noble/main arm64 Packages [12.8 kB]
2025-02-07T11:22:21.8155384Z Get:9 https://packages.microsoft.com/ubuntu/24.04/prod noble/main amd64 Packages [20.9 kB]
2025-02-07T11:22:21.8551341Z Get:10 http://azure.archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages [853 kB]
2025-02-07T11:22:21.8619328Z Get:11 http://azure.archive.ubuntu.com/ubuntu noble-updates/main Translation-en [193 kB]
2025-02-07T11:22:21.8645411Z Get:12 http://azure.archive.ubuntu.com/ubuntu noble-updates/main amd64 Components [151 kB]
2025-02-07T11:22:21.8672597Z Get:13 http://azure.archive.ubuntu.com/ubuntu noble-updates/universe amd64 Packages [1012 kB]
2025-02-07T11:22:21.8736615Z Get:14 http://azure.archive.ubuntu.com/ubuntu noble-updates/universe Translation-en [253 kB]
2025-02-07T11:22:21.8754923Z Get:15 http://azure.archive.ubuntu.com/ubuntu noble-updates/universe amd64 Components [363 kB]
2025-02-07T11:22:21.8813180Z Get:16 http://azure.archive.ubuntu.com/ubuntu noble-updates/restricted amd64 Packages [635 kB]
2025-02-07T11:22:21.8858214Z Get:17 http://azure.archive.ubuntu.com/ubuntu noble-updates/restricted Translation-en [123 kB]
2025-02-07T11:22:21.8875967Z Get:18 http://azure.archive.ubuntu.com/ubuntu noble-updates/restricted amd64 Components [212 B]
2025-02-07T11:22:21.8885645Z Get:19 http://azure.archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Components [940 B]
2025-02-07T11:22:21.9561575Z Get:20 http://azure.archive.ubuntu.com/ubuntu noble-backports/main amd64 Components [208 B]
2025-02-07T11:22:21.9576866Z Get:21 http://azure.archive.ubuntu.com/ubuntu noble-backports/universe amd64 Components [17.7 kB]
2025-02-07T11:22:21.9593546Z Get:22 http://azure.archive.ubuntu.com/ubuntu noble-backports/restricted amd64 Components [216 B]
2025-02-07T11:22:21.9602533Z Get:23 http://azure.archive.ubuntu.com/ubuntu noble-backports/multiverse amd64 Components [212 B]
2025-02-07T11:22:21.9718288Z Get:24 http://azure.archive.ubuntu.com/ubuntu noble-security/main amd64 Packages [618 kB]
2025-02-07T11:22:21.9765049Z Get:25 http://azure.archive.ubuntu.com/ubuntu noble-security/main Translation-en [118 kB]
2025-02-07T11:22:21.9788320Z Get:26 http://azure.archive.ubuntu.com/ubuntu noble-security/main amd64 Components [8968 B]
2025-02-07T11:22:21.9802256Z Get:27 http://azure.archive.ubuntu.com/ubuntu noble-security/universe amd64 Packages [803 kB]
2025-02-07T11:22:21.9850544Z Get:28 http://azure.archive.ubuntu.com/ubuntu noble-security/universe amd64 Components [52.0 kB]
2025-02-07T11:22:21.9864030Z Get:29 http://azure.archive.ubuntu.com/ubuntu noble-security/restricted amd64 Packages [625 kB]
2025-02-07T11:22:21.9928999Z Get:30 http://azure.archive.ubuntu.com/ubuntu noble-security/restricted Translation-en [121 kB]
2025-02-07T11:22:21.9948970Z Get:31 http://azure.archive.ubuntu.com/ubuntu noble-security/restricted amd64 Components [212 B]
2025-02-07T11:22:21.9959927Z Get:32 http://azure.archive.ubuntu.com/ubuntu noble-security/multiverse amd64 Components [212 B]
2025-02-07T11:22:27.5577830Z Fetched 6364 kB in 1s (6915 kB/s)
2025-02-07T11:22:28.1607699Z Reading package lists...
2025-02-07T11:22:28.1929128Z Reading package lists...
2025-02-07T11:22:28.3289910Z Building dependency tree...
2025-02-07T11:22:28.3297677Z Reading state information...
2025-02-07T11:22:28.4880976Z kubectl is already the newest version (1.32.1-1.1).
2025-02-07T11:22:28.4881933Z 0 upgraded, 0 newly installed, 0 to remove and 83 not upgraded.
2025-02-07T11:22:28.4927865Z ##[group]Run yc managed-kubernetes cluster get-credentials --id "$***YC_CLUSTER_ID***" --external
2025-02-07T11:22:28.4928599Z ␛[36;1myc managed-kubernetes cluster get-credentials --id "$***YC_CLUSTER_ID***" --external␛[0m
2025-02-07T11:22:28.4929078Z ␛[36;1mkubectl get nodes␛[0m
2025-02-07T11:22:28.4957022Z shell: /usr/bin/bash -e ***0***
2025-02-07T11:22:28.4957312Z env:
2025-02-07T11:22:28.4967078Z   YC_SERVICE_ACCOUNT_KEY: ***
2025-02-07T11:22:28.4967406Z   YC_CLUSTER_ID: ***
2025-02-07T11:22:28.4967687Z ##[endgroup]
2025-02-07T11:22:32.8813620Z 
2025-02-07T11:22:32.8814805Z Context 'yc-k8s-regional' was added as default to kubeconfig '/home/runner/.kube/config'.
2025-02-07T11:22:32.8816049Z Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/runner/.kube/config'.
2025-02-07T11:22:32.8816684Z 
2025-02-07T11:22:32.8817052Z Note, that authentication depends on 'yc' and its config profile 'default'.
2025-02-07T11:22:32.8818117Z To access clusters using the Kubernetes API, please use Kubernetes Service Account.
2025-02-07T11:22:34.9130453Z NAME                        STATUS   ROLES    AGE   VERSION
2025-02-07T11:22:34.9131555Z cl16u2jghkbr84e1k5j8-ibeq   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:34.9132332Z cl1dhdftsuq04nvjf7mu-ehas   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:34.9132926Z cl1o5vlf8657q696ivcd-utet   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:34.9178459Z ##[group]Run kubectl config view
2025-02-07T11:22:34.9178977Z ␛[36;1mkubectl config view␛[0m
2025-02-07T11:22:34.9179247Z ␛[36;1mkubectl get nodes␛[0m
2025-02-07T11:22:34.9179551Z ␛[36;1mkubectl get pods --all-namespaces␛[0m
2025-02-07T11:22:34.9179956Z ␛[36;1mkubectl create deployment nginx --image=sash39/nginx:1.0.6␛[0m
2025-02-07T11:22:34.9209089Z shell: /usr/bin/bash -e ***0***
2025-02-07T11:22:34.9209389Z ##[endgroup]
2025-02-07T11:22:34.9648187Z apiVersion: v1
2025-02-07T11:22:34.9649243Z clusters:
2025-02-07T11:22:34.9649622Z - cluster:
2025-02-07T11:22:34.9650056Z     certificate-authority-data: DATA+OMITTED
2025-02-07T11:22:34.9650624Z     server: https://84.201.148.13
2025-02-07T11:22:34.9651467Z   name: yc-managed-k8s-***
2025-02-07T11:22:34.9651896Z contexts:
2025-02-07T11:22:34.9652243Z - context:
2025-02-07T11:22:34.9652687Z     cluster: yc-managed-k8s-***
2025-02-07T11:22:34.9653207Z     user: yc-managed-k8s-***
2025-02-07T11:22:34.9653654Z   name: yc-k8s-regional
2025-02-07T11:22:34.9654227Z current-context: yc-k8s-regional
2025-02-07T11:22:34.9654685Z kind: Config
2025-02-07T11:22:34.9655103Z preferences: ***
2025-02-07T11:22:34.9655460Z users:
2025-02-07T11:22:34.9655868Z - name: yc-managed-k8s-***
2025-02-07T11:22:34.9656264Z   user:
2025-02-07T11:22:34.9656589Z     exec:
2025-02-07T11:22:34.9657023Z       apiVersion: client.authentication.k8s.io/v1beta1
2025-02-07T11:22:34.9657559Z       args:
2025-02-07T11:22:34.9657899Z       - k8s
2025-02-07T11:22:34.9658248Z       - create-token
2025-02-07T11:22:34.9658653Z       - --profile=default
2025-02-07T11:22:34.9659123Z       command: /home/runner/yandex-cloud/bin/yc
2025-02-07T11:22:34.9659622Z       env: null
2025-02-07T11:22:34.9660002Z       interactiveMode: IfAvailable
2025-02-07T11:22:34.9660475Z       provideClusterInfo: false
2025-02-07T11:22:36.6981371Z NAME                        STATUS   ROLES    AGE   VERSION
2025-02-07T11:22:36.7002825Z cl16u2jghkbr84e1k5j8-ibeq   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:36.7003326Z cl1dhdftsuq04nvjf7mu-ehas   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:36.7004047Z cl1o5vlf8657q696ivcd-utet   Ready    <none>   22h   v1.28.9
2025-02-07T11:22:38.4485740Z NAMESPACE        NAME                                       READY   STATUS      RESTARTS      AGE
2025-02-07T11:22:38.4486703Z default          ingress-nginx-controller-dfcb9c977-nqhrg   1/1     Running     0             17h
2025-02-07T11:22:38.4487795Z ingress-nginx    ingress-nginx-admission-create-cptt2       0/1     Completed   0             16h
2025-02-07T11:22:38.4488901Z ingress-nginx    ingress-nginx-admission-patch-456vs        0/1     Completed   0             16h
2025-02-07T11:22:38.4490004Z ingress-nginx    ingress-nginx-controller-bd7b9bbd6-8xdfz   1/1     Running     0             16h
2025-02-07T11:22:38.4491221Z kube-system      coredns-7cd467646d-bhb4j                   1/1     Running     0             22h
2025-02-07T11:22:38.4492256Z kube-system      coredns-7cd467646d-ghk4s                   1/1     Running     0             22h
2025-02-07T11:22:38.4493225Z kube-system      ip-masq-agent-5lk7l                        1/1     Running     0             22h
2025-02-07T11:22:38.4494144Z kube-system      ip-masq-agent-7vgjm                        1/1     Running     0             22h
2025-02-07T11:22:38.4495076Z kube-system      ip-masq-agent-cj9m8                        1/1     Running     0             22h
2025-02-07T11:22:38.4496056Z kube-system      kube-dns-autoscaler-74d99dd8dc-cl2w2       1/1     Running     0             22h
2025-02-07T11:22:38.4497065Z kube-system      kube-proxy-4stt7                           1/1     Running     0             22h
2025-02-07T11:22:38.4497669Z kube-system      kube-proxy-bgxbj                           1/1     Running     0             22h
2025-02-07T11:22:38.4498191Z kube-system      kube-proxy-vxjpt                           1/1     Running     0             22h
2025-02-07T11:22:38.4499140Z kube-system      metrics-server-6b5df79959-l8gdp            2/2     Running     0             22h
2025-02-07T11:22:38.4499832Z kube-system      npd-v0.8.0-5l8vz                           1/1     Running     0             22h
2025-02-07T11:22:38.4500297Z kube-system      npd-v0.8.0-cdbpt                           1/1     Running     0             22h
2025-02-07T11:22:38.4500960Z kube-system      npd-v0.8.0-lbtmr                           1/1     Running     0             22h
2025-02-07T11:22:38.4501517Z kube-system      yc-disk-csi-node-v2-2tl66                  6/6     Running     0             22h
2025-02-07T11:22:38.4502047Z kube-system      yc-disk-csi-node-v2-67gcx                  6/6     Running     0             22h
2025-02-07T11:22:38.4502575Z kube-system      yc-disk-csi-node-v2-sn67d                  6/6     Running     0             22h
2025-02-07T11:22:38.4503141Z metallb-system   controller-7499d4584d-p48rb                1/1     Running     1 (16h ago)   16h
2025-02-07T11:22:38.4503689Z metallb-system   speaker-svngd                              1/1     Running     0             16h
2025-02-07T11:22:38.4504189Z metallb-system   speaker-vqhkf                              1/1     Running     0             16h
2025-02-07T11:22:38.4504684Z metallb-system   speaker-zlvhn                              1/1     Running     0             16h
2025-02-07T11:22:38.4505221Z monitoring       alertmanager-main-0                        2/2     Running     0             20h
2025-02-07T11:22:38.4505732Z monitoring       alertmanager-main-1                        2/2     Running     0             20h
2025-02-07T11:22:38.4506241Z monitoring       alertmanager-main-2                        2/2     Running     0             20h
2025-02-07T11:22:38.4506798Z monitoring       blackbox-exporter-5dfbb6c6b5-fj4rg         3/3     Running     0             20h
2025-02-07T11:22:38.4507364Z monitoring       grafana-f46f686f8-78hs2                    1/1     Running     0             20h
2025-02-07T11:22:38.4508298Z monitoring       kube-state-metrics-57c97f6d8b-nb6wf        3/3     Running     0             20h
2025-02-07T11:22:38.4509224Z monitoring       node-exporter-42nmd                        2/2     Running     0             20h
2025-02-07T11:22:38.4510119Z monitoring       node-exporter-4t4mh                        2/2     Running     0             20h
2025-02-07T11:22:38.4511069Z monitoring       node-exporter-s8mqf                        2/2     Running     0             20h
2025-02-07T11:22:38.4511687Z monitoring       prometheus-adapter-77f8587965-vqvhs        1/1     Running     0             20h
2025-02-07T11:22:38.4512279Z monitoring       prometheus-adapter-77f8587965-w2mfx        1/1     Running     0             20h
2025-02-07T11:22:38.4512824Z monitoring       prometheus-k8s-0                           2/2     Running     0             20h
2025-02-07T11:22:38.4513309Z monitoring       prometheus-k8s-1                           2/2     Running     0             20h
2025-02-07T11:22:38.4513854Z monitoring       prometheus-operator-7bf68975ff-dzv45       2/2     Running     0             20h
2025-02-07T11:22:40.4632845Z deployment.apps/nginx created
2025-02-07T11:22:40.4732738Z Post job cleanup.
2025-02-07T11:22:40.5667328Z [command]/usr/bin/git version
2025-02-07T11:22:40.5706878Z git version 2.48.1
2025-02-07T11:22:40.5756216Z Temporarily overriding HOME='/home/runner/work/_temp/d4b3a51d-f7ff-496b-a4fb-18bea32c882a' before making global git config changes
2025-02-07T11:22:40.5757578Z Adding repository directory to the temporary git global config as a safe directory
2025-02-07T11:22:40.5762947Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/Application/Application
2025-02-07T11:22:40.5798417Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2025-02-07T11:22:40.5831262Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2025-02-07T11:22:40.6070411Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2025-02-07T11:22:40.6094115Z http.https://github.com/.extraheader
2025-02-07T11:22:40.6107054Z [command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
2025-02-07T11:22:40.6140110Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2025-02-07T11:22:40.6487688Z Cleaning up orphan processes
```
</details>


В свою очередь на `docker hub` появляется загруженный образ:  
<img width="1017" alt="log DockerHub" src="https://github.com/user-attachments/assets/9daf9caa-d842-4e08-aa9e-fd45fd6999ff" />

Интерфейс ci/cd доступен по http  
<img width="686" alt="сервис http" src="https://github.com/user-attachments/assets/f66f1d22-6f0a-4edf-8fc4-b419fc17e943" />


Ссылка на [docker hub](https://hub.docker.com/repository/docker/sash39/nginx/general)  
Ссылка на [actions](https://github.com/sash3939/Application/actions)  
Ссылка на [grafana](http://130.193.46.226:32000)  
Ссылка на приложение [app](http://158.160.38.207:31056/)


