#!/bin/bash

FUZZFARM_DIR='$HOME/fuzzfarm_bot_patch'
CLUSTERFUZZ_BOT_DIR='$HOME/clusterfuzz_bot'
CLUSTERFUZZ_SERVER_DIR='$HOME/clusterfuzz_server'

while [ "$1" != "" ]; do
  case $1 in
    --install-server)
      install_server=1
      ;;
    --install-bot)
      install_bot=1
      ;;
  esac
  shift
done

echo "[*] Updating and upgrading"
sudo apt update && sudo apt -y upgrade

echo "[*] Installing python3 related binaries"
sudo apt -y install \
    python3.8 \
    python3.8-distutils \
    python3.8-venv \
    python3-apt \
    python3-dev \
    python3-h5py \
    python3-pip \
    python3-scipy

echo "[*] Installing required libraries"
sudo apt -y install \
    libcairo2-dev \
    libgirepository1.0-dev \
    libpython3-all-dev \
    libhdf5-dev \
    libopenblas-dev \
    liblapack-dev
    # gcc \
    # gir1.2-gtk-3.0

echo "[*] Installing npm requirements"
sudo curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - ;
sudo npm install -g bower polymer-bundler

echo "[*] Installing required binaries" 
sudo apt -y install \
    llvm-11 \
    clang-11 \
    golang \
    nodejs \
    socat \
    sqlite3 \
    build-essential \
    dtach \
    pkg-config \
    blackbox \
    curl \
    unzip \
    xvfb \
    gfortran

echo "[*] Installing gcloud components"
sudo apt -y install \
	apt-transport-https \
	ca-certificates \
	gnupg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update 
sudo apt -y install \
    google-cloud-sdk \
    google-cloud-sdk-app-engine-python \
    google-cloud-sdk-app-engine-python-extras \
    google-cloud-sdk-datastore-emulator \
    google-cloud-sdk-pubsub-emulator

echo "[*] Installing ClusterFuzz"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.8 get-pip.py && rm -f get-pip.py
python3.8 -m pip install --upgrade https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-1.12.0-py3-none-any.whl
python3.8 -m pip install setuptools==45
python3.8 -m pip install --user pipenv

if [ ! $install_server ]; then
    CLUSTERFUZZ_DIR=$CLUSTERFUZZ_SERVER_DIR
elif [ ! $install_bot ]; then
    CLUSTERFUZZ_DIR=$CLUSTERFUZZ_BOT_DIR
fi

mkdir $CLUSTERFUZZ_DIR && cd $CLUSTERFUZZ_DIR
git clone https://github.com/google/clusterfuzz.git .
mv $HOME/Pipfile $CLUSTERFUZZ_DIR/Pipfile
mv $HOME/Pipfile.lock $CLUSTERFUZZ_DIR/Pipfile.lock
python3.8 -m pipenv --python python3.8 install

if [ ! $install_bot ]; then
    python3.8 -m pipenv shell
    python3.8 -m pip install -r src/requirements.txt --upgrade --target src/third_party
fi

echo "[*] Patching ClusterFuzz with fuzzfarm"
tar xzf patch_files.tar.gz 
if [ ! $install_server ]; then
    bash $FUZZFARM_DIR/server_patch.sh && echo "python3.8 butler.py run_server --bootstrap"
elif [ ! $install_bot ]; then
    bash $FUZZFARM_DIR/bot_patch.sh && echo "python3.8 butler.py run_bot my-bot-$(hostname) my-bot-$(hostname)"
fi
