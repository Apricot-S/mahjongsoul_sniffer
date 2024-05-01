#!/usr/bin/env bash

set -euo pipefail

set -x

# `api-visualizer/sniffer.py` を addon として mitmproxy を起動する．
mitmdump -qs api-visualizer/sniffer.py &

set +x

# mitmproxy の証明書が作成されるまで待つ
while [[ ! -f ~/.mitmproxy/mitmproxy-ca-cert.pem ]]; do sleep 1; done

set -x

# 一度 mitmproxy を起動すると `~/.mitmproxy` ディレクトリが作成されるので，
# そこに作成される mitmproxy の証明書を Web server が読める場所にコピーする．
openssl x509 -in ~/.mitmproxy/mitmproxy-ca-cert.pem -inform PEM \
        -out api-visualizer/web-server/vue/dist/mitmproxy-ca-cert.crt

# Web server を起動する．
flask run --host=0.0.0.0
