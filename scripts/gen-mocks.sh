#!/bin/sh

if ! which mint >/dev/null; then
  echo "warning: Mint not installed, download from https://github.com/yonaskolb/Mint"
  exit 0
fi

START_DATE=$(date +"%s")

run_mockolo() {
  local source_path="${1}"
  local output_dir="./Tests/${source_path}Mocks"
  mkdir -p "$output_dir"

  local module="$(echo "${source_path}" | sed -e 's|/||g')"
  mint run uber/mockolo mockolo \
    -s "./Sources/${source_path}" \
    -d "${output_dir}/${module}Mocks.generated.swift" \
    -i "${module}" \
    --enable-args-history
}

END_DATE=$(date +"%s")

run_mockolo "SubprocessKit"
run_mockolo "SimctlKit"
run_mockolo "SimulatorKit"
run_mockolo "IsimctlUI"

DIFF=$(($END_DATE - $START_DATE))
echo "Mockolo took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."
