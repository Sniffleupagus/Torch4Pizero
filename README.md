# Torch4Pizero
compiling the pytorch neural network backend for pizerow and bananapim2zero

This is not perfect. It is notes I made while figuring out how to get it going.  there are typos,
but I am able to follow this as a general guide and end up with an installable wheel for the pizerow.

I tried building on an actual pizeroW, but i think the memory requirements are too much. Instead I
build it in a Docker container, emulating a 10-core 3.6 Ghz pizero. It takes about 5 hours to build.

Prebuilt wheels for python 3.9 that work on the 2022 and 2023 raspiOS bulids with kernels 5.15.84 and 6.1.21 so far.

<code>
dd if=/dev/zero of=/swapfile1 bs=1024 count=3144000
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1
swapon /swapfile1

nano /etc/fstab
##### add following line to end of fstab
/swapfile1 none swap sw 0 0


################################
#!/usr/bin/env bash

cat > /tmp/dependencies << EOF
libopenblas-dev
cmake
clang
python3-distutils 
python3-dev
python3-pip
python3-protobuf
python3-numpy
python3-cffi
python3-wheel
python3-pillow
python3-yaml
python3-setuptools
libprotobuf-dev
EOF

sudo apt -q update
for pkg in $(cat /tmp/dependencies)
do
  sudo apt install -y $pkg
done

#####################

git clone --depth=1 https://github.com/pytorch/pytorch --recursive && cd pytorch
pip3 install -r requirements.txt

export USE_CUDA=0
export USE_DISTRIBUTED=0
export USE_MKLDNN=0
export BUILD_TEST=0
export BUILD_BINARY=0
export MAX_JOBS=1
export CC=clang

if [ $(uname -m} = "armv6l" ]; then
	export USE_NNPACK=0
	export USE_QNNPACK=0
	export USE_PYTORCH_QNNPACK=0
	export USE_XNNPACK=0
	export USE_NUMA=0
	export USE_SYSTEM_CPUINFO=ON
	export USE_SYSTEM_SLEEF=ON
	export BUILD_CUSTOM_PROTOBUF=OFF

	#### dependencies from armv6 build - some duplicates from above
	apt install systemd passwd vim-minimal \
		libopenblas-dev libblas-dev m4 cmake cython3 python3-devel python3-yaml \
		python3-pil python3-setuptools python3-numpy python3-cffi python3-wheel \
		gcc-c++ tar gcc git make tmux

	apt install libprotobuf-dev python3-protobuf
	apt install libcpuinfo-dev

	# patch /usr/include/cpuinfo.h for a missing check - GROSS, but whatever
    sudo patch /usr/include/cpuinfo.h <<EOP
--- /tmp/cpuinfo.h	2023-07-09 11:36:13.993161372 -0700
+++ cpuinfo.h	2023-07-09 11:35:47.923343576 -0700
@@ -1468,6 +1468,11 @@
 	extern struct cpuinfo_arm_isa cpuinfo_isa;
 #endif
 
+/* needed for pytorch build */
+static inline bool cpuinfo_has_arm_bf16(void) {
+	return false;
+}
+
 static inline bool cpuinfo_has_arm_thumb(void) {
 	#if CPUINFO_ARCH_ARM
 		return cpuinfo_isa.thumb;
EOP

fi    # if $(uname -m) = "armv6l"

time python3 setup.py bdist_wheel

#
# torchvision
#
cd ..
git clone --depth=1 https://github.com/pytorch/vision && cd vision

time python3 setup.py bdist_wheel
# real	85m11.918s
#user	70m1.210s
#sys	6m16.943s
sudo python3 setup.py install
</code>
