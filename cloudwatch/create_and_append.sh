#!/bin/bash

aws logs create-log-group \
    --log-group-name KarlTest

aws logs create-log-stream \
    --log-group-name KarlTest \
    --log-stream-name KarlTestStream

NEXT_SEQ_TOKEN=$(
aws logs put-log-events \
    --log-group-name KarlTest \
    --log-stream-name KarlTestStream \
    --log-events file://log.json \
    | jq -r .nextSequenceToken
)

aws logs put-log-events \
    --log-group-name KarlTest \
    --log-stream-name KarlTestStream \
    --log-events file://log.json \
    --sequence-token $NEXT_SEQ_TOKEN

echo "Logs created, press enter to delete log group"
read

aws logs delete-log-group \
    --log-group-name KarlTest
