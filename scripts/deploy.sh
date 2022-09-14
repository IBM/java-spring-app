#!/usr/bin/env bash

echo "Updating the namespace in the deployment file....."
NAMESPACE_DOC_INDEX=$(yq read --doc "*" --tojson "${DEPLOYMENT_FILE}" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="namespace") | .key')
yq w -d "${NAMESPACE_DOC_INDEX}" "${DEPLOYMENT_FILE}" metadata.name "${IBMCLOUD_IKS_CLUSTER_NAMESPACE}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"
yq write --inplace "$DEPLOYMENT_FILE" --doc "*" "metadata.namespace" "${IBMCLOUD_IKS_CLUSTER_NAMESPACE}"

echo "Updating Image Pull Secrets Name in the deployment file......"
SECRET_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="secret") | .key')
yq write --doc "${SECRET_DOC_INDEX}" "${DEPLOYMENT_FILE}" "metadata.name" "${IMAGE_PULL_SECRET_NAME}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"

SERVICE_ACCOUNT_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="serviceaccount") | .key')
yq write --doc "${SERVICE_ACCOUNT_DOC_INDEX}" "${DEPLOYMENT_FILE}" "imagePullSecrets[0].name" "${IMAGE_PULL_SECRET_NAME}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"


echo "Updating Image Pull Secrets in the deployment file......"
REGISTRY_AUTH=""
if [[ -n "$BREAK_GLASS" ]]; then
  REGISTRY_AUTH=$(jq .parameters.docker_config_json /config/artifactory)
else
  REGISTRY_AUTH=$(echo "{\"auths\":{\"${REGISTRY_URL}\":{\"auth\":\"$(echo -n iamapikey:"${IBMCLOUD_API_KEY}" | base64 -w 0)\",\"username\":\"iamapikey\",\"email\":\"iamapikey\",\"password\":\"${IBMCLOUD_API_KEY}\"}}}" | base64 -w 0)
fi
yq write --doc "${SECRET_DOC_INDEX}" "${DEPLOYMENT_FILE}" "data[.dockerconfigjson]" "${REGISTRY_AUTH}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"

echo "Cluster IP Service should be unique accross all the namespace, updating Cluster IP service name with namespace..."
CIP_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.spec.type=="ClusterIP" ) | .key')
CIP_SERVICE_NAME=$(yq r --doc "$CIP_DOC_INDEX" "$DEPLOYMENT_FILE" metadata.name)
CIP_SERVICE_NAME="${CIP_SERVICE_NAME}"-"${IBMCLOUD_IKS_CLUSTER_NAMESPACE}"
yq write --doc "${CIP_DOC_INDEX}" "${DEPLOYMENT_FILE}" "metadata.name" "${CIP_SERVICE_NAME}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"
if [ "${CLUSTER_TYPE}" == "OPENSHIFT" ]; then
  ROUTE_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="route") | .key')
  yq write --doc "${ROUTE_DOC_INDEX}" "${DEPLOYMENT_FILE}" "spec.to.name" "${CIP_SERVICE_NAME}" > "${TEMP_DEPLOYMENT_FILE}"
  mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"
fi

echo "updating Cluster IP service name in the ingress.."
INGRESS_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="ingress") | .key')
yq write --doc "${INGRESS_DOC_INDEX}" "${DEPLOYMENT_FILE}" "spec.rules[0].http.paths[*].backend.service.name" "${CIP_SERVICE_NAME}" > "${TEMP_DEPLOYMENT_FILE}"
mv "${TEMP_DEPLOYMENT_FILE}" "${DEPLOYMENT_FILE}"

# Check if the cluster is paid IKS cluster. If yes then update the cluster domain name in place for the host name.
CLUSTER_INGRESS_SUBDOMAIN=$(ibmcloud ks cluster get --cluster "${IBMCLOUD_IKS_CLUSTER_NAME}" --json | jq -r '.ingressHostname // .ingress.hostname' | cut -d, -f1)
INGRESS_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="ingress") | .key')
if [ ! -z "${CLUSTER_INGRESS_SUBDOMAIN}" ] && [ "${KEEP_INGRESS_CUSTOM_DOMAIN}" != true ]; then 
  if [ -z "${INGRESS_DOC_INDEX}" ]; then
    echo "No Kubernetes Ingress definition found in $DEPLOYMENT_FILE."
  else
    # Update ingress with cluster domain/secret information
    # Look for ingress rule whith host contains the token "cluster-ingress-subdomain"
    INGRESS_RULES_INDEX=$(yq r --doc "${INGRESS_DOC_INDEX}" --tojson "${DEPLOYMENT_FILE}" | jq '.spec.rules | to_entries | .[] | select( .value.host | contains("cluster-ingress-subdomain")) | .key')
    if [ ! -z "${INGRESS_RULES_INDEX}" ]; then
      INGRESS_RULE_HOST=$(yq r --doc "${INGRESS_DOC_INDEX}" "${DEPLOYMENT_FILE}" spec.rules["${INGRESS_RULES_INDEX}"].host)
      DOMAIN_ADDRESS="${IBMCLOUD_IKS_CLUSTER_NAMESPACE}"."${CLUSTER_INGRESS_SUBDOMAIN}"
      # IKS provides a valid TLS certificate for *.Cluster-ingress-sub-domian
      # Update the host with format {App-Name}-{Cluster-Namespace}.{Cluster-ingress-subdomain}
      # Example :- https://hello-app-prod.gen2phm-b-57a8db4f565402d4797cc1d3399c50e2-0000.eu-de.containers.appdomain.cloud/
      # hello-app is from INGRESS_RULES_INDEX
      # prod is cluster namespace
      yq w --inplace --doc "${INGRESS_DOC_INDEX}" "${DEPLOYMENT_FILE}" spec.rules["${INGRESS_RULES_INDEX}"].host ${INGRESS_RULE_HOST/.cluster-ingress-subdomain/-$DOMAIN_ADDRESS}
    fi    
  fi
