#!/usr/bin/env bash

source hack/lib/test_lib.sh

function check_dir() {
  if [[ $3 == 0 ]]; then
    if [[ -d "$2" ]]; then
      error_text "${1}: directory ${2} should not exist"
      exit 1
    fi
  else
    if [[ ! -d "$2" ]]; then
      error_text "${1}: directory ${2} should exist"
      exit 1
    fi
  fi
}

function check_file() {
  if [[ $3 == 0 ]]; then
    if [[ -f "$2" ]]; then
      error_text "${1}: file ${2} should not exist"
      exit 1
    fi
  else
    if [[ ! -f "$2" ]]; then
      error_text "${1}: file ${2} should exist"
      exit 1
    fi
  fi
}

function cleanup_case() {
  git clean -dfxq .
}

TEST_DIR="test/test-framework"
OPERATOR_NAME="memcached-operator"
OPERATOR_VERSION_1="0.0.2"
OPERATOR_VERSION_2="0.0.3"
OPERATOR_BUNDLE_IMAGE_2="quay.io/example/${OPERATOR_NAME}:${OPERATOR_VERSION_2}"
OPERATOR_BUNDLE_ROOT_DIR="deploy/olm-catalog/${OPERATOR_NAME}"
OPERATOR_BUNDLE_DIR_1="${OPERATOR_BUNDLE_ROOT_DIR}/${OPERATOR_VERSION_1}"
OPERATOR_BUNDLE_DIR_2="${OPERATOR_BUNDLE_ROOT_DIR}/${OPERATOR_VERSION_2}"
OUTPUT_DIR="foo"

function create() {
  operator-sdk bundle create $1 --directory $2 --package $OPERATOR_NAME ${@:3}
}

function generate() {
  operator-sdk bundle create --generate-only --directory $1 --package $OPERATOR_NAME ${@:2}
}

pushd "$TEST_DIR"
trap_add "git clean -dfxq $TEST_DIR" EXIT
trap_add "popd" EXIT

set -e

header_text "Running 'operator-sdk bundle' subcommand tests."

TEST_NAME="create with version ${OPERATOR_VERSION_2}"
header_text "$TEST_NAME"
create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 0
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/manifests" 0
check_file "$TEST_NAME" "bundle.Dockerfile" 0
cleanup_case

TEST_NAME="create with version ${OPERATOR_VERSION_2} and output-dir"
header_text "$TEST_NAME"
create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2" --output-dir "$OUTPUT_DIR"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 1
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 1
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/manifests" 0
check_file "$TEST_NAME" "bundle.Dockerfile" 0
cleanup_case

TEST_NAME="generate with version ${OPERATOR_VERSION_2}"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_2"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 0
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/metadata" 1
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/manifests" 1
check_file "$TEST_NAME" "bundle.Dockerfile" 1
cleanup_case

TEST_NAME="generate with version ${OPERATOR_VERSION_2} and output-dir"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_2" --output-dir "$OUTPUT_DIR"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 1
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 1
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/manifests" 0
check_file "$TEST_NAME" "bundle.Dockerfile" 1
cleanup_case

TEST_NAME="create with version ${OPERATOR_VERSION_2} with existing metadata"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_2"
create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 0
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 0
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/metadata" 1
check_dir "$TEST_NAME" "$OPERATOR_BUNDLE_ROOT_DIR/manifests" 1
check_file "$TEST_NAME" "bundle.Dockerfile" 1
cleanup_case

TEST_NAME="create with version ${OPERATOR_VERSION_2} with existing metadata and output-dir"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_2"
create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2" --output-dir "$OUTPUT_DIR"
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 1
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 1
check_dir "$TEST_NAME" "${OPERATOR_BUNDLE_ROOT_DIR}/manifests" 1
check_dir "$TEST_NAME" "${OPERATOR_BUNDLE_ROOT_DIR}/metadata" 1
check_file "$TEST_NAME" "bundle.Dockerfile" 1
cleanup_case

TEST_NAME="error on create with version ${OPERATOR_VERSION_2} with existing manifests version ${OPERATOR_VERSION_1}"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_1"
if create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2"; then
  error_text "$TEST_NAME: expected error"
  exit 1
fi
cleanup_case

TEST_NAME="create with version ${OPERATOR_VERSION_2} with existing manifests/metadata version ${OPERATOR_VERSION_1} and overwrite"
header_text "$TEST_NAME"
generate "$OPERATOR_BUNDLE_DIR_2"
create $OPERATOR_BUNDLE_IMAGE_2 "$OPERATOR_BUNDLE_DIR_2" --overwrite
check_dir "$TEST_NAME" "${OUTPUT_DIR}/manifests" 0
check_dir "$TEST_NAME" "${OUTPUT_DIR}/metadata" 0
check_dir "$TEST_NAME" "${OPERATOR_BUNDLE_ROOT_DIR}/manifests" 1
check_dir "$TEST_NAME" "${OPERATOR_BUNDLE_ROOT_DIR}/metadata" 1
check_file "$TEST_NAME" "bundle.Dockerfile" 1
cleanup_case

header_text "All 'operator-sdk bundle' subcommand tests passed."

# TODO(estroz): add validate steps after each 'create' test to validate dirs
# once the following is merged:
# https://github.com/operator-framework/operator-sdk/pull/2737
