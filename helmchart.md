

# Deploy Cloud Native Apps - Happy Helming...

![helm-chart](./Assets/helm-chart.png)



## Introduction

## What the Document does

## What It does not

## Components

- **Chart.yaml**

  - Contains information about the chart

  - Modify *Description*

  - Modify *Chart Version*

  - Modify *App Version*

  - **Example**

    ```yaml
    apiVersion: v2
    name: ratingsapi-chart
    description: A Helm chart for Ratings API
    
    # A chart can be either an 'application' or a 'library' chart.
    #
    # Application charts are a collection of templates that can be packaged into versioned archives
    # to be deployed.
    #
    # Library charts provide useful utilities or functions for the chart developer. They're included as
    # a dependency of application charts to inject those utilities and functions into the rendering
    # pipeline. Library charts do not define any templates and therefore cannot be deployed.
    type: application
    
    # This is the chart version. This version number should be incremented each time you make changes
    # to the chart and its templates, including the app version.
    # Versions are expected to follow Semantic Versioning (https://semver.org/)
    version: 0.0.1
    
    # This is the version number of the application being deployed. This version number should be
    # incremented each time you make changes to the application. Versions are not expected to
    # follow Semantic Versioning. They should reflect the version the application is using.
    appVersion: 1.0.0
    ```

- **values.yaml** - configuration values for this chart

  - **Example**

    ```yaml
    deployment:
      name: ratingsapi-deploy
      namespace: aks-workshop-dev
      labels:
        app: ratingsapi-deploy
      selectorLabels:
        app: ratingsapi-pod    
      replicas: 2
      strategyType: RollingUpdate
      maxSurge: 1
      maxUnavailable: 1
      nodeSelector:
        agentpool: aksapipool
      containers:
      - name: ratingsapi-app
        image: akswkshpacr.azurecr.io/ratings-api:v1.0.0
        imagePullPolicy: IfNotPresent
        readinessPort: 3000
        readinessPath: /healthz
        livenessPort: 3000
        livenessPath: /healthz
        memoryRequest: "64Mi"
        cpuRequest: "100m"
        memoryLimit: "256Mi"
        cpuLimit: "200m"
        containerPorts: [3000]    
        env:          
        - name: MONGODB_URI
          valueKey: MONGOCONNECTION
          valueSecret: aks-workshop-mongo-secret
    service:
      name: ratingsapi-service
      namespace: aks-workshop-dev
      selector:
        app: ratingsapi-pod
      type: ClusterIP
      ports:
      - protocol: TCP
        port: 80
        targetPort: 3000
    ```

- **Chart Templates**

  - Contains multiple *Chart templates*
  - All templates are deployed at once
  - Each Template contains the definition of a *K8s* object
    - Same format as original *Deployment* YAML file
    - Values are replaced by templatized values; to be filled up by corresponding values from *Values* YAML file at runtime

## Let us Get into some Action

- ### Create Helm Chart

  ```bash
  helm create <chart-name>
  ```

  ![helm-folder](./Assets/helm-folder-collapsed.png)

  

  

  ![helm-folder](./Assets/helm-folder.png)

  

  - #### Understand Folder structure

    - **templates**
      - Contains multiple template yamls
    - **.helmignore**
      - File containing entries that should NOT be included in the helm package
    - **values-xxx.yaml**
      - Configuration values for the chart

  - #### Configure Chart Release

    - **Chart.yaml**

      ![helm-folder](./Assets/chart-release.png)

      - Contains information about the chart
      - Modify *Description*
      - Modify *Chart Version*
      - Modify *App Version*

- ### Define a Chart Template

  - #### Conditions

    - Check existence of an item in yaml

      ```yaml
      {{ if $ingress.annotations.rewriteTarget }}
          nginx.ingress.kubernetes.io/rewrite-target: {{ $ingress.annotations.rewriteTarget }}
      {{ end }}
      ```

  - #### Loops

    - Repetitive entries in yaml

      ```yaml
      {{- range $host := $ingress.hosts }}
        - host: {{ $host.name}}
          http:
            paths:
            {{- range $path := $host.paths }}
            - path: {{ $path.path }}
              pathType: {{ $path.pathType }}
              backend:
                service:
                  name: {{ $path.service }}
                  port:
                    number: {{ $path.port }}
            {{- end }}
        {{- end }}
      ```

    - *range* denotes the start of the Loop block

    - *{{- end }}* denotes the end of the Loop block

    - Assign items in the Loop block in a variable

      ```bash
      $host := $ingress.hosts
      ......
      $path := $host.paths
      ```

      

  - #### Assign Single Key/Value pair

    - Single Value assignments are straight forward

      ```bash
      pathType: {{ $path.pathType }}
      ```

  - #### Assign Multiple Key/Value pairs

    - Multiple Value assignments are perfoermed using *toYaml* keyword

    - Indentation is for successful assignment

      - **Note *nindent* value - 6**

      ```yaml
      spec:
        selector:
          matchLabels:
      		{{ toYaml $deployment.selectorLabels | nindent 6 }}
      ```

      ![helm-multi-assign](./Assets/helm-multi-assign.png)

    - **4 Blank spaces from Left + 2 TAB spaces (*standard K8s object hierarchy*)**

    - **Few More Examples**

      - **Note *nindent* value - 8**

      ```yaml
        template:
          metadata:
            labels:
            {{ toYaml $deployment.selectorLabels | nindent 8 }}
      ```

      - **Note *nindent* value - 4**

      ```yaml
      metadata:
        name: {{ $deployment.name }}
        namespace: {{ $deployment.namespace }}
        labels:
        {{ toYaml $deployment.labels | nindent 4 }}
      ```

      

  - #### Examples

    - ##### Deployment

    - ##### Service

    - ##### ConfigMap

    - ##### RBAC

    - ##### Ingress

- ### Define Values for the Chart

  - #### Best Practices

  - #### Flat vs Hierarchial

  - #### Examples

    - ##### Deployment

    - ##### Service

    - ##### ConfigMap

    - ##### RBAC

    - ##### Ingress

- ### Install/Upgrade the Chart

- ### UnInstall the Chart

- #### Integration with Azure DevOps



