#!/bin/bash
mc cp s3/floswald/matlab.yaml ~/work/matlab.yaml
kubectl apply -f ~/work/matlab.yaml
