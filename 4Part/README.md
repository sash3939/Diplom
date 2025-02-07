# Подготовка cистемы мониторинга и деплой приложения
<details>
	<summary></summary>
      <br>

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ к тестовому приложению.

</details>

---
## Решение:

### 4.1 Деплой в кластер prometheus, grafana, alertmanager, экспортер основных метрик Kubernetes.

Для решения задачи деплоя в кластер prometheus, grafana, alertmanager, экспортер основных метрик Kubernetes воспользуемся решением [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus).

Склонируем репозиторий
```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diplom/4Part#
Cloning into 'kube-prometheus'...
remote: Enumerating objects: 20739, done.
remote: Counting objects: 100% (5287/5287), done.
remote: Compressing objects: 100% (280/280), done.
remote: Total 20739 (delta 5158), reused 5013 (delta 5005), pack-reused 15452 (from 2)
Receiving objects: 100% (20739/20739), 12.95 MiB | 15.60 MiB/s, done.
Resolving deltas: 100% (14349/14349), done.
```

Переходим в папку с kube-prometheus
```bash
debian@master-1:~$ cd kube-prometheus/
```

Создадим мониторинг стека с использование конфигурации в manifests каталоге:
```bash
kubectl apply --server-side -f manifests/setup
kubectl wait \
 --for condition=Established \
 --all CustomResourceDefinition \
 --namespace=monitoring
kubectl apply -f manifests/
```

Убедимся, что маниторинг развернулся и работает:
```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diplom2/4Part# kubectl get all -n monitoring
NAME                                       READY   STATUS    RESTARTS   AGE
pod/alertmanager-main-0                    2/2     Running   0          2m8s
pod/alertmanager-main-1                    2/2     Running   0          2m8s
pod/alertmanager-main-2                    2/2     Running   0          2m8s
pod/blackbox-exporter-5dfbb6c6b5-fj4rg     3/3     Running   0          3m39s
pod/grafana-f46f686f8-78hs2                1/1     Running   0          3m2s
pod/kube-state-metrics-57c97f6d8b-nb6wf    3/3     Running   0          2m56s
pod/node-exporter-42nmd                    2/2     Running   0          2m48s
pod/node-exporter-4t4mh                    2/2     Running   0          2m48s
pod/node-exporter-s8mqf                    2/2     Running   0          2m48s
pod/prometheus-adapter-77f8587965-vqvhs    1/1     Running   0          2m26s
pod/prometheus-adapter-77f8587965-w2mfx    1/1     Running   0          2m26s
pod/prometheus-k8s-0                       2/2     Running   0          2m7s
pod/prometheus-k8s-1                       2/2     Running   0          2m7s
pod/prometheus-operator-7bf68975ff-dzv45   2/2     Running   0          2m17s

NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-main       ClusterIP   10.96.165.134   <none>        9093/TCP,8080/TCP            3m46s
service/alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   2m9s
service/blackbox-exporter       ClusterIP   10.96.253.23    <none>        9115/TCP,19115/TCP           3m42s
service/grafana                 ClusterIP   10.96.189.2     <none>        3000/TCP                     3m4s
service/kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP            2m58s
service/node-exporter           ClusterIP   None            <none>        9100/TCP                     2m50s
service/prometheus-adapter      ClusterIP   10.96.164.117   <none>        443/TCP                      2m29s
service/prometheus-k8s          ClusterIP   10.96.250.237   <none>        9090/TCP,8080/TCP            2m39s
service/prometheus-operated     ClusterIP   None            <none>        9090/TCP                     2m8s
service/prometheus-operator     ClusterIP   None            <none>        8443/TCP                     2m21s

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/node-exporter   3         3         3       3            3           kubernetes.io/os=linux   2m52s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/blackbox-exporter     1/1     1            1           3m43s
deployment.apps/grafana               1/1     1            1           3m6s
deployment.apps/kube-state-metrics    1/1     1            1           3m
deployment.apps/prometheus-adapter    2/2     2            2           2m32s
deployment.apps/prometheus-operator   1/1     1            1           2m23s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/blackbox-exporter-5dfbb6c6b5     1         1         1       3m44s
replicaset.apps/grafana-f46f686f8                1         1         1       3m7s
replicaset.apps/kube-state-metrics-57c97f6d8b    1         1         1       3m1s
replicaset.apps/prometheus-adapter-77f8587965    2         2         2       2m33s
replicaset.apps/prometheus-operator-7bf68975ff   1         1         1       2m24s

NAME                                 READY   AGE
statefulset.apps/alertmanager-main   3/3     2m10s
statefulset.apps/prometheus-k8s      2/2     2m9s

```

