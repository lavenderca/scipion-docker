FROM nvidia/cuda:7.5-cudnn5-devel-centos7

# Install Scipion dependencies
RUN yum install -y \
	csh \
	which \
	make \
	git \
	wget \
	gcc-c++ \
	glibc-headers \
	gcc \
	gcc-g++ \
	cmake \
	java-1.8.0-openjdk-devel.x86_64 \
	libXft-devel.x86_64  \
	openssl-devel.x86_64 \
	libXext-devel.x86_64 \
	libxml++.x86_64 \
	libquadmath-devel.x86_64 \
	libxslt.x86_64 \
	openmpi openmpi-devel.x86_64 \
	gsl-devel.x86_64 \
	libX11.x86_64 \
	gcc-gfortran.x86_64 \
#	mesa-dri-drivers.x86_64 \
	mesa-libGL-devel \
	mesa-libGLU-devel \
	libXrender-devel \
	libSM-devel \
	libX11-devel \
	fontconfig && \
	yum clean headers && \
	yum clean packages && \
	yum clean metadata

# Install bbcp
RUN yum groupinstall -y "Development Tools" "Development Libraries" && \
	wget http://www.slac.stanford.edu/~abh/bbcp/bbcp.tgz && \
	tar -zxvf bbcp.tgz && \
	cd bbcp/src && make && \
	cd / && \
	cp /bbcp/bin/amd64_linux/bbcp /usr/bin/ && \
	rm -rf /bbcp/ && \
	rm -rf /bbcp.tgz && \
	yum groupremove -y "Development Tools" "Development Libraries" && \
	yum clean headers && \
  yum clean packages && \
  yum clean metadata

# Create user 'scipion'
RUN adduser -m scipion
USER scipion
WORKDIR /home/scipion/

# Clone scipion repository
RUN git clone https://github.com/I2PC/scipion.git --branch release-1.1 --single-branch
WORKDIR /home/scipion/scipion

# Manage paths for openmpi
RUN echo "n\n" | ./scipion config
RUN sed 's/\/usr\/lib64\/mpi\/gcc\/openmpi\/lib/\/usr\/lib64\/openmpi\/lib/g;s/\/usr\/lib64\/mpi\/gcc\/openmpi\/include/\/usr\/include\/openmpi-x86_64/g;s/\/usr\/lib64\/mpi\/gcc\/openmpi\/bin/\/usr\/lib64\/openmpi\/bin/g' config/scipion.conf > temp && \
	mv temp config/scipion.conf

# Comment out code setting LD_LIBRARY_PATH for EMAN2
RUN sed "s/'LD_LIBRARY_PATH'/# 'LD_LIBRARY_PATH'/" pyworkflow/em/packages/eman2/eman2.py > temp && \
	mv temp pyworkflow/em/packages/eman2/eman2.py

# Perform Scipion installation and installation of related packages
RUN ./scipion install -j 8 && ./scipion install \
	Gautomatch \
	Gctf \
	bsoft \
	chimera \
	cryoem \
	ctffind \
	ctffind4 \
	dogpicker \
	eman \
	frealign \
	gEMpicker \
	localrec \
	mag_distortion \
	motioncor2 \
	motioncorr \
	nma \
	relion \
	resmap \
	simple \
	spider \
	summovie \
	unblur && \
	rm -rf /home/scipion/scipion/software/tmp && \
	rm -rf /home/scipion/scipion/software/em/*tgz

# Clone scipion scripts and add to Scipion
WORKDIR /home/scipion
RUN git clone https://github.com/lavenderca/scipion-scripts.git scipion_scripts
RUN mv scipion_scripts/protocol_qc_monitor.py scipion/pyworkflow/em/protocol/monitors/protocol_qc_monitor.py && echo "" >> scipion/pyworkflow/em/protocol/monitors/__init__.py && echo "from protocol_qc_monitor import ProtQCSummary" >> scipion/pyworkflow/em/protocol/monitors/__init__.py
WORKDIR /home/scipion/scipion

# Set environmental variables
ENV QT_X11_NO_MITSHM=1

# Fix Java font issue by adding a config file
COPY local.conf /etc/fonts/
