# artisan-completion

laravel artisan completion for zsh

can complete subcommands, common options, subcommand options, some option values.

## Installations

Using zplug

```zsh
# before zplug load
zplug "stedolan/jq", \
    from:gh-r, \
    as:command, \
    rename-to:jq

zplug "magai/artisan-completion", \
    on:"stedolan/jq"

# ...

# after compinit
compdef -d php
compdef _artisan php
zstyle ':completion::*:php:*' use-cache true
```

## Dependencies

* jq
* openssl

## License

GPLv3
