#!/bin/sh

SCRIPT=$LAMBDA_TASK_ROOT/$(echo "$_HANDLER" | cut -d. -f1).R

FUNCTION=$(echo "$_HANDLER" | cut -d. -f3)

echo $SCRIPT
echo $FUNCTION

while true
do
    # Get an event
    HEADERS="$(mktemp)"
    EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
    REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)

   
    # Execute the handler function from the script
    RESULT=$(mktemp)
    /var/task/R/bin/Rscript --version
	/var/task/R/bin/Rscript $SCRIPT --args "${EVENT_DATA} "${REQUEST_ID}
	
    RESPONSE="${FUNCTION} Processed!"

    # Send the response
    curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response"  -d "$RESPONSE"
done