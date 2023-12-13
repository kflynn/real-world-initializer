# Make sure that we have what we need in our $PATH.

set -e

check () {
    cmd="$1"
    url="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing: $cmd (see $url)" >&2
        exit 1
    fi
}

check linkerd "https://linkerd.io/2/getting-started/"
check kubectl "https://kubernetes.io/docs/tasks/tools/"