fi



# Portieris is not compatible with image name containing both tag and sha. Removing the tag
IMAGE="${IMAGE#*"@"}"
sed -i "s~^\([[:blank:]]*\)image:.*$~\1image: ${IMAGE}~" "${DEPLOYMENT_FILE}"

DEPLOYMENT_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="deployment") | .key')
SERVICE_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.spec.type=="NodePort" ) | .key')

deployment_name=$(yq r -d "${DEPLOYMENT_DOC_INDEX}" "${DEPLOYMENT_FILE}" metadata.name)


kubectl apply --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" -f "${DEPLOYMENT_FILE}"
if kubectl rollout status --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "deployment/$deployment_name"; then
  status=success
else
  status=failure
fi

kubectl get events --sort-by=.metadata.creationTimestamp -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE"

if [ "$status" = failure ]; then
  echo "Deployment failed"
  if [[ -z "$BREAK_GLASS" ]]; then
    ibmcloud cr quota
  fi
  exit 1
fi

export APPURL
if [ "${CLUSTER_TYPE}" == "OPENSHIFT" ]; then
  ROUTE_DOC_INDEX=$(yq read --doc "*" --tojson "$DEPLOYMENT_FILE" | jq -r 'to_entries | .[] | select(.value.kind | ascii_downcase=="route") | .key')
  service_name=$(yq r --doc "$ROUTE_DOC_INDEX" "$DEPLOYMENT_FILE" metadata.name)
  APPURL=$(kubectl get route --namespace "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "${service_name}" -o json | jq -r '.status.ingress[0].host')
else
  sleep 10
  if [ ! -z "${CLUSTER_INGRESS_SUBDOMAIN}" ] && [ "${KEEP_INGRESS_CUSTOM_DOMAIN}" != true ]; then 
    if [ -z "$INGRESS_DOC_INDEX" ]; then
      echo "No Kubernetes Ingress definition found in $DEPLOYMENT_FILE."
    else
      service_name=$(yq r --doc "$INGRESS_DOC_INDEX" "$DEPLOYMENT_FILE" metadata.name)
      for ITER in {1..30}
      do
        INGRESS_JSON=$(kubectl get ingress --namespace "${IBMCLOUD_IKS_CLUSTER_NAMESPACE}" "${service_name}" -o json)
        # Expose app using ingress host and path for the service
        APP_HOST=$(echo $INGRESS_JSON | jq -r --arg service_name "${CIP_SERVICE_NAME}" '.spec.rules[] | first(select(.http.paths[].backend.serviceName==$service_name or .http.paths[].backend.service.name==$service_name)) | .host' | head -n1)
        APP_PATH=$(echo $INGRESS_JSON | jq -r --arg service_name "${CIP_SERVICE_NAME}" '.spec.rules[].http.paths[] | first(select(.backend.serviceName==$service_name or .backend.service.name==$service_name)) | .path' | head -n1)
        # Remove any group in the path in case of regex in ingress path definition
        # https://kubernetes.github.io/ingress-nginx/user-guide/ingress-path-matching/
        APP_PATH=$(echo "$APP_PATH" | sed "s/([^)]*)//g")
        # Remove the last / from APP_PATH if any
        APP_PATH="${APP_PATH%/}"
        if [ ! -z  "${APP_HOST}"  ]; then 
          APPURL="${APP_HOST}""${APP_PATH}"
          break
        fi
        sleep 2
      done
    fi
  fi
  
  # If unable to find the APP_URL and Ingress sub domain is not available.
  if [ -z  "${APPURL}"  ] || [[  "${APPURL}" = "null"  ]]; then
    service_name=$(yq r -d "${SERVICE_DOC_INDEX}" "${DEPLOYMENT_FILE}" metadata.name)
    IP_ADDRESS=$(kubectl get nodes -o json | jq -r '[.items[] | .status.addresses[] | select(.type == "ExternalIP") | .address] | .[0]')
    PORT=$(kubectl get service -n "$IBMCLOUD_IKS_CLUSTER_NAMESPACE" "$service_name" -o json | jq -r '.spec.ports[0].nodePort')
    APPURL="${IP_ADDRESS}:${PORT}"
  fi 
fi

if [ -z  "${APPURL}"  ] || [[  "${APPURL}" = "null"  ]] || [[  "${APPURL}" = ":"  ]]; then
    echo "Unable to get Application URL....."
    exit 1
fi

echo "Application URL: http://${APPURL}"
echo -n http://${APPURL} >../app-url
set_env app-url "http://${APPURL}"
