ARG BASE_IMAGE
ARG TOOLKIT_IMAGE

# Declare Toolkit image
FROM ${TOOLKIT_IMAGE} AS toolkit

############################
#### INTERMEDIATE Stage ####
############################
FROM ${BASE_IMAGE} AS prepare_install

# set arguments
ARG eddl_src_origin="eddl"
ARG eddl_src_target="/usr/local/src/eddl"

# make a temporary copy of libraries
COPY --from=toolkit /usr/local/etc /tmp/local/etc
COPY --from=toolkit /usr/local/include /tmp/local/include
COPY --from=toolkit /usr/local/lib /tmp/local/lib
COPY --from=toolkit /usr/local/share /tmp/local/share
COPY --from=toolkit /usr/local/src/eddl/build/install_manifest.txt /tmp/local/install_manifest.txt

# merge existing system directories with those containing libraries
RUN cd /tmp/local && sed -e 's+/usr/local/++g' /tmp/local/install_manifest.txt | \
    while IFS= read -r line; do echo ">>> $line" ; rsync --relative "${line}" "/usr/local/" || exit ; done

######################
#### TARGET Stage ####
######################
FROM scratch AS libs.eddl

# Set metadata
LABEL website="https://github.com/deephealthproject" \
      description="DeepHealth European Distributed Deep Learning Library" \
      software="deephealth-eddl"

COPY --from=prepare_install /bin /bin
COPY --from=prepare_install /boot /boot
COPY --from=prepare_install /dev /dev
COPY --from=prepare_install /etc /etc
COPY --from=prepare_install /home /home
COPY --from=prepare_install /lib /lib
COPY --from=prepare_install /lib64 /lib64
COPY --from=prepare_install /media /media
COPY --from=prepare_install /mnt /mnt
COPY --from=prepare_install /opt /opt
COPY --from=prepare_install /proc /proc
COPY --from=prepare_install /root /root
COPY --from=prepare_install /run /run
COPY --from=prepare_install /sbin /sbin
COPY --from=prepare_install /srv /srv
COPY --from=prepare_install /sys /sys
COPY --from=prepare_install /usr /usr
COPY --from=prepare_install /var /var

# create the /tmp folder with right permissions
RUN mkdir -p /tmp && chmod 1777 /tmp

# default cmd
CMD ["/bin/bash"]