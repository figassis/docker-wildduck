#!/bin/sh
set -x

source "${SCRIPTS_DIR}/00-define_variables.sh";
source "${SCRIPTS_DIR}/_utils.sh";
source "${SCRIPTS_DIR}/_init-env-vars.sh";
source "${SCRIPTS_DIR}/_wildduck.sh";
source "${SCRIPTS_DIR}/_haraka.sh";
source "${SCRIPTS_DIR}/_zonemta.sh";
source "${SCRIPTS_DIR}/_antispam.sh";
source "${SCRIPTS_DIR}/_dkim.sh";

main () {
    # === Configure ===
    init_runtime_env_variables;
    configure_wildduck;
    configure_haraka;
    configure_zonemta;
    configure_antispam;
    link_dkim_keys;

    # === Start ===
    start_antispam;

    start_wildduck &
    local WILDDUCK_PID=$!;

    start_haraka &
    local HARAKA_PID=$!;

    start_zonemta &
    local ZONEMTA_PID=$!;

    add_dkim_for_mail_domain;

    wait $WILDDUCK_PID;
    wait $HARAKA_PID;
    wait $ZONEMTA_PID;
}

main "$@";
