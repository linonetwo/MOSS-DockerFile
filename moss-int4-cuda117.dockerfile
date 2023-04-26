FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

ENV NVIDIA_VISIBLE_DEVICES=all NVIDIA_DRIVER_CAPABILITIES=compute,utility\
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64

# This Env setting is aimd to display Linux-original window in Windows through WSLg.
ENV DISPLAY=:0 CODEDIR=/opt/project XDG_RUNTIME_DIR=/usr/lib/

# Create a working directory
RUN mkdir $CODEDIR
WORKDIR $CODEDIR

# Remove all third-party apt sources to avoid issues with expiring keys.
RUN rm -f /etc/apt/sources.list.d/*.list && rm -rf /var/lib/apt/lists/*

# speedup apt-get
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

# Install some basic utilities
RUN apt-get update --fix-missing && apt-get -y --no-install-recommends install  ca-certificates libjpeg-dev libpng-dev\
    sudo git vim traceroute inetutils-ping net-tools curl fontconfig wget\
    libgl1 libglib2.0-dev libfontconfig libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0  \
    libxcb-shape0 libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxkbcommon-x11-0 libfontconfig1 libdbus-1-3 libx11-6 \
    openssh-server htop \
    python3.10 python3-pip python3-dev

RUN git clone https://github.com/OpenLMLab/MOSS.git --filter=blob:none --depth=1
RUN cd MOSS

WORKDIR $CODEDIR/MOSS

# install python packages
# fix ERROR: Could not find a version that satisfies the requirement torch==1.10.1 (from versions: 1.11.0, 1.12.0, 1.12.1, 1.13.0, 1.13.0+cu117, 1.13.1, 1.13.1+cu117, 2.0.0, 2.0.0+cu117)
RUN sed -i 's/torch==1.10.1/torch==1.13.1+cu117/' requirements.txt
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --extra-index-url https://download.pytorch.org/whl/cu117 -r requirements.txt

WORKDIR $CODEDIR
ENV GIT_LFS_SKIP_SMUDGE=1
RUN git clone https://huggingface.co/fnlp/moss-moon-003-sft-plugin-int4 --filter=blob:none --depth=1
# fix name 'autotune' is not defined
RUN mkdir -p /root/.cache/huggingface/modules/transformers_modules/local/ && cp $CODEDIR/moss-moon-003-sft-plugin-int4/custom_autotune.py /root/.cache/huggingface/modules/transformers_modules/local/
LABEL maintainer="LinOnetwo <linonetwo012@gmail.com>"

# Clean up intermediate files to save some space
RUN apt-get -qy autoremove
RUN rm -r /opt/nvidia/

RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple mdtex2html triton

WORKDIR $CODEDIR/MOSS
COPY ./moss_web_demo_gradio.py ./moss_web_demo_gradio.py
# Enable sharing, comment out if you don't need it
RUN sed -i 's/share=False, inbrowser=True/share=True, inbrowser=True/' moss_web_demo_gradio.py
# model is in /mnt/llm/MOSS/moss-moon-003-sft-plugin-int4
# RUN sed -i 's#fnlp/moss-moon-003-sft#/mnt/llm/MOSS/moss-moon-003-sft-plugin-int4#' moss_web_demo_gradio.py

ENTRYPOINT ["/usr/bin/python3"]
CMD ["moss_web_demo_gradio.py"]
# ENTRYPOINT ["/usr/bin/env"]
# CMD ["ls", "-al", "/mnt/llm/MOSS/moss-moon-003-sft-plugin-int4"]