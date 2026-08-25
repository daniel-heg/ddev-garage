#!/usr/bin/env bats

setup() {
  set -eu -o pipefail

  export GITHUB_REPO=daniel-heg/ddev-garage
  export GARAGE_ACCESS_KEY=GK0123456789abcdef0123456789abcdef
  export GARAGE_SECRET_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true

  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"

  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success

  run ddev start -y
  assert_success
}

install_from_directory() {
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success
}

health_checks() {
  run ddev garage status
  assert_success
  assert_output --partial "HEALTHY NODES"

  run ddev garage bucket list
  assert_success
  assert_output --partial "garage"

  run ddev exec --raw -- curl --fail --silent --show-error \
    --aws-sigv4 "aws:amz:garage:s3" \
    --user "${GARAGE_ACCESS_KEY}:${GARAGE_SECRET_KEY}" \
    --request PUT \
    --data-binary "garage-test" \
    http://garage:3900/garage/health.txt
  assert_success

  run ddev exec --raw -- curl --fail --silent --show-error \
    --aws-sigv4 "aws:amz:garage:s3" \
    --user "${GARAGE_ACCESS_KEY}:${GARAGE_SECRET_KEY}" \
    http://garage:3900/garage/health.txt
  assert_success
  assert_output "garage-test"

  run curl --fail --silent --show-error --insecure \
    "https://garage.${PROJNAME}.ddev.site:3902/health.txt"
  assert_success
  assert_output "garage-test"

  run ddev restart -y
  assert_success

  run curl --fail --silent --show-error --insecure \
    "https://garage.${PROJNAME}.ddev.site:3902/health.txt"
  assert_success
  assert_output "garage-test"
}

teardown() {
  set -eu -o pipefail

  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1

  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ -n "${TESTDIR}" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  install_from_directory
  health_checks
}

@test "configuration overrides and removal" {
  install_from_directory

  run ddev dotenv set .ddev/.env.garage \
    --garage-default-bucket=assets \
    --garage-default-bucket-public=false
  assert_success

  run ddev add-on get "${DIR}"
  assert_success

  run grep -F -- "- assets.${PROJNAME}" .ddev/config.garage.yaml
  assert_success

  run ddev add-on remove garage
  assert_success

  [ ! -e .ddev/config.garage.yaml ]
  [ ! -e .ddev/garage/garage.toml ]

  run docker volume inspect "ddev-${PROJNAME}-garage-data"
  assert_success
}

# bats test_tags=release
@test "install from release" {
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3

  run ddev add-on get "${GITHUB_REPO}"
  assert_success

  run ddev restart -y
  assert_success

  health_checks
}
