# SafeWild — Identificador de Fauna Peligrosa en Microservicios

**Estudiantes:**
- Miguel Angel Franco Restrepo (22506163)
- Saulo Quiñones Góngora (22506635)
- Adrian Felipe Vargas Rojas (22505561)

**Curso:** Computación en la Nube
**Docente:** Jhorman A. Villanueva Vivas
**Institución:** Universidad Autónoma de Occidente
**Periodo:** 2026-1S

---

## 1. Resumen del Proyecto

SafeWild es una aplicación de identificación de fauna peligrosa desplegada como arquitectura de microservicios en **Amazon EKS**. El sistema permite al usuario cargar una imagen, clasificarla usando un modelo de visión por computadora (**MobileNetV2 / ImageNet**), y determinar si el animal detectado representa un riesgo de peligro, toxicidad o agresividad, consultando una base de datos de especies. Los resultados se persisten en PostgreSQL y se visualizan en un dashboard interactivo con historial y estadísticas.

---

## 2. Objetivo de la Práctica

Implementar una arquitectura de microservicios para una aplicación de IA en **Amazon EKS**, cumpliendo los siguientes requisitos:

- Mínimo 3 microservicios: frontend, servicio de IA y servicio de datos.
- Imágenes Docker almacenadas en **Amazon ECR**.
- Clúster Kubernetes con mínimo 3 nodos (instancias `t3.large`).
- Deployment y Service configurados por microservicio.
- Acceso al frontend a través de un **Load Balancer**.
- Mínimo 2 réplicas por pod donde sea necesario.
- Aplicación accesible desde internet.

---

## 3. Caso de Uso

> **Problema:** En zonas rurales y de ecoturismo, las personas frecuentemente se exponen a fauna silvestre sin conocer su nivel de peligro.

