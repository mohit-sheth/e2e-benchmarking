#!/usr/bin/env bash

# Two arguments are 'pod label' and 'timeout in seconds'
function get_pod () {
  counter=0
  sleep_time=5
  counter_max=$(( $2 / sleep_time ))
  pod_name="False"
  until [ $pod_name != "False" ] ; do
    sleep $sleep_time
    pod_name=$(oc get pods -l $1 --namespace ${3:-benchmark-operator} -o name | cut -d/ -f2)
    if [ -z $pod_name ]; then
      pod_name="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      echo "Unable to locate the pod!"
      return 1
    fi
  done
  echo $pod_name
  return 0
}

# The argument is 'timeout in seconds'
function get_uuid () {
  sleep_time=$1
  sleep $sleep_time
  counter=0
  counter_max=6
  uuid="False"
  until [ $uuid != "False" ] ; do
    uuid=$(oc -n benchmark-operator get benchmarks -o jsonpath='{.items[0].status.uuid}')
    if [ -z $uuid ]; then
      sleep $sleep_time
      uuid="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      echo "Unable to fetch the benchmark uuid!"
      return 1
    fi
  done
  echo $uuid
  return 0
}

# The argument is 'timeout and 'pod name' in seconds'
function check_pod_ready_state () {
  pod_name=$1
  timeout=$2
  echo "Waiting $timeout for $pod_name pod to transition to the ready state..."
  oc wait --for=condition=ready pods --namespace ${3:-benchmark-operator} $pod_name --timeout=$timeout
  return $?
}


##############################################################################
# Prints log messages
# Arguments:
#   Log string
##############################################################################
log() {
  echo -e "\033[1m$(date -u) ${@}\033[0m"
}

##############################################################################
# Imports a CSV file into a google spreadsheet
# Arguments:
#   Spreadsheet name
#   CSV file to import
#   Gmail email address
#   Service account file
##############################################################################
gen_spreadsheet() {
  log "Installing requirements to generate spreadsheet"
  csv_tmp=$(mktemp -d)
  python -m venv ${csv_tmp}
  source ${csv_tmp}/bin/activate
  pip install oauth2client>=4.1.3 gspread
  $(dirname ${BASH_SOURCE[@]})/csv_gen.py --sheetname ${1}-$(date "+%Y-%m-%dT%H:%M:%S") -c ${2} --email ${3} --service-account ${4}
  deactivate
  rm -rf ${csv_tmp}
}

