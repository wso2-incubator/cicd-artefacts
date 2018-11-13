#!/bin/bash
LOCALHOST=${TEST_URL}
CODE=`wget --server-response "${LOCALHOST}/helloworld?name=Tom" 2>&1 | awk '/^  HTTP/{print $2}'`;
if [ ${CODE} -eq "200" ] ; then
  echo "Test passed successfully..."
  exit 0
else
  echo "Test failed..."
  exit 1
fi
