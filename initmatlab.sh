#!/bin/bash

mc cp s3/${VAULT_TOP_DIR}/matlab_template.yaml ~/work/matlab_template.yaml

if [ -z "${MATLAB_PASS}" ] ; then
  echo "Error: MATLAB_PASS environment variable is not set."
  exit 1
fi

#this bash variable holds the secret required for 'mc' to work within the container.
#it is passed to the container through the 'create secret' command from kubectl.
MC_HOST_s3="https://${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}:${AWS_SESSION_TOKEN}@${AWS_S3_ENDPOINT}"
kubectl create secret generic mc-host-secret-name --from-literal=mc-host-secret-key="${MC_HOST_s3}"

#creating a secret will fail if it already exists. It is deleted and recreated if it already exists, allowing the user to change their password in vault before launching the service.
if ! $(kubectl create secret generic basic-auth --from-literal=auth="${VAULT_TOP_DIR}:$(openssl passwd -apr1 ${MATLAB_PASS})") ; then
	kubectl delete secret basic-auth
	kubectl create secret generic basic-auth --from-literal=auth="${VAULT_TOP_DIR}:$(openssl passwd -apr1 ${MATLAB_PASS})"
fi

#command `envsubst` is part of `gettext` package
sudo apt update && sudo apt install gettext -y

#this command subsitutes environment variables in the template with env variables currently in the shell.
#it is piped into the kubectl command without creating any additional files.
echo "This is a debug statement to check whether kubectl command is actually run"
envsubst < ~/work/matlab_template.yaml | kubectl apply -f -
kubectl get pods
echo "This is a debug statement to check whether kubectl command is actually run"