Чтобы подключиться снаружи к Grafana необходимо изменить порт с ClusterIP на NodePort
```bash
debian@master-1:~/kube-prometheus$ cat <<EOF > ~/patch.yml
spec:
  type: NodePort
EOF
debian@master-1:~/kube-prometheus$ kubectl patch svc grafana -n monitoring --patch-file ~/patch.yml
service/grafana patched
```

Дополнительно может понадобиться создать сервис для grafana с измененным типом на NodePort

```bash
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 11.4.0
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: http
    port: 3000
    targetPort: http
    nodePort: 32000
  selector:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus

и применить kubectl apply -f grafana-svc.yaml
```


Проверим изменения
```bash
debian@master-1:~/kube-prometheus$ kubectl get svc -n monitoring
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
alertmanager-main       ClusterIP   10.233.59.16    <none>        9093/TCP,8080/TCP            8m32s
alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   8m2s
blackbox-exporter       ClusterIP   10.233.25.225   <none>        9115/TCP,19115/TCP           8m32s
grafana                 NodePort    10.233.11.36    <none>        3000:31817/TCP               8m30s
kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP            8m29s
node-exporter           ClusterIP   None            <none>        9100/TCP                     8m29s
prometheus-adapter      ClusterIP   10.233.16.134   <none>        443/TCP                      8m27s
prometheus-k8s          ClusterIP   10.233.39.167   <none>        9090/TCP,8080/TCP            8m28s
prometheus-operated     ClusterIP   None            <none>        9090/TCP                     8m1s
prometheus-operator     ClusterIP   None            <none>        8443/TCP                     8m27s
```

Проверим Http доступ к web интерфейсу grafana:
<img width="683" alt="Grafana" src="https://github.com/user-attachments/assets/4b330418-1bc4-4963-95d5-f08cb52b0b81" />

<img width="683" alt="Grafana2" src="https://github.com/user-attachments/assets/8d3dfb5d-72ba-4545-ab94-b8dcf6e5ca9e" />

Выведем в grafana Дашборды отображающие состояние Kubernetes кластера:
<img width="692" alt="Grafana1" src="https://github.com/user-attachments/assets/f52670de-14e7-4f8a-91d4-e90d2fa648ea" />

<img width="692" alt="Cluster Healthy" src="https://github.com/user-attachments/assets/b5bb3065-38c1-4d43-a475-3be402215815" />

---
### 4.2 Деплой тестового приложения, например, nginx сервер отдающий статическую страницу.

ОДНИМ ИЗ ВАРИАНТОВ, УСТАНОВКА LB METALLB И INGRESS, ОДНАКО ДАЖЕ У ПРЕПОДАВАТЕЛЯ НЕ ЗАРАБОТАЛО С КУБСПРЕЕМ

## Описание установки MetalLB
_https://metallb.io/configuration/_
_https://metallb.io/installation/_

0. Подключаемся к Cluster Kubernetes в Yandex
Для этого в первую очередь необходимо:

- Установить и инициализовать интерфейс командной строки Yandex Cloud
yc init
- Добавить учетные данные кластера Kubernetes в конфигурационный файл kubectl:
yc managed-kubernetes cluster get-credentials --id cathadg1h6d500lr7nnc --external
- Используйте утилиту kubectl для работы с кластером Kubernetes
kubectl get pods


1. Ставим metallb после подключения к кластеру прям в том же интерфейсе на той же управляющей машине Linux.

2. Установка по манифесту или через helm:
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

Предварительно установить Helm:
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb
helm install metallb metallb/metallb -f values.yaml

Мы ставим через манифест. В варианте с kubespray ставил через Helm

4. Чтобы проверить, установился ли metallb:
kubectl get pods -n metallb-system
должны увидеть поды speaker и controller в состоянии Run

root@ubuntu-VirtualBox:/home/ubuntu/Diplom# kubectl get pods -n metallb-system
NAME                          READY   STATUS    RESTARTS      AGE
controller-7499d4584d-p48rb   1/1     Running   1 (24h ago)   24h
speaker-svngd                 1/1     Running   0             24h
speaker-vqhkf                 1/1     Running   0             24h
speaker-zlvhn                 1/1     Running   0             24h

5. Проверим, что сервисы metallB созданы
root@ubuntu-VirtualBox:/home/ubuntu/Diplom# kubectl get services -n metallb-system
   
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
metallb-webhook-service   ClusterIP   10.96.252.134   <none>        443/TCP   24h

6. Создадим yaml файл с описанием балансировщика  пула IP адресов metallb.yaml

---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool
  namespace: metallb-system
spec:
  addresses:
    - 84.201.148.13/32

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-pool
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool


7. Применим конфигурацию

kubectl apply -f metallb.yaml

root@ubuntu-VirtualBox:/home/ubuntu/Diplom#  kubectl apply -f metallb.yaml
ipaddresspool.metallb.io/pool created
l2advertisement.metallb.io/l2-pool created

8. Проверим, что metalLB корректно работает

root@ubuntu-VirtualBox:/home/ubuntu/Diplom#     kubectl get pods -n metallb-system
   
NAME                         READY   STATUS    RESTARTS   AGE
controller-bb5f47665-ngwvp   1/1     Running   0          37m
speaker-5mpdf                1/1     Running   0          37m
speaker-b8lvt                1/1     Running   0          37m
speaker-kqc27                1/1     Running   0          37m


9. Если необходимо удалить.
kubectl delete all --all -n metallb-system



Установка INGRESS NGINX
0. Установка Helm при необходимости
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

root@ubuntu-VirtualBox:/home/ubuntu/Diplom# helm version
version.BuildInfo{Version:"v3.17.0", GitCommit:"301108edc7ac2a8ba79e4ebf5701b0b6ce6a31e4", GitTreeState:"clean", GoVersion:"go1.23.4"}

1. kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

ubuntu@ubuntu-VirtualBox:/home/ubuntu/Diplom$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
Warning: resource namespaces/ingress-nginx is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
namespace/ingress-nginx configured
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created

3. Посмотрим статус контроллера ingress-nginx
ubuntu@ubuntu-VirtualBox:/home/ubuntu/Diplom$    kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-6mqbt       0/1     Completed   0          44s
ingress-nginx-admission-patch-tf6xg        0/1     Completed   0          44s
ingress-nginx-controller-d8c96cf68-5jqcw   1/1     Running     0          44s

4. Посмотрим состояние сервисов kubectl get services -n ingress-nginx
ubuntu@ubuntu-VirtualBox:/home/ubuntu/Diplom$ kubectl get services -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.96.129.218   84.201.148.13   80:31940/TCP,443:31228/TCP   23m
ingress-nginx-controller-admission   ClusterIP      10.96.220.180   <none>          443/TCP                      23m



Создадим манифесты для нашего приложения, service, deployment, namespace и ingress и применим манифест


1. Вносим изменения в манифест diplom-manifest.yaml

- Так как у нас установлен балансировщик Metallb и Ingress controller, нам необходимо в сервисе изменить тип на LoadBalancer
   
---
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
  namespace: diplom
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP

- Добавляем ресурс ingress-resource для приложения и убедитесь, что оно доступен снаружи по 80 порту
!!!Этот пункт делаем в случае, когда у нас создана зона DNS, настроена A запись, прописаны у провайдера DNC яндекса
```yml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: "nginx"
  rules:
    - host: kms-netology.ru
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: svc-nginx-simple
                port:
                  name: web
          - path: /app
            pathType: Exact
            backend:
              service:
                name: svc-multitool
                port:
                  name: app
```

Применяем манифест

kubectl apply -f diplom-manifest.yaml 


3. Проверяем

root@ubuntu-VirtualBox:/home/ubuntu/Diplom/4Part# kubectl get svc -n monitoring
NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
alertmanager-main       ClusterIP      10.96.165.134   <none>        9093/TCP,8080/TCP            4h42m
alertmanager-operated   ClusterIP      None            <none>        9093/TCP,9094/TCP,9094/UDP   4h40m
blackbox-exporter       ClusterIP      10.96.253.23    <none>        9115/TCP,19115/TCP           4h42m
grafana                 LoadBalancer   10.96.189.2     <pending>     3000:32000/TCP               4h41m
kube-state-metrics      ClusterIP      None            <none>        8443/TCP,9443/TCP            4h41m
node-exporter           ClusterIP      None            <none>        9100/TCP                     4h41m
prometheus-adapter      ClusterIP      10.96.164.117   <none>        443/TCP                      4h41m
prometheus-k8s          ClusterIP      10.96.250.237   <none>        9090/TCP,8080/TCP            4h41m
prometheus-operated     ClusterIP      None            <none>        9090/TCP                     4h40m
prometheus-operator     ClusterIP      None            <none>        8443/TCP                     4h40m
root@ubuntu-VirtualBox:/home/ubuntu/Diplom2/4Part# kubectl get svc -n diplom
NAME        TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
svc-nginx   LoadBalancer   10.96.174.39   <pending>     80:32509/TCP   48m



Для того, чтобы заработало по доменному имени, необходимо на хостинге, где есть свое купленное доменное имя настроить на днс ЯО, а в ЯО создать зону с сайтом kms-netology.ru. и создать запись в ЯО. К сожалению не удалось с учетом кубер кластера это сделать средствами терраформ


Проверим Http доступ к тестовому приложению:
![Скриншот-4.3](./img/.....)
![Скриншот-4.3](.img/......)
