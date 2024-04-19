FROM ubuntu
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

RUN apt-get update -y && \
        apt-get install -y curl libgl1 libglib2.0-0 python3-pip python-is-python3 git && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && apt-get install ffmpeg -y 

RUN apt-get update && apt-get install wget git -y
RUN wget https://repo.radeon.com/amdgpu-install/6.1/ubuntu/jammy/amdgpu-install_6.1.60100-1_all.deb
RUN apt-get install ./amdgpu-install_6.1.60100-1_all.deb -y
RUN amdgpu-install -y --accept-eula --no-dkms --usecase=rocm
RUN apt-get install rocm -y
RUN apt-get update -y
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY requirements_docker.txt requirements_versions.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt && \
        rm -f /tmp/requirements_docker.txt /tmp/requirements_versions.txt
RUN pip uninstall -y torch torchvision torchaudio torchtext functorch xformers 
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.6
RUN pip install --no-cache-dir xformers==0.0.22 --no-dependencies
RUN curl -fsL -o /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
        chmod +x /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2

RUN adduser --disabled-password --gecos '' user && \
        mkdir -p /content/app /content/data

COPY entrypoint.sh /content/
RUN chown -R user:user /content

WORKDIR /content
USER user

RUN git clone https://github.com/lllyasviel/Fooocus /content/app
RUN mv /content/app/models /content/app/models.org

CMD [ "sh", "-c", "/content/entrypoint.sh ${CMDARGS}" ]
