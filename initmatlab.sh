#!/bin/bash

mc cp s3/${VAULT_TOP_DIR}/matlab.yaml ~/work/matlab.yaml

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

kubectl apply -f ~/work/matlab.yaml
