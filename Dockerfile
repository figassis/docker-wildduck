FROM astzweig/wildduck

ARG WILDDUCK_GIT_REPO=https://github.com/figassis/wildduck
ARG WILDDUCK_GIT_CID=develop
ENV CONFIG_DIR=/etc/nodemailer

RUN rm -rf ${INSTALL_DIR} ${CONFIG_DIR}/wildduck ${SCRIPTS_DIR}/*

COPY ./scripts/[0-9][0-9]-*.sh ${SCRIPTS_DIR}/

# Scripts are named like: {ORDER PREFIX}-{NAME}.sh.
# Run files in sequence as induced by their order prefix (00-99).
RUN for file in ${SCRIPTS_DIR}/[0-9][0-9]-*.sh; do \
    chmod u+x "${file}"; \
    source "${file}"; \
    done

COPY ./scripts/[^0-9]*.sh ${SCRIPTS_DIR}/
COPY ./scripts/bin /usr/local/bin
RUN chmod +x ${SCRIPTS_DIR}/entrypoint.sh; \
    chmod +x /usr/local/bin/*;

VOLUME ["/etc/nodemailer"]

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ${SCRIPTS_DIR}/entrypoint.sh