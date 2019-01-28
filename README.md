The build_worker_tags.sh script will add a "tags" to different parts of a yml
I may be missing some things that could use a tag but it is getting jobs/resources/gets/tasks

The output of the script is a file called pipeline_final.yml
It will create a tag that would be replaced with a bash variable

The process is to create an ops file (worker_patch.yml) and then use yaml_patch to create the final output

To test
./build_worker_tags.sh pipeline.yml

bosh int pipeline_final.yml -v worker-tags=[China]


