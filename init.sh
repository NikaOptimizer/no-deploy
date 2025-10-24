project_root=/home/szotica/azotic/nika/
dir="$( cd "$( dirname "$0" )" && pwd )"
docker_name="nika"

for lib in "$@"
do 
    if [ ! -d "$project_root/$lib" ]; then
        echo "$project_root/$lib was not found."
        exit
    fi
done

docker build -t $docker_name .

docker run --name $docker_name -h $docker_name --network host\
 -v $project_root:/home/nika/libs \
 -ti -d nika:latest

# wait for container to start
sleep 3 

# install git and git libs in editable mode
docker exec -it $docker_name bash -c "cd /home/nika/libs && echo $@ | xargs -n 1 python3 -m pip install -e"


docker stop $docker_name
docker start $docker_name
