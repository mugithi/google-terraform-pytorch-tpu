FROM gcr.io/tpu-pytorch/xla:nightly${IMAGE_NIGHTLY}
# FROM debian:stretch 

## Set Docker Arguments 
ARG MOUNT_POINT=""
ARG NFS_IP=""
ARG SHARED_FS=""
ARG IMAGE_NIGHTLY=""

## Copy the enviromental file and set permissions
COPY setup_nightly.sh .
RUN chmod a+x setup_nightly.sh

# Define entrypoint and cmd
COPY docker-entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
# Use conda environment on startup or when running scripts.
ENV PATH /root/anaconda3/envs/pytorch/bin/:$PATH

RUN echo "*  soft    nofile       100000" |  tee -a /etc/security/limits.conf && \
    echo "*  hard    nofile       100000" |  tee -a /etc/security/limits.conf 

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]