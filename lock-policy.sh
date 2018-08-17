#!/bin/sh

# !!! WARNING: This script will lock your bucket.  THIS OPERATION IS IRREVERSIBLE!!!



if ! [ -e /usr/bin/jq ]; then
	echo "Please install jq"
	exit 1
fi

if ! [ -e /usr/bin/cloudian-s3curl.pl ]; then
	echo "Please install cloudian-s3curl"
	exit 1
fi




#ACCESSKEYID=63a29ef8b69f66376ed7
#SECRETKEY=79lI0xF8KVlq0t0iNl0k+1F0Ih8bTlNrZF9ncnqb
#ENDPOINT=s3-region.cmdhome.net
ACCESSKEYID="<accesskey>"
SECRETKEY="<secretkey>"
ENDPOINT=s3-region.cmdcloudian.net
#TEST=1


BUCKET=bucket
LOCKID=


function usage() {
	echo "usage: $1 [--endpoint=endpoint.cloudian.com] [--bucket=bucket] [--accesskeyid=63a29ef8b69f66376ed7] [--secretkey='79lI0xF8KVlq0t0iNl0k+1F0Ih8bTlNrZF9ncnqb'] [--autolock] [--test]"
	
}


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage $0
            exit 0
            ;;
        --endpoint)
            ENDPOINT=$VALUE
            ;;
        --accesskeyid | --key)
            ACCESSKEYID=$VALUE
            ;;
        --secretkey)
	    SECRETKEY=$VALUE
            ;;
        --bucket)
	    BUCKET=$VALUE
            ;;
	--test)
	    TEST=1
	    ;;
	--autolock)
	    AUTOLOCK=1
	    ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage $0
            exit 1
            ;;
    esac
    shift
done









if ! [  -e ./lock-policy.json ]; then

echo -en "{
\"Id\":\"ignore\", 
\"Version\":\"2012-10-17\",  
\"Statement\":
   [ 
      { 
         \"Sid\":\"deny-based-on-age\", 
         \"Effect\":\"Deny\", 
         \"Action\":[\"s3:DeleteObject\"],  
         \"Resource\":[\"arn:aws:s3:::$BUCKET/\*\"],  
         \"Condition\":{\"NumericLessThan\":{\"s3:AgeInDays\":\"1\"}}   
      }
   ]
}" > ./lock-policy.json
fi

echo 

echo "initializing lock..."

if [ -z "$TEST" ]; then
cloudian-s3curl.pl -post=./lock-policy.json -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT -- -k -ss 'https://'$ENDPOINT'/'$BUCKET'?lock-policy'
else
echo -e "cloudian-s3curl.pl -post=./lock-policy.json -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT -- -k -ss \"https://$ENDPOINT/$BUCKET?lock-policy\""
fi

if [ -z "$TEST" ]; then
LOCKID=`cloudian-s3curl.pl  -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT  -- -k -ss 'https://'$ENDPOINT'/'$BUCKET'?lock-policy'  | jq .LockId | sed 's/\"//g'`
else
LOCKID="nil"
echo -e "LOCKID=cloudian-s3curl.pl  -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT  -- -k -ss \"https://$ENDPOINT/${BUCKET}?lock-policy\"  | jq .LockId | sed s/\\\"//g"
fi


echo "Lock $LOCKID acquired"

if ! [ -z "$AUTOLOCK" ]; then

echo "finishing lock in 5 seconds (or press Ctrl-C to cancel)"

for((i=1; $i<=5; i++)); do

	echo $i
	sleep 1

done

if [ -z "$TEST" ] ; then
cloudian-s3curl.pl -post -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT  -- -k -ss 'https://'$ENDPOINT'/'$BUCKET'?lock-policy&lockId='$LOCKID
else
echo -e "cloudian-s3curl.pl -post -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT  -- -k -ss \"https://$ENDPOINT/$BUCKET?lock-policy&lockId=$LOCKID\""
fi


else

	echo "Skipping lock finalization; use --autolock to complete the lock"
	TEST=1
fi

echo "Complete"


if ! [ -z "$AUTOLOCK" ]; then
echo "current state:"
if [ -z "$TEST" ]; then
cloudian-s3curl.pl -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT -- -k -ss 'https://'$ENDPOINT'/'$BUCKET'?lock-policy' | jq .State
else
echo -e "cloudian-s3curl.pl -id=$ACCESSKEYID --key=$SECRETKEY --endpoint=$ENDPOINT -- -k -ss \"https://$ENDPOINT/${BUCKET}?lock-policy\" | jq .State"
fi


fi
