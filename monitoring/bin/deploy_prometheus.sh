#!/usr/bin/env bash

USAGE="Usage: $0 [-n <namespace>] [-f <values file>]"

# Output help if no arguments or -h is included
if [[ $1 == "-h" ]];then
    echo $USAGE
    echo "-n <namespace>    namespace"
    echo "-f <values file>  add custom values file. Default: custom.yaml"
    exit
fi

# Read arguments
while getopts :n:f: option; do
    case "${option}" in
        n) NAMESPACE=${OPTARG};;
        f) FILE=${OPTARG};;
        \?) echo "Error: Incorrect usage"
            echo $USAGE
            exit 1;;
    esac
done

# Check if -n flag has been included
if [[ $1 != "-n" ]]; then
    NAMESPACE=monitoring
fi

# set custom yaml file if not provided with the -f arg
if ! [ $FILE ]; then
    FILE="custom.yaml"
fi

# Deploy to cluster
if read -t 10 -p "Installing Prometheus Operator and Grafana to '${NAMESPACE}' namespace in 10 seconds or when enter is pressed...";then echo;fi

# Add coreos repo to helm
#helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

# Install/Upgrade prometheus-operator
helm upgrade -i ${NAMESPACE}-prometheus-operator coreos/prometheus-operator --set=rbac.install=true --values values/prometheus-operator.yaml --namespace=$NAMESPACE

# Install/Upgrade kube-prometheus
helm upgrade -i ${NAMESPACE}-kube-prometheus coreos/kube-prometheus --set=rbac.install=true \
    -f values/kube-prometheus.yaml,values/am-alerts.yaml,values/ds-alerts.yaml,values/idm-alerts.yaml,values/ig-alerts.yaml,values/cluster-alerts.yaml --namespace=$NAMESPACE --force --wait --debug

#helm upgrade -i ${NAMESPACE}-kube-prometheus coreos/kube-prometheus --set=rbac.install=true \
#    -f values/kube-prometheus.yaml,values/am-alerts.yaml,values/ds-alerts.yaml,values/idm-alerts.yaml,values/ig-alerts.yaml --namespace=$NAMESPACE

# Install/Upgrade forgerock-servicemonitors
helm upgrade -i ${NAMESPACE}-forgerock-metrics helm/forgerock-metrics/ --values helm/${FILE} --set=rbac.install=true --namespace=$NAMESPACE

