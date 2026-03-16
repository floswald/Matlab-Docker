#!/bin/bash
mc cp s3/floswald/r-buses.yaml ~/work/r-buses.yaml
kubectl apply -f ~/work/r-buses.yaml
