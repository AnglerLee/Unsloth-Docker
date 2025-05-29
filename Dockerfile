# CUDA 12.1과 cuDNN이 포함된 Ubuntu 22.04 베이스 이미지 사용
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Ubuntu 저장소를 카카오 미러로 변경
RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \
    sed -i 's/ports.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

# 사용자 계정 설정 (angler)
RUN useradd -m -s /bin/bash angler && \
    usermod -aG sudo angler

# Ubuntu 저장소 업데이트 및 기본 프로그램 설치 (SSH 포함)
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install -y \
    openssh-server \
    wget \
    curl \
    git \
    vim \
    build-essential \
    sudo \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 추가 개발 도구 설치 (별도 레이어)
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    python3-dev \
    python3-pip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# sudo 권한 설정 (패스워드 없이)
RUN echo "angler ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSH 서버 설정
RUN mkdir /var/run/sshd && \
    echo 'root:rootpassword' | chpasswd && \
    echo 'angler:anglerpassword' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH 포트 노출
EXPOSE 22

# 사용자 계정으로 전환
USER angler
WORKDIR /home/angler

# Certificate 파일 복사 (로컬에서 복사)
# 사용 시 docker build 명령에서 --build-context 또는 COPY 명령 사용
COPY --chown=angler:angler certificates/ /home/angler/.certificates/

# Certificate를 Ubuntu 시스템에 등록
USER root
RUN if [ -d "/home/angler/.certificates" ]; then \
    cp /home/angler/.certificates/*.crt /usr/local/share/ca-certificates/ 2>/dev/null || true && \
    cp /home/angler/.certificates/*.pem /usr/local/share/ca-certificates/ 2>/dev/null || true && \
    find /home/angler/.certificates -name "*.crt" -exec cp {} /usr/local/share/ca-certificates/ \; 2>/dev/null || true && \
    find /home/angler/.certificates -name "*.pem" -exec sh -c 'cp "$1" "/usr/local/share/ca-certificates/$(basename "$1" .pem).crt"' _ {} \; 2>/dev/null || true && \
    update-ca-certificates; \
fi

USER angler

# Miniconda 설치
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /home/angler/miniconda3 && \
    rm miniconda.sh

# PATH에 conda 추가
ENV PATH="/home/angler/miniconda3/bin:$PATH"

# conda 초기화
RUN conda init bash

# Unsloth 환경 생성 및 패키지 설치
RUN conda create --name unsloth_env \
    python=3.11 \
    pytorch-cuda=12.1 \
    pytorch cudatoolkit xformers -c pytorch -c nvidia -c xformers \
    -y

# unsloth_env 환경에서 pip 업그레이드 및 unsloth 설치
RUN /bin/bash -c "source /home/angler/miniconda3/etc/profile.d/conda.sh && \
    conda activate unsloth_env && \
    pip install --upgrade pip && \
    pip install 'unsloth[cu121-torch240] @ git+https://github.com/unslothai/unsloth.git'"

# conda 환경 활성화를 위한 쉘 스크립트 생성
RUN echo "#!/bin/bash" > /home/angler/activate_unsloth.sh && \
    echo "source /home/angler/miniconda3/etc/profile.d/conda.sh" >> /home/angler/activate_unsloth.sh && \
    echo "conda activate unsloth_env" >> /home/angler/activate_unsloth.sh && \
    echo 'exec "$@"' >> /home/angler/activate_unsloth.sh && \
    chmod +x /home/angler/activate_unsloth.sh

# .bashrc에 conda 자동 활성화 및 proxy 설정 추가
RUN echo "source /home/angler/miniconda3/etc/profile.d/conda.sh" >> /home/angler/.bashrc && \
    echo "conda activate unsloth_env" >> /home/angler/.bashrc && \
    echo "" >> /home/angler/.bashrc && \
    echo "# Proxy Settings" >> /home/angler/.bashrc && \
    echo "export http_proxy=http://proxy.company.com:8080" >> /home/angler/.bashrc && \
    echo "export https_proxy=http://proxy.company.com:8080" >> /home/angler/.bashrc && \
    echo "export HTTP_PROXY=http://proxy.company.com:8080" >> /home/angler/.bashrc && \
    echo "export HTTPS_PROXY=http://proxy.company.com:8080" >> /home/angler/.bashrc && \
    echo "export no_proxy=localhost,127.0.0.1,::1" >> /home/angler/.bashrc && \
    echo "export NO_PROXY=localhost,127.0.0.1,::1" >> /home/angler/.bashrc

# 작업 디렉토리 설정
WORKDIR /home/angler/workspace
RUN mkdir -p /home/angler/workspace

# 기본 명령어 설정 (SSH 서버 시작 및 unsloth_env 환경 활성화)
ENTRYPOINT ["/bin/bash", "-c", "sudo service ssh start && /home/angler/activate_unsloth.sh /bin/bash"]
EXPOSE 22