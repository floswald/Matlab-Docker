# Matlab-Docker on SSPcloud

> Author: Florian Oswald, JPE Data Editor

This checklist worked for me to deploy matlab with pre-installed toolboxes via the `https://datalab.sspcloud.fr/` instance of the [Onyxia](https://www.onyxia.sh) project. 

## Objectives

1. Provide a way to run matlab in the cloud, with toolboxes, and with browser based login.
2. Use MATLAB Online Licensing: We use _named user licensing_ with a mathworks account authentication. You need to have something like a _Matlab campuswide license_ - you log in with your institutional credentials.
3. Technically, the `-browser` flag on the matlab startup command launches `matlab-proxy` which runs the authentication workflow in your browser.

## Implementation

### Preparation of Docker Image and Kubernetes Setup

1. `Dockerfile` in this repo: locally builds a matlab image and preinstalls a set of toolboxes. This takes the official matlab image, and adds the matlab package installer, with instructions for which additional toolboxes to add. Edit the `products` argument in the Dockerfile.
5. built locally with: 
    ```
    docker buildx build --platform linux/amd64 -t floswald/matlab-toolboxes:r2025b .
    ``` 
    I am using the `platform` flag because I am on Apple Silicon.
6. tested that running container locally allows to log in via browser and that toolboxes are installed and work. run locally with
    ```
    docker run --rm -it --platform linux/amd64 --shm-size=512M -p 8888:8888 floswald/matlab-toolboxes:r2025b -browser
    ```
    those instructions are from the [matlab docker hub](https://hub.docker.com/r/mathworks/matlab).
7. `docker push floswald/matlab-toolboxes:r2025b` : make docker image available via docker hub.
8. `matlab.yaml`: is a kubernetes specification which sets up a service to run on SSPcloud, which uses my container from docker hub. This file needs to be placed on the SSPcloud S3 storage of the user. I followed SSPcloud instructions for storage at [https://datalab.sspcloud.fr/account/storage](https://datalab.sspcloud.fr/account/storage), selecting at the bottom the env var for the `mc` client. Locally, export that env var as `MC_HOST_onyxia`, and use the `mc` client:
    ```
    # install client on mac:
    brew install minio/stable/mc

    # check onyxia client available from env var:
    floswald@PTL11077 ~/g/Matlab-Docker (main)> mc alias list
    onyxia
      URL       : https://minio.lab.sspcloud.fr
      AccessKey : ***
      SecretKey : ***
      API       : S3v4
      Path      : 
      Src       : env

    # keys are set from MC_HOST_onyxia

    # do a ls on onyxia S3 datastore
    floswald@PTL11077 ~/g/Matlab-Docker (main) [1]> mc ls onyxia/floswald
    [2026-03-01 11:16:45 CET] 1.2KiB STANDARD matlab.yaml
    [2026-03-01 12:12:01 CET]     0B diffusion/
    [2026-03-01 12:12:01 CET]     0B testdir/
    [2026-03-01 12:12:01 CET]     0B uploads/
    
    # edit matlab.yaml locally (for your user name?), then put onto S3 at onyxia:
    mc cp matlab.yaml onyxia/floswald/matlab.yaml

### Service Creation on SSPcloud

1.  One needs to create a VScode based instance on SSPcloud - choose any available (`vscode-r-python-julia` works. you need `vscode`.) We will call this the `admin-instance`. `TL;DR:` You can click on [this link](https://datalab.sspcloud.fr/launcher/ide/vscode-r-python-julia?name=admin-vscode-r-python-julia&version=2.5.2&s3=region-79669f20&service.image.custom.version=«mathworks%2Fmatlab%3Ar2025b»&init.personalInit=«https%3A%2F%2Fraw.githubusercontent.com%2Ffloswald%2FMatlab-Docker%2Frefs%2Fheads%2Fmain%2Finitmatlab.sh»&kubernetes.role=«admin»&networking.user.enabled=true&networking.user.ports[0]=-&autoLaunch=true) to launch my exact instance, but for completeness here are the configurations, and the rest of the section explains creation of the service:
    1. The instance needs to be configured _in admin mode_ (setting `Role`)
    2. Do not supply a custom docker container, leave whatever is the default (that one just runs VScode in admin mode for us)
    3. Supply an init script that uses kubernetes to launch our new matlab service. The init script I supplied is [initmatlab.sh](initmatlab.sh), edit as need and supply a similar [URL](https://raw.githubusercontent.com/floswald/Matlab-Docker/refs/heads/main/initmatlab.sh) to `InitializationScript`. Script content:
        ```
        #!/bin/bash
        mc cp s3/floswald/matlab.yaml ~/work/matlab.yaml
        kubectl apply -f ~/work/matlab.yaml
        ```
      this just copies the `matlab.yaml` from above from the SSPcloud S3 into the the current instances user space, and uses `kubectl` to launch the new custom service (`matlab`)
2.  Save this service configuration in SSPcloud, so you can find it easily in the future.

## Launch Service on SSPcloud

1.  Launch `admin-instance` on SSPcloud. You see VSCode under a URL like `https://user-floswald-468664-0.user.lab.sspcloud.fr`. 
2.  On first run, this will pull your docker image and build it, so it takes a while. On the console of the `admin-instance` do `kubectl get pods` to see progress.
    ```bash
    onyxia@vscode-r-python-julia-826144-0:~/work$ kubectl get pods
    NAME                             READY   STATUS              RESTARTS   AGE
    matlab-7ccb98587f-9dbv2          0/1     ContainerCreating   0          3m9s
    ```
3.   As soon as `kubectl get pods -w` reports `STATUS: Running` for the matlab service, you can point your browser to [https://user-floswald-999999-0.user.lab.sspcloud.fr](https://user-floswald-999999-0.user.lab.sspcloud.fr) and see what gives. If all went well, you will see the matlab login browser.
4.   The `matlab.yaml` specification sets the ingress point for kubernetes at `https://user-floswald-999999-0.user.lab.sspcloud.fr`, where you will find matlab if successful. Obviously, you may want to change the hostnames in the `matlab.yaml` file. I _think_ you are almost free what goes for `999999-0`, but there may be some checking going on that expects a certain format for this URL - I guess at least the username must be valid.
5.   You need an institutional login (via your university for instance) that works on mathworks.com. After successful login check that you can see the toolboxes in matlab (go to `Apps`).