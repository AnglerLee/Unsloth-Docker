# CUDA Unsloth Docker Environment

CUDA 12.1, cuDNN, Ubuntu 22.04 기반의 Unsloth 개발 환경을 위한 Docker 이미지입니다.

## 🚀 주요 기능

### 기본 환경
- **OS**: Ubuntu 22.04 LTS
- **CUDA**: 12.1 with cuDNN 8
- **Python**: 3.11 (Miniconda)
- **사용자**: angler (sudo 권한 포함)

### 설치된 패키지
- **AI/ML 프레임워크**: PyTorch, CUDA Toolkit, XFormers
- **Unsloth**: `unsloth[cu121-torch240]` (최신 버전)
- **개발 도구**: git, vim, wget, curl, build-essential
- **네트워크**: SSH 서버 (포트 22)

### 네트워크 설정
- **저장소**: 카카오 미러 서버 (mirror.kakao.com)
- **Proxy**: 환경변수로 설정 가능
- **Certificate**: 사용자 정의 인증서 지원

## 📋 사전 준비

### 1. 인증서 파일 준비 (선택사항)
```bash
mkdir certificates
# 필요한 .crt 또는 .pem 파일을 certificates/ 폴더에 복사
```

### 2. NVIDIA Docker 설치 확인
```bash
# NVIDIA Docker runtime 확인
docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi
```

## 🔧 빌드 및 실행

### Docker 이미지 빌드
```bash
# 기본 빌드
docker build -t cuda-unsloth:latest .

# 빌드 로그 상세 출력
docker build --progress=plain -t cuda-unsloth:latest .
```

### 컨테이너 실행

#### 기본 실행
```bash
docker run --gpus all -it cuda-unsloth:latest
```

#### 포트 포워딩 포함 (SSH 접속용)
```bash
docker run --gpus all -it -p 2222:22 cuda-unsloth:latest
```

#### 볼륨 마운트 포함
```bash
docker run --gpus all -it \
  -p 2222:22 \
  -v $(pwd)/workspace:/home/angler/workspace \
  cuda-unsloth:latest
```

#### 백그라운드 실행
```bash
docker run --gpus all -d \
  --name unsloth-container \
  -p 2222:22 \
  -v $(pwd)/workspace:/home/angler/workspace \
  cuda-unsloth:latest
```

### SSH 접속
```bash
# 컨테이너 실행 후 SSH로 접속
ssh -p 2222 angler@localhost

# 기본 비밀번호
# angler: anglerpassword
# root: rootpassword
```

## 💻 VS Code 사용법

### 1. Docker Extension 설치
VS Code에서 Docker Extension을 설치합니다.

### 2. 컨테이너 실행 설정
VS Code의 `settings.json`에 다음 설정을 추가합니다:

```json
{
  "docker.containers.defaultRunOptions": [
    "--gpus", "all"
  ]
}
```

### 3. Dev Container 설정 (선택사항)
프로젝트 루트에 `.devcontainer/devcontainer.json` 파일을 생성합니다:

```json
{
  "name": "CUDA Unsloth Environment",
  "image": "cuda-unsloth:latest",
  "runArgs": [
    "--gpus", "all"
  ],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.jupyter",
        "ms-toolsai.jupyter"
      ]
    }
  },
  "forwardPorts": [22],
  "remoteUser": "angler",
  "workspaceFolder": "/home/angler/workspace"
}
```

### 4. VS Code에서 컨테이너 사용

#### 방법 1: Docker Extension 사용
1. VS Code에서 Docker Extension 열기
2. 이미지 목록에서 `cuda-unsloth:latest` 우클릭
3. "Run Interactive" 선택
4. 터미널에서 `--gpus all` 옵션 확인

#### 방법 2: Dev Container 사용
1. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
2. 자동으로 GPU 옵션이 적용된 컨테이너에서 작업

#### 방법 3: SSH 연결 사용
1. 컨테이너를 SSH 포트와 함께 실행
2. VS Code에서 Remote-SSH extension 사용
3. `ssh angler@localhost -p 2222`로 연결

## 🛠️ 사용 예제

### Python 환경 확인
```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"Device count: {torch.cuda.device_count()}")
```

### Unsloth 사용 예제
```python
from unsloth import FastLanguageModel
import torch

# 모델 로드 예제
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-2-7b-bnb-4bit",
    max_seq_length=2048,
    dtype=None,
    load_in_4bit=True,
)
```

## 🔧 환경 변수

컨테이너 내부에서 자동으로 설정되는 환경 변수들:

```bash
# Proxy 설정 (필요시 수정)
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080
export no_proxy=localhost,127.0.0.1,::1

# CUDA 환경
export CUDA_HOME=/usr/local/cuda
export PATH=$PATH:/usr/local/cuda/bin
```

## 📝 주의사항

1. **GPU 메모리**: 대용량 모델 사용 시 충분한 GPU 메모리 확인
2. **네트워크**: 프록시 환경에서는 `.bashrc`의 프록시 설정 수정 필요
3. **인증서**: 회사 인증서가 필요한 경우 `certificates/` 폴더에 추가
4. **포트**: SSH 접속 시 호스트의 2222 포트 사용 (충돌 시 변경)

## 🐛 문제 해결

### 빌드 실패 시
```bash
# 캐시 없이 다시 빌드
docker build --no-cache -t cuda-unsloth:latest .
```

### GPU 인식 안될 시
```bash
# NVIDIA Docker runtime 재설치
# 또는 nvidia-container-toolkit 업데이트
```

### SSH 접속 안될 시
```bash
# 컨테이너 내부에서 SSH 서비스 상태 확인
sudo service ssh status
sudo service ssh restart
```

## 📄 라이선스

이 Dockerfile은 MIT 라이선스를 따릅니다. 각 포함된 소프트웨어는 해당 라이선스를 따릅니다.