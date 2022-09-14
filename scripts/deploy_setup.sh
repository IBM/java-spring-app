#!/usr/bin/env bash

# shellcheck source=/dev/null
source "${ONE_PIPELINE_PATH}"/tools/retry
export IBMCLOUD_API_KEY
export IBMCLOUD_TOOLCHAIN_ID
export IBMCLOUD_IKS_REGION
export IBMCLOUD_IKS_CLUSTER_NAME
export IBMCLOUD_IKS_CLUSTER_ID
export IBMCLOUD_IKS_CLUSTER_NAMESPACE
export REGISTRY_URL
export IMAGE_PULL_SECRET_NAME
export IMAGE
export DIGEST
export HOME
export BREAK_GLASS
export CLUSTER_INGRESS_SUBDOMAIN
export CLUSTER_INGRESS_SECRET
export DEPLOYMENT_FILE
export CLUSTER_TYPE
export TEMP_DEPLOYMENT_FILE

if [ -f /config/api-key ]; then
  IBMCLOUD_API_KEY="$(cat /config/api-key)" # pragma: allowlist secret
else
  IBMCLOUD_API_KEY="$(get_env ibmcloud-api-key)" # pragma: allowlist secret
fi

IBMCLOUD_API=$(get_env ibmcloud-api "https://cloud.ibm.com")
HOME=/root
IBMCLOUD_TOOLCHAIN_ID="$(jq -r .toolchain_guid /toolchain/toolchain.json)"
IBMCLOUD_IKS_REGION="$(get_env dev-region | awk -F ":" '{print $NF}')"
IBMCLOUD_IKS_CLUSTER_NAMESPACE="$(get_env dev-cluster-namespace)"
IBMCLOUD_IKS_CLUSTER_NAME="$(get_env cluster-name)"
REGISTRY_URL="$(load_artifact app-image name| awk -F/ '{print $1}')"
IMAGE="$(load_artifact app-image name)"
DIGEST="$(load_artifact app-image digest)"
IMAGE_PULL_SECRET_NAME="ibmcloud-toolchain-${IBMCLOUD_TOOLCHAIN_ID}-${REGISTRY_URL}"
DEPLOYMENT_FILE="$(cat /config/deployment-file)"
CLUSTER_TYPE="IKS"
TEMP_DEPLOYMENT_FILE="temp.yml"

if [[ -f "/config/break_glass" ]]; then
  export KUBECONFIG
  KUBECONFIG=/config/cluster-cert
else
  IBMCLOUD_IKS_REGION=$(echo "${IBMCLOUD_IKS_REGION}" | awk -F ":" '{print $NF}')
  ibmcloud config --check-version false
  retry 5 2 \
    ibmcloud login -r "${IBMCLOUD_IKS_REGION}" -a "$IBMCLOUD_API"

  retry 5 2 \
    ibmcloud ks cluster config --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}"


  ibmcloud ks cluster get --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}" --json > "${IBMCLOUD_IKS_CLUSTER_NAME}.json"
  IBMCLOUD_IKS_CLUSTER_ID=$(jq -r '.id' "${IBMCLOUD_IKS_CLUSTER_NAME}.json")

  if [ "$(kubectl config current-context)" != "${IBMCLOUD_IKS_CLUSTER_NAME}"/"${IBMCLOUD_IKS_CLUSTER_ID}" ]; then
    echo "ERROR: Unable to connect to the Kubernetes cluster."
    echo "Consider checking that the cluster is available with the following command: \"ibmcloud ks cluster get --cluster ${IBMCLOUD_IKS_CLUSTER_NAME}\""
    echo "If the cluster is available check that that kubectl is properly configured by getting the cluster state with this command: \"kubectl cluster-info\""
    exit 1
  fi


  # If the target cluster is openshift then make the appropriate additional login with oc tool
  if which oc > /dev/null && jq -e '.type=="openshift"' "${IBMCLOUD_IKS_CLUSTER_NAME}.json" > /dev/null; then
    echo "${IBMCLOUD_IKS_CLUSTER_NAME} is an openshift cluster. Doing the appropriate oc login to target it"
    oc login -u apikey -p "${IBMCLOUD_API_KEY}"
     CLUSTER_TYPE="OPENSHIFT"
  fi
fi

if [ -z "${DEPLOYMENT_FILE}" ]; then
  echo "deployment-file environment is not defined."
  if [ "${CLUSTER_TYPE}" == "OPENSHIFT" ]; then
    DEPLOYMENT_FILE="deployment_os.yml"
  else
    DEPLOYMENT_FILE="deployment_iks.yml"
  fi
   
  set_env "deployment-file" "$DEPLOYMENT_FILE"    
  set_env "cluster-type" "$CLUSTER_TYPE"
  echo "deployment-file is ${DEPLOYMENT_FILE}"
fi
