#!/usr/bin/env bash
export WORKLOAD=pod
source ./common.sh

for pairs in 1 2 4; do
  export UUID=$(uuidgen)
  export pairs=${pairs}
  run_workload smoke-crd.yaml
  if [[ $? != 0 ]]; then
    exit 1
  fi
  assign_uuid
  run_benchmark_comparison
done
generate_csv

if [[ ${ENABLE_SNAPPY_BACKUP} == "true" ]] ; then
  echo -e "snappy server as backup enabled"
  source ../../utils/snappy-move-results/common.sh
  csv_list=`find . -name "*.csv"` 
  mkdir files_list
  cp $csv_list ./files_list
  tar -zcvf snappy_files.tar.gz ./files_list
  
  export workload=network_perf_smoke_test
  export snappy_path="$SNAPPY_USER_FOLDER/$runid$platform-$cluster_version-$network_type/$workload/$folder_date_time/"
  generate_metadata > metadata.json  
  ../../utils/snappy-move-results/run_snappy.sh snappy_files.tar.gz $snappy_path
  ../../utils/snappy-move-results/run_snappy.sh metadata.json $snappy_path
  store_on_elastic
  rm -rf files_list
fi
log "Finished workload ${0}"
