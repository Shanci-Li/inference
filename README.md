# Getting Started

## Requirements

- Linux machine
- Docker 
- NVIDIA GPU with at least 32GB memory
- Approximately 6~15 times disk space of input image and LiDAR data for intermediate result storage (wo/w depth map saved)

# File Structure

Input ORBIS data should follow structure as below:

```
`-- ${DATA_PATH}
    |-- ORBIS_NEUCHATEL                                 # Survey name with prefix **ORBIS_**
    |   |-- IMAGES
    |   |   |-- 85266_PANORAMA_POS_ORI.csv              # Metadata with sufix **_PANORAMA_POS_ORI.csv**
    |   |   `-- JPG                                     # Panoramic images
    |   `-- LASER
    |       |-- 85266_EMPRISE_BLOCS_LASER.dbf
    |       |-- 85266_EMPRISE_BLOCS_LASER.shp           # SHP file with sufix **_EMPRISE_BLOCS_LASER.shp**
    |       |-- 85266_EMPRISE_BLOCS_LASER.shx
    |       |-- 85266_SIT_NEUCHATEL_MN95.dgn
    |       |-- 85266_TSCAN_BLOCS.prj
    |       |-- 85266_TSCAN_CLASSES.ptc
    |       `-- BLOCS                                   # LiDAR file (.las or .laz)
    |-- ORBIS_VEVEY
        ...
    `-- mask.jpg                                        # Binary mask for panoramics to remove acquisition equipment
```

All the survey under `${DATA_PATH}` will be processed with a single inference. After inference, file structure changes as below:

```
`-- ${DATA_PATH}
    |-- ORBIS_NEUCHATEL
    |   |-- IMAGES
    |   |   |-- 85266_PANORAMA_POS_ORI.csv
    |   |   |-- JPG
    |   |   |-- coordinates.txt                         # Image meta for potree
    |   |   |-- depth_map                               # Depth maps
    |   |   `-- semantic_prediction                     # Image semantics inference
    |   |-- LASER
    |   |   |-- 85266_EMPRISE_BLOCS_LASER.dbf
    |   |   |-- 85266_EMPRISE_BLOCS_LASER.shp
    |   |   |-- 85266_EMPRISE_BLOCS_LASER.shx
    |   |   |-- 85266_SIT_NEUCHATEL_MN95.dgn
    |   |   |-- 85266_TSCAN_BLOCS.prj
    |   |   |-- 85266_TSCAN_CLASSES.ptc
    |   |   |-- BLOCS
    |   |   |-- Prediction                              # LiDAR semantics inference in blocks
    |   |   `-- buffer                                  # Buffer tiles (Deletable)    
    |   `-- potree                                      # PotreeConvertor processed files
    |-- ORBIS_VEVEY
        ... 
    |-- inference.log                                   # log file 
    `-- mask.jpg
```
_mask.jpg for current hardware configuration is enclosed in `resources/`._


# LiDAR semantic 

## Installation 

1. Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

2. Build docker image with legacy mode (DOCKER_BUILDKIT disabled)

```bash
DOCKER_BUILDKIT=0 docker build -t magic3d_jax .
```

3. Mount the data folder path and run the container
```bash
docker run -v ${DATA_PATH}:/mnt/ --gpus all --ipc=host  magic3d_jax
```

4. Optional: interactive inference
    - launch interactive container
        ```bash
        docker run -it -v ${DATA_PATH}:/mnt/data/ --gpus all --ipc=host  magic3d_jax /bin/bash   
        ```
    - run inference script with customized behavior
        ```bash
        # save depth maps
        python /home/root/magic3d/scripts/deploy_jax.py --save_depth

        # skip spt inference if spt prediction already exists in intermediate buffered tiles 
        python /home/root/magic3d/scripts/deploy_jax.py --skip_spt
        ```

# Potree visualization


1. Generate HTML file for each survey 

```bash
pip install jinja2
python scripts/generate_html.py ${SURVEY} ${SURVEY_XXX}
```

2. Download Potree implementation with panoramic image/label support

```bash
git clone https://github.com/Shanci-Li/potree_pano.git
```

3. Link point cloud / image data / HTML files

```bash
mv html/*.html ./potree_pano/examples/
ln -s ${DATA_PATH}/ORBIS_${SURVEY}/potree ./potree_pano/pointclouds/${SURVEY}
```

### Install Potree

Install [node.js](http://nodejs.org/)

Install dependencies, as specified in package.json, and create a build in ./build/potree.

```bash
cd potree_pano
npm install
```

### Run Visualization

Use the `npm start` command to 

* create ./build/potree 
* watch for changes to the source code and automatically create a new build on change
* start a web server at localhost:1234. 

Go to http://localhost:1234/examples/ to test the examples.
