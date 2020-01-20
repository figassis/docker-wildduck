#!/bin/sh

_persist_secret_variables () {
    local _VAR_DEF _VAR_VALUE _VAR_NAME _SECRET_FILE;
    _create_dir_if_empty "${SECRETS_DIR}";
    for _VAR_DEF in $(printenv); do
        _VAR_NAME="$(echo "${_VAR_DEF}" | sed -e 's,\([^=]*\)=.*,\1,')";
        _VAR_VALUE="$(echo "${_VAR_DEF}" | sed -e 's,[^=]*=\(.*\),\1,')";
        if [ "$(expr "${_VAR_NAME}" : '.\+_SECRET$')" -gt 0 ]; then
            # It seems to be a '_SECRET' variable. Persist it.
            _SECRET_FILE="${SECRETS_DIR}/${_VAR_NAME}";
            _VAR_VALUE="$(cat "${_SECRET_FILE}" 2> /dev/null || \
                echo "${_VAR_VALUE}")";
            echo "${_VAR_VALUE}" > "${_SECRET_FILE}";
        fi
    done
}

init_runtime_env_variables () {
    # Initialize environment variables. Variables prefixed with an
    # underscore are 'calculated' variables. That means their value is
    # inferred by the values of other variables.

    # === General ===
    # Simple (too general) domain recognizing regular expression.
    local _DOMAIN_REGEX='[^[:space:]]\{1,63\}\.\+[^[:space:].]\+$';
    _check_value 'FQDN' "${_DOMAIN_REGEX}" 'exit';
    _check_value 'MAIL_DOMAIN' "${_DOMAIN_REGEX}" "${FQDN}";
    _check_value 'PRODUCT_NAME' '.\+' 'Wildduck Mail';
    _check_value 'MONGODB_HOST' '.\+' 'mongodb://mongo:27017/wildduck';

    # === General: Redis ===
    _check_value 'REDIS_HOST' '.\+' 'redis://redis:6379/8';
    # Split REDIS_HOST into components as we need the components in the
    # configuration files.
    export _REDIS_PORT="$(_get_url_part "${REDIS_HOST}" port)";
    export _REDIS_HOSTNAME="$(_get_url_part "${REDIS_HOST}" hostname)";
    export _REDIS_DB="$(_get_url_part "${REDIS_HOST}" path)";

    # === General ===
    export TLS_KEY="${TLS_KEY}";
    export TLS_CERT="${TLS_CERT}";
    export _USE_PROXY='false';
    [ -n "${USE_PROXY}" ] && export _USE_PROXY="${USE_PROXY}";

    export _USE_SSL='false';
    [ -n "${TLS_KEY}" -a -n "${TLS_CERT}" ] && export _USE_SSL='true';
    _check_value 'ENABLE_STARTTLS' 'true\|false' 'false';
    if [ "${ENABLE_STARTTLS}" = 'true' -a "${_USE_SSL}" = 'false' ]; then
        export ENABLE_STARTTLS='false';
    fi

    # === General: Graylog ===
    export GRAYLOG_HOST_PORT="${GRAYLOG_HOST_PORT}";
    export _GRAYLOG_PORT="$(_get_url_part "${GRAYLOG_HOST_PORT}" port)";
    export _GRAYLOG_HOSTNAME="$(_get_url_part "${GRAYLOG_HOST_PORT}" \
        hostname)";
    export _GRAYLOG_ENABLE='false';
    if [ -n "${_GRAYLOG_HOSTNAME}" -a -n "${_GRAYLOG_PORT}" ]; then
        export _GRAYLOG_ENABLE='true';
    fi


    # === API ===
    local PROTO='http';
    _check_value 'API_ENABLE' 'true\|false' 'true';
    _check_value 'API_USE_HTTPS' 'true\|false' 'false';
    _check_value 'API_TOKEN_SECRET' '.\+' '';

    export _API_ACCESS_CONTROL_ENABLE='false';
    export _API_ACCESS_CONTROL_SECRET="$(_get_random_string)";
    [ -n "${API_TOKEN_SECRET}" ] && export _API_ACCESS_CONTROL_ENABLE='true';
    [ -n "${API_ACCESS_CONTROL_SECRET}" ] && export _API_ACCESS_CONTROL_SECRET="${API_ACCESS_CONTROL_SECRET}";

    echo $_API_ACCESS_CONTROL_SECRET;

    export _API_PORT=80;
    if [ "${API_USE_HTTPS}" = 'true' -a "${_USE_SSL}" = 'true' ]; then
        PROTO="${PROTO}s";
        export _API_PORT=443;
    else
        export API_USE_HTTPS='false';
    fi

    _check_value 'API_URL' '.\+' "${PROTO}://${FQDN}";


    # === Configprofile ===
    # default identifier for mobilconfig is the first two parts of the
    # reversed FQDN with '.wildduck' appended.
    local REV_FQDN="$(echo $FQDN | \
        awk '{n = split($0,v,"."); print v[n]"."v[n-1]}').wildduck";
    _check_value 'CONFIGPROFILE_ID' '.\+' "${REV_FQDN}";
    _check_value 'CONFIGPROFILE_DISPLAY_NAME' '.\+' "${PRODUCT_NAME}";
    _check_value 'CONFIGPROFILE_DISPLAY_ORGANIZATION' '.\+' 'Unknown';
    _check_value 'CONFIGPROFILE_DISPLAY_DESC' '.\+' \
        'Install this profile to setup {email}';
    _check_value 'CONFIGPROFILE_ACCOUNT_DESC' '.\+' '{email}';


    # === IMAP ===
    _check_value 'IMAP_PROCESSES' '[[:digit:]]\+$' '2';
    _check_value 'IMAP_RETENTION' '[[:digit:]]\+$' '4';
    export _IMAP_DISABLE_STARTTLS='true';
    export _IMAP_PORT=143;
    if [ "${_USE_SSL}" = 'true' ]; then
        export _IMAP_PORT=993;
        if [ "${ENABLE_STARTTLS}" = 'true' ]; then
            export _IMAP_DISABLE_STARTTLS='false';
        fi
    fi


    # === Outbound SMTP ===
    export _OUTBOUND_SMTP_PORT=587;
    export _OUTBOUND_SMTP_SECRET="$(_get_random_string)";
    export _OUTBOUND_SMTP_ALLOW_FUTURE_DATE='true';
    [ "${_USE_SSL}" = 'true' ] && export _OUTBOUND_SMTP_PORT=465;
    [ "${ENABLE_SMTP_SEND_LATER}" = 'false' ] && export _OUTBOUND_SMTP_ALLOW_FUTURE_DATE='true';


    # === Misc ===
    export _COCOF_ADD='{"op": "add", "path": "%s", "value": %s}';
    export _TOTP_SECRET="$(_get_random_string)";
    export _SRS_SECRET="$(_get_random_string)";
    export _DKIM_SECRET="$(_get_random_string)";
    export _SMTP_PORT='587';
    [ "${_USE_SSL}" = 'true' ] && export SMTP_PORT='465';

    _persist_secret_variables;
}
