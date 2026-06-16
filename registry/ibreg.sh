# Island Bitcoin registry shell helpers.
#
# Source this from your shell rc so it survives restarts. e.g. add to ~/.zshrc:
#   source ~/Documents/Start9/Repos/atoll/registry/ibreg.sh
#
# Provides:
#   $REG, $HOST       registry URL + signing-context hostname (the LAN name in registry-hostname)
#   ibreg <args...>   start-cli against the registry — e.g.  ibreg registry package index
#   CAT <args...>     registry package category — e.g.  CAT list   |   CAT add-package ai maple-proxy
#
# Override the defaults by exporting REG / HOST before sourcing.
# Works in bash and zsh. Must run on a machine on the registry's LAN with the
# registered developer key (see registry/README.md).

export REG="${REG:-https://start9.bobodread.com}"
export HOST="${HOST:-embassy-5004a3db.local}"

ibreg() { start-cli --registry-hostname "$HOST" -r "$REG" "$@"; }
CAT()   { ibreg registry package category "$@"; }
