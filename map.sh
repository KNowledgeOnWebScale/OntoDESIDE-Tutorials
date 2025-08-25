#!/bin/bash
# Usage:
# - run in the directory where this script is located
# - supply the YARRRML file (with path) as the first argument
# - optionally, supply the output serialization as the second argument (default is 'nquads')
#
# Example:
#   ./map.sh example-data/x-domain/lindner/mapping.yml
#   ./map.sh example-data/x-domain/lindner/mapping.yml turtle

if [[ -z "$1" ]]; then
  echo "Error: YARRRML file is not given."
  echo "Usage: $0 <YARRRML_FILE_WITH_PATH>"
  exit 1
fi

if [[ ! -f "$1" ]]; then
  echo "Error: '$1' does not exist."
  exit 1
fi

YARRRML_FILE_WITH_PATH=$1
OUTPUT_SERIALIZATION=${2:-nquads}

YARRRML_DIR=$(dirname "${YARRRML_FILE_WITH_PATH}")
YARRRML_FILE=$(basename "${YARRRML_FILE_WITH_PATH}")
RML_FILE=${YARRRML_FILE}.rml.ttl.testout
PROJECT_DIR=$(pwd)

# execute the tools in the directory where the YARRRML file is located
# this is because of relative paths inside the YARRRML files
pushd "${YARRRML_DIR}" > /dev/null

# make sure the output directory exists
mkdir -p out
# delete old output files; assuming they all have the .testout suffix or are in the output directory
find . -name '*.testout' -delete
rm -f out/*

# parse YAMMML to RML
npx yarrrml-parser -i ${YARRRML_FILE} -o ${RML_FILE}
# run the RML mapper
java -jar ${PROJECT_DIR}/rmlmapper.jar -m ${RML_FILE} -s ${OUTPUT_SERIALIZATION}

popd > /dev/null