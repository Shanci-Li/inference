FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 AS base

########################################################################################################################
# Install python and pip
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y python3 python3-pip \
    && apt install -y wget git vim nano tmux rsync \
    && apt install -y htop ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# RUN mkdir /.cache && chmod 777 /.cache
########################################################################################################################

ENV CUDA_HOME=/usr/local/cuda-12.1
ENV CONDA_PATH=/opt/miniconda3
RUN mkdir $CONDA_PATH
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \ 
    && bash /tmp/miniconda.sh -b -u -p $CONDA_PATH \
    && rm /tmp/miniconda.sh

ENV PATH="$CONDA_PATH/bin:$PATH"

RUN /opt/miniconda3/bin/conda init

RUN conda create -n magic -y python=3.9

SHELL ["conda", "run", "-n", "magic", "/bin/bash", "-c"]

RUN conda install -c conda-forge gdal \
    && pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121 \
    && pip install -U openmim ftfy regex rasterio tensorboardX future tensorboard \
    && pip install albumentations>=0.3.2 --no-binary qudida,albumentations \
    && pip install numpy==1.24.4 pandas tqdm whitebox rasterio geopandas shapely scipy laspy[laszip] tifffile imagecodecs opencv-python fiona==1.9.6 wget \
    && mim install mmengine==0.10.3 \
    && mim install mmcv==2.1.0 \
    && pip install -U "jax[cuda12_pip]==0.4.13" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html \
    && pip install "mmsegmentation>=1.0.0" 

# RUN apt update
# RUN mkdir -p -m 0700 /root/.ssh && ssh-keyscan gitlab.com >> /root/.ssh/known_hosts
WORKDIR /home/root
# RUN --mount=type=ssh git clone git@gitlab.com:heig-vd-geo/magic3d.git
RUN git clone https://github.com/Shanci-Li/magic3d.git
RUN git clone https://github.com/potree/PotreeConverter.git

WORKDIR /home/root/PotreeConverter
RUN apt-get update \
    && apt-get install -y cmake libtbb-dev \
    && mkdir build

WORKDIR /home/root/PotreeConverter/build
RUN cmake ../ && make

WORKDIR /home/root/magic3d/superpoint_transformer
RUN ./install.sh 

CMD python /home/root/magic3d/scripts/deploy_jax.py 