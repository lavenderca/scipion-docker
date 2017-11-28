FROM nvidia/cuda:7.5-cudnn5-devel-centos7

RUN yum remove -y cpp

# Install Scipion dependencies
RUN yum install -y \
	cpp \
	csh \
	which \
	make \
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
	mesa-libGL-devel \
	mesa-libGLU-devel \
	libXrender-devel \
	libSM-devel \
	libX11-devel \
	fontconfig \
	compat-libtiff3 && \
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

# Copy Scipion files
COPY scipion /home/scipion/scipion
COPY scipion_scripts/protocol_qc_monitor.py /home/scipion/scipion/pyworkflow/em/protocol/monitors/protocol_qc_monitor.py
COPY scipion_scripts/protocol_transfer.py /home/scipion/scipion/pyworkflow/em/protocol/monitors/protocol_transfer.py

# Run Scipion config
RUN echo "n\n" | /home/scipion/scipion/scipion config && \
	mkdir /home/scipion/.config && \
	mkdir /home/scipion/.config/scipion && \
	mv /root/.config/scipion/scipion.conf /home/scipion/.config/scipion/scipion.conf

# Copy config files
COPY config_files/scipion.conf /home/scipion/scipion/config/scipion.conf
COPY config_files/font.conf /etc/fonts/local.conf

RUN chown -R scipion /home/scipion/*
USER scipion
WORKDIR /home/scipion/scipion

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
	motioncor2-16.10.19 \
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

# Set environmental variables
ENV QT_X11_NO_MITSHM=1
