#!/bin/bash

input_file=''

display_usage() {
    echo
    echo "Provide the name of the input file (i.e. pipeline.yml)"
    echo "build_worker_tags.sh pipeline.yml"
}

function createFile {
    echo "# Generated patch file to add worker tags" > worker_patch.yml
}

function pushOpForTask {
    echo "- op: add" >> worker_patch.yml
    echo -e "  path: /jobs/name=$1/task=$2/tags" >> worker_patch.yml
    echo -e "  value: ((worker-tags))" >> worker_patch.yml
    echo "" >> worker_patch.yml
}

function pushOpForGet {
    echo "- op: add" >> worker_patch.yml
    echo -e "  path: /jobs/name=$1/plan/0/aggregate/get=$2/tags" >> worker_patch.yml
    echo -e "  value: ((worker-tags))" >> worker_patch.yml
    echo "" >> worker_patch.yml
}

function pushOpForResource {
    echo "- op: add" >> worker_patch.yml
    echo -e "  path: /resources/name=$1/tags" >> worker_patch.yml
    echo -e "  value: ((worker-tags))" >> worker_patch.yml
    echo "" >> worker_patch.yml
}

function processTasks {
    tasks=$(eval bosh int $input_file --path=/jobs/name=$1 | grep task:)
    tasklist=${tasks//task: /}
    for taskName in ${tasklist[*]}; do
        pushOpForTask $1 $taskName
    done
}

function processGets {
    gets=$(eval bosh int $input_file --path=/jobs/name=$1/plan/0/aggregate | grep -- '- get: ')
    getList=${gets//- get: /}
    for getName in ${getList[*]}; do
        pushOpForGet $1 $getName
    done
}

function processJobs {
    jobs=$(eval bosh int $input_file --path=/jobs | grep -- '- name:')
    joblist=${jobs//- name: /}
    for jobName in ${joblist[*]}; do
        processTasks $jobName
        processGets $jobName
    done
}

function processResources {
    resources=$(eval bosh int $input_file --path=/resources | grep -- '- name:')
    resourceList=${resources//- name: /}
    for resourceName in ${resourceList[*]}; do
        pushOpForResource $resourceName
    done
}

function applyPatch {
    cat $input_file | yaml-patch -o worker_patch.yml > pipeline_final.yml
}

input_file=$1
if [[ -z "$input_file" ]]
then
    display_usage
    case "$-" in
    *i*)	return;;
    *)	exit;;
    esac
fi

createFile
processJobs
processResources
applyPatch

