function _artisan_subcommands() {
    if [ ! -f artisan ]; then
        return
    fi

    php artisan list --raw | sed 's/:/\\\:/' | sed 's/[[:space:]]\+/:/'
}

function _artisan_options() {
    if [ ! -f artisan ]; then
        return
    fi

    php artisan help $1 --format=json | jq -r \
        'def spl(f): f | split("|"); def mat(f): f | (if test("\\(") then (match("\\((.*)\\)") | .captures[0].string | [ splits(", |\\s*or\\s*") ] | map(select(. != "")) | ":msg:(" + join(" ") + ")") else "" end); .definition.options[] | {name: spl(.name), desc: .description, value: .accept_value}, {name: spl(.shortcut), desc: .description, value: .accept_value} | {name: .name[], desc: .desc, value: .value } | select(.name != "") | .name + (if .value then "=" else "" end) + "[" + .desc + "]" + mat(.desc)'
}

function _artisan_has_subcommand() {
    local _artisan_list_raw

    if ! _retrieve_cache $(_artisan_generate_cache_id_by_filepath_and_key artisan list_raw); then
        _artisan_list_raw=$(php artisan list --raw)

        _artisan_store_cache list_raw _artisan_list_raw
    fi

    if echo $_artisan_list_raw | awk '{print $1}' | grep -q "^\\(${*// /\\|}\\)$"; then
        return 0
    fi

    return 1
}

function _artisan_store_cache() {
    local key=$1
    local data=$2

    _store_cache $(_artisan_generate_cache_id_by_filepath_and_key artisan $key) $data
}

function _artisan_generate_cache_id_by_filepath_and_key() {
    local filepath=$1
    local key=$2

    echo "artisan-$(_artisan_hash_filepath $(readlink -f $filepath))-$key"
}

function _artisan_hash_filepath() {
    echo $1 | openssl dgst -md5 | awk '{ print $2 }'
}

function _artisan() {
    local state context line
    local -a _artisan_subcommands
    local -a _artisan_options
    local -a _artisan_subcommand_options

    _arguments '*:subcommand:->subcommand'

    if [[ "$state" == "subcommand" && "$words[2]" == "artisan" ]]; then
        if ! _retrieve_cache $(_artisan_generate_cache_id_by_filepath_and_key artisan subcommands); then
            local IFS=$'\n'
            _artisan_subcommands=($(_artisan_subcommands))

            _artisan_store_cache subcommands _artisan_subcommands
        fi

        if ! _retrieve_cache $(_artisan_generate_cache_id_by_filepath_and_key artisan common_options); then
            local IFS=$'\n'
            _artisan_options=($(_artisan_options))

            _artisan_store_cache common_options _artisan_options
        fi

        # ignore current word
        if [[ $words[-1] == '' ]]; then
            last_index='-1'
        else
            last_index='-2'
        fi

        if _artisan_has_subcommand $words[3,$last_index]; then
            if ! _retrieve_cache $(_artisan_generate_cache_id_by_filepath_and_key artisan subcommand_${words[3]}_options); then
                local IFS=$'\n'
                _artisan_subcommand_options=($(_artisan_options $words[3]))

                _artisan_store_cache subcommand_${words[3]}_options _artisan_subcommand_options
            fi

            _arguments -s : \
                $_artisan_subcommand_options[@] \
                '*:Sub command Options:()' # XXX なんでこれないと駄目なの？
        else
            _arguments -s : \
                $_artisan_options[@] \
                '*:Sub commands:(($_artisan_subcommands))'
        fi
    else
        _php
    fi
}