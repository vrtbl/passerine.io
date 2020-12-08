#!/bin/sh

main() {
    clear
    need_cmd mktemp
    need_cmd mv
    need_cmd rm

    printf "\n"

    need_explain "git" "Git" "https://git-scm.com/downloads" || return 1
    need_explain "cargo" "Cargo and the Rust Toolchain" "https://www.rust-lang.org/tools/install" || return 1

    export ASPEN_HOME=${ASPEN_HOME:-$HOME/.aspen}
    ASPEN_BIN=${ASPEN_BIN:-$ASPEN_HOME/bin}
    ASPEN_REGISTRY=${ASPEN_BIN:-$ASPEN_HOME/registry}

    printf "    Welcome to Passerine!\n\n"

    printf "This script will download and install the official compiler and\n"
    printf "interpreter for the Passerine programming language, and its package\n"
    printf "manager and CLI, Aspen.\n\n"

    printf "The Aspen home, registry, and bin directories are:\n\n"
    printf "    ${ASPEN_HOME}\n"
    printf "    ${ASPEN_HOME}/registry\n"
    printf "    ${ASPEN_HOME}/bin\n\n"
    printf "This can be modified with the ASPEN_HOME environment variable.\n\n"

    profiles=$(ls -a $HOME | grep -x '\..*profile')
    if [ -z "$profiles" ]; then
        profiles=".profile"
    fi

    printf "The bin directory will then be added to your PATH environment\n"
    printf "variable by modifying the the profile files located at:\n\n"
    for profile in $profiles
    do
        printf "    $HOME/$profile\n"
    done
    printf "\n"

    # TODO: implement aspen uninstall
    # printf "You can uninstall Passerine at any time with the command\n"
    # printf "\'aspen uninstall\' and these changes will be reverted.\n\n"

    printf "Would you like to proceed with the installation? (y/N)\n\n"
    read -p ">   " -n 1 -r
    printf "\n\n"
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        printf "Installation aborted.\n\n"
        return 1
    fi

    printf "Proceeding with installation:\n\n"

    tmpaspen=$(mktemp -d 2>/dev/null || mktemp -d -t 'tmpaspen')
    download "Passerine" "passerine" || return 1
    download "Aspen" "aspen" || return 1

    printf "    Creating Aspen home... "
    mkdir -p $ASPEN_HOME || return 1
    mkdir -p $ASPEN_BIN || return 1
    mkdir -p $ASPEN_REGISTRY || return 1
    mv -f "$tmpaspen/passerine" "$tmpaspen/aspen" $ASPEN_HOME >/dev/null 2>&1
    rm -rf $tmpaspen
    printf "Done!\n"

    update "Passerine" "passerine" || return 1
    update "Aspen" "aspen" || return 1
    printf "\n"

    printf "Updating PATH:\n\n"

    for profile in $profiles
    do
        added=$(grep "$ASPEN_BIN" "$HOME/$profile")
        if [ ! -z "$added" ]; then
            printf "    \$ASPEN_BIN is already exported in $profile.\n"
        else
            printf "    Updating $profile... "
            printf "\n# Automatically added by Aspen\n" >> "$HOME/$profile"
            printf "export PATH=\"$ASPEN_BIN:\$PATH\"\n\n" >> "$HOME/$profile"
            printf "Done!\n"
        fi
    done
    printf "\n"

    printf "Installing the Aspen binary. This may take a minute:\n\n"
    build "Aspen" "aspen" "aspen" || return 1
    printf "\n"

    printf "Hooray! Passerine and Aspen have been installed. To create and run\n"
    printf "your first Passerine project, restart your shell, then run:\n\n"
    printf "    aspen new hello\n"
    printf "    cd hello\n"
    printf "    aspen run\n\n"

    printf "Get involved! Here are some things you can do:\n\n"
    printf "    Checkout Passerine on GitHub: https://github.com/vrtbl\n"
    printf "    Join the community Discord server: https://discord.gg/VEAtSZb\n"
    printf "    Read the compiler documentation: https://docs.rs/passerine\n\n"
    printf "Thanks and have a nice day!\n\n"
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

need_cmd() {
    if ! check_cmd "$1"; then
        err "Need '$1' (command not found)"
    fi
}

need_explain() {
    if ! check_cmd "$1"; then
        printf "It appears you don't have '$1' installed. You can install\n"
        printf "$2 by following the instructions here:\n\n"
        printf "    $3\n\n"
        printf "In the future, we plan to just distribute Aspen's binaries,\n"
        printf "but due to the current experimental nature of the project, build\n"
        printf "tools are needed.\n\n"

        err "Need '$1' (command not found)"
    fi
}

download() {
    printf "    Downloading $1... "
    git clone -q "https://github.com/vrtbl/$2" "$tmpaspen/$2" || return 1
    printf "Done!\n"
}

update() {
    printf "    Updating $1... "
    git --work-tree="$ASPEN_HOME/$2" --git-dir="$ASPEN_HOME/$2/.git" pull -ff -q origin master || return 1
    printf "Done!\n"
}

build() {
    printf "    Building $1...\n\n"
    cargo build --manifest-path "$ASPEN_HOME/$2/Cargo.toml" --release --color never || return 1
    printf "\n"

    printf "    Installing $1... "
    mv -f "$ASPEN_HOME/aspen/target/release/$3" "$ASPEN_BIN/$2" || return 1
    printf "Done!\n"
}

main || exit 1
