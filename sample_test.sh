#!/bin/bash

set -ex

# Show environment
uname -a
id
java -version
# Build logic.
./mvnw verify
# Test logic.
./mvnw test
