# docker build --tag coraza-benchmark:latest --pull .
# docker run --rm -v $(pwd)/tests:/opt/coraza-benchmark/tests -v $(pwd)/waf.rules:/opt/coraza-benchmark/waf.rules coraza-benchmark:latest -rules=/opt/coraza-benchmark/waf.rules

FROM archlinux/archlinux:base-devel AS builder

ARG user=makepkg

RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user

USER $user
WORKDIR /home/$user

RUN sudo pacman -Syu --needed --noconfirm \
    git

RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm \
  && cd \
  && rm -rf .cache yay

RUN yay -S --noconfirm \
    go \
    libinjection-git \
    libmodsecurity \
    pcre \
    pcre2 \
    python3

RUN git clone https://github.com/corazawaf/coraza-benchmark.git \
  && cd coraza-benchmark \
  && go build -o coraza-benchmark \
  && sudo mkdir -p /opt/coraza-benchmark \
  && sudo mv coraza-benchmark /opt/coraza-benchmark/ \
  && sudo chmod -R 0777 /opt/coraza-benchmark \
  && cd /home/$user \
  && rm -rf coraza-benchmark

RUN yay -Scc --noconfirm

USER root
RUN userdel -r $user \
  && rm -f /etc/sudoers.d/$user

FROM archlinux/archlinux:base-devel

COPY --from=builder . .

WORKDIR /opt/coraza-benchmark
ENTRYPOINT ["/opt/coraza-benchmark/coraza-benchmark"]