**Solución:** SafeWild permite tomar o cargar una foto del animal encontrado y recibir de forma inmediata:
- Identificación de la especie (nombre científico y común).
- Nivel de peligro (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`).
- Indicadores de veneno y agresividad.
- Recomendación de acción ante el avistamiento.

---

## 4. Arquitectura del Sistema

```
                        ┌─────────────────────────────────────────────┐
                        │              AWS Cloud (us-east-1)           │
                        │                                              │
        Internet        │   ┌──────────────────────────────────────┐  │
   ─────────────────►   │   │         Amazon EKS Cluster           │  │
        HTTP :80        │   │         (3 nodos t3.large)           │  │
                        │   │                                      │  │
                        │   │  ┌─────────────────────────────┐    │  │
                        │   │  │  AWS LoadBalancer (ELB)     │    │  │
                        │   │  │  frontend-svc  :80          │    │  │
                        │   │  └──────────┬──────────────────┘    │  │
                        │   │             │                        │  │
                        │   │   ┌─────────▼──────────┐            │  │
                        │   │   │  frontend (x2 pods) │            │  │
                        │   │   │  Flask + HTML/JS    │            │  │
                        │   │   │  :5000              │            │  │
                        │   │   └────┬──────────┬─────┘            │  │
                        │   │        │          │                   │  │
                        │   │  ┌─────▼──┐  ┌───▼──────────┐       │  │
                        │   │  │ai-svc  │  │ data-svc     │       │  │
                        │   │  │(x2 pod)│  │ (x2 pods)    │       │  │
                        │   │  │MobileN │  │ psycopg2     │       │  │
                        │   │  │V2 :5001│  │ :5002        │       │  │
                        │   │  └────────┘  └──────┬───────┘       │  │
                        │   │                     │               │  │
                        │   │             ┌───────▼──────┐        │  │
                        │   │             │  PostgreSQL  │        │  │
                        │   │             │  (1 pod)     │        │  │
                        │   │             │  PVC 5Gi gp2 │        │  │
                        │   │             │  :5432       │        │  │
                        │   │             └──────────────┘        │  │
                        │   └──────────────────────────────────────┘  │
                        │                                              │
                        │   Amazon ECR  ──►  3 repositorios de        │
                        │                    imágenes Docker           │
                        └─────────────────────────────────────────────┘
```

### 4.1 Microservicios

| Servicio | Puerto | Tecnología | Réplicas | Función |
|---|---|---|---|---|
| `frontend` | 5000 | Flask + HTML/CSS/JS | 2 | Dashboard UI, proxy entre usuario y servicios |
| `ai-service` | 5001 | Flask + TensorFlow / MobileNetV2 | 2 | Clasificación de imagen + enriquecimiento con danger_db |
| `data-service` | 5002 | Flask + psycopg2 | 2 | CRUD sobre PostgreSQL (historial, estadísticas) |
| `postgres` | 5432 | PostgreSQL 16 Alpine | 1 | Almacenamiento persistente con PVC (gp2, 5 Gi) |

### 4.2 Flujo de la Aplicación

1. El usuario accede al DNS del **LoadBalancer** (puerto 80).
2. El tráfico llega al `frontend`, que sirve la UI.
3. Al cargar una imagen, el `frontend` la envía en base64 al `ai-service`.
4. El `ai-service` ejecuta **MobileNetV2** y cruza el resultado con `danger_db.json` para determinar nivel de peligro.
5. El `frontend` envía el resultado al `data-service`, que lo persiste en **PostgreSQL**.
6. El historial y las estadísticas son recuperados del `data-service` bajo demanda.

---

## 5. Estructura del Proyecto

```
safewild-eks/
├── frontend/
│   ├── app.py                   # Flask proxy hacia ai-service y data-service
│   ├── templates/
│   │   └── index.html           # UI (drag & drop, historial, estadísticas)
│   ├── requirements.txt
│   └── Dockerfile
├── ai-service/
│   ├── app.py                   # MobileNetV2 + lookup en danger_db
│   ├── danger_db.json           # Base de datos de especies peligrosas
│   ├── requirements.txt
│   └── Dockerfile
├── data-service/
│   ├── app.py                   # CRUD PostgreSQL (save, history, stats, delete)
│   ├── requirements.txt
│   └── Dockerfile
├── k8s/
│   ├── postgres-secret.yaml     # Secret con credenciales de BD
│   ├── postgres.yaml            # PVC + Deployment + Service
│   ├── ai-service.yaml          # Deployment (x2) + Service ClusterIP
│   ├── data-service.yaml        # Deployment (x2) + Service ClusterIP
│   └── frontend.yaml            # Deployment (x2) + Service LoadBalancer
├── cluster/
│   └── cluster.yml              # Configuración eksctl del clúster
├── scripts/
│   ├── aws-credentials.sh
│   ├── create-ecr.sh
│   └── push-images.sh
└── docker-compose.yaml          # Para pruebas locales
```

---

## 6. Modelo de IA

El servicio de inteligencia artificial utiliza **MobileNetV2** preentrenado en ImageNet a través de TensorFlow/Keras.

- **Entrada:** imagen en base64 (redimensionada a 224×224 px).
- **Salida:** Top-5 predicciones con confianza + enriquecimiento con `danger_db.json`.
- **Enriquecimiento:** si la especie detectada existe en la base de datos interna, se adjuntan campos como `danger`, `venomous`, `aggressive` y `action`.
- **Sin entrenamiento adicional:** el modelo usa pesos preentrenados de ImageNet, lo que permite inferencia inmediata sin GPU.

Niveles de peligro definidos: `LOW` · `MEDIUM` · `HIGH` · `CRITICAL` · `NO_WILDLIFE`

---

## 7. Configuración del Clúster EKS

El clúster fue creado con `eksctl` usando el archivo `cluster/cluster.yml`:

```yaml
metadata:
  name: microservice-finaldelivery
  region: us-east-1
  version: "1.34"

managedNodeGroups:
  - name: ai-nodes
    instanceType: t3.large
    desiredCapacity: 3
    minSize: 3
    maxSize: 4
    volumeSize: 30
    privateNetworking: true
```

**Add-ons habilitados:** `vpc-cni`, `coredns`, `kube-proxy`

---

## 8. Pre-requisitos

- AWS CLI configurado (`aws configure`)
- `eksctl` instalado
- `kubectl` instalado
- `docker` instalado
- Cuenta AWS con permisos sobre EKS, ECR, IAM, VPC

---

## 9. Paso a Paso de Despliegue

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/<tu-usuario>/safewild-eks.git
cd safewild-eks
```

### Paso 2 — Crear repositorios en Amazon ECR

```bash
export AWS_REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

for SERVICE in frontend ai-service data-service; do
  aws ecr create-repository \
    --repository-name $SERVICE \
    --region $AWS_REGION
done
```

### Paso 3 — Autenticarse en ECR y construir/publicar imágenes

```bash
aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS \
    --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

```bash
for SERVICE in frontend ai-service data-service; do
  docker build -t $SERVICE ./$SERVICE
  docker tag $SERVICE:latest \
    $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:latest
  docker push \
    $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:latest
done
```

> ⚠️ El build de `ai-service` descarga los pesos de MobileNetV2 (~14 MB) y puede tardar varios minutos.

### Paso 4 — Crear el clúster EKS

```bash
eksctl create cluster -f cluster/cluster.yml
```

> ⏳ Este proceso tarda aproximadamente 15 minutos.

Verificar que los nodos estén listos:

```bash
kubectl get nodes
```

### Paso 5 — Actualizar los manifiestos con tu Account ID y región

```bash
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" k8s/ai-service.yaml k8s/data-service.yaml k8s/frontend.yaml
sed -i "s/<REGION>/$AWS_REGION/g"     k8s/ai-service.yaml k8s/data-service.yaml k8s/frontend.yaml
```

### Paso 6 — Desplegar en EKS

```bash
# 1. Secret con credenciales de Postgres
kubectl apply -f k8s/postgres-secret.yaml

# 2. Base de datos
kubectl apply -f k8s/postgres.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# 3. Microservicios
kubectl apply -f k8s/data-service.yaml
kubectl apply -f k8s/ai-service.yaml
kubectl apply -f k8s/frontend.yaml
```

### Paso 7 — Obtener la URL pública

```bash
kubectl get svc frontend
```

Busca la columna `EXTERNAL-IP`. Puede tardar 2-3 minutos en asignarse.

```
NAME       TYPE           CLUSTER-IP    EXTERNAL-IP                          PORT(S)
frontend   LoadBalancer   10.100.x.x    abc123.us-east-1.elb.amazonaws.com   80:xxxxx/TCP
```

Abre `http://<EXTERNAL-IP>` en tu navegador. ✅

---

## 10. Verificación del Estado del Clúster

```bash
# Ver todos los pods
kubectl get pods

# Ver logs por servicio
kubectl logs -l app=ai-service --tail=50
kubectl logs -l app=data-service --tail=50
kubectl logs -l app=frontend --tail=50

# Describir un pod con error
kubectl describe pod <nombre-del-pod>

# Verificar health de los servicios
curl http://<EXTERNAL-IP>/api/stats
```

---

## 11. Funcionalidades de la Aplicación

| Feature | Descripción |
|---|---|
| **Drag & Drop** | Arrastra una imagen o haz clic para seleccionar |
| **Clasificación en tiempo real** | Top-5 categorías con nivel de peligro y recomendación de acción |
| **Guardado automático** | Cada clasificación se persiste en PostgreSQL |
| **Historial paginado** | Galería de imágenes clasificadas con thumbnails |
| **Re-clasificar** | Vuelve a correr el modelo sobre una imagen anterior |
| **Eliminar registros** | Borra clasificaciones del historial y la BD |
| **Dashboard de estadísticas** | Total de clasificaciones, confianza promedio, top especies, actividad diaria |
| **Gráficas interactivas** | Chart.js — barras horizontales + línea de actividad |

---

## 12. Alta Disponibilidad

| Microservicio | Réplicas | Estrategia |
|---|---|---|
| `frontend` | 2 | Activo-activo, balanceado por el ELB |
| `ai-service` | 2 | Activo-activo, ClusterIP interno |
| `data-service` | 2 | Activo-activo, ClusterIP interno |
| `postgres` | 1 | PVC persistente (stateful) |

- Los pods con `readinessProbe` y `livenessProbe` permiten detección automática de fallos.
- El `ai-service` tiene un `initialDelaySeconds: 60` para esperar la carga del modelo antes de recibir tráfico.
- El clúster tiene autoescalado configurado (`minSize: 3`, `maxSize: 4`).

---

## 13. Configuración de Security Groups (Kubernetes)

La comunicación entre microservicios se realiza exclusivamente por **ClusterIP** (red interna del clúster). Solo el `frontend` tiene un `Service` de tipo `LoadBalancer` expuesto a internet.

| Comunicación | Protocolo | Puerto |
|---|---|---|
| Internet → frontend | HTTP | 80 |
| frontend → ai-service | HTTP | 5001 |
| frontend → data-service | HTTP | 5002 |
| data-service → postgres | TCP | 5432 |

---

## 14. Prueba Local con Docker Compose

Antes del despliegue en EKS, es posible probar la aplicación localmente:

```bash
docker-compose up --build
```

Accede a `http://localhost:5000` en tu navegador.

---

## 15. Limpieza de Recursos (evitar costos)

```bash
# Eliminar todos los recursos de Kubernetes
kubectl delete -f k8s/

# Eliminar el clúster EKS
eksctl delete cluster --name microservice-finaldelivery --region $AWS_REGION

# Eliminar repositorios ECR
for SERVICE in frontend ai-service data-service; do
  aws ecr delete-repository \
    --repository-name $SERVICE \
    --force \
    --region $AWS_REGION
done
```

> 💡 **Nota:** El NAT Gateway y el Load Balancer generan costos por hora incluso sin tráfico. Eliminar el clúster cuando no esté en uso.

---

## 16. Lecciones Aprendidas

- El modelo MobileNetV2 requiere más de 1 Gi de memoria por pod; ajustar los `resources.limits` es crítico para evitar OOMKilled.
- El `initialDelaySeconds` del `readinessProbe` en el `ai-service` debe ser suficientemente alto para permitir la carga completa de los pesos del modelo antes de recibir tráfico.
- PostgreSQL como Deployment con PVC es adecuado para entornos de práctica; en producción se recomienda usar Amazon RDS.
- La separación de responsabilidades entre microservicios facilita el escalado independiente de cada componente.
- `eksctl` con un archivo YAML de configuración es más reproducible que los comandos en línea.

---

## 17. Consideraciones Académicas

Este proyecto fue desarrollado con fines educativos en el contexto de la asignatura de Computación en la Nube de la Universidad Autónoma de Occidente. Los recursos de AWS fueron aprovisionados y eliminados dentro del período de práctica para minimizar costos.
