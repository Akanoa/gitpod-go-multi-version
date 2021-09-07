FROM buildpack-deps:focal-scm

RUN apt update && apt install -y sudo make git-lfs gcc bison binutils && apt clean 

### Gitpod user ###
# '-l': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
ENV HOME=/home/gitpod
WORKDIR $HOME
# custom Bash prompt
RUN { echo && echo "PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\") $ '" ; } >> .bashrc

USER gitpod

ENV GO_VERSION=1.17
ENV GOPATH=$HOME/go-packages
ENV GOROOT=$HOME/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH
RUN curl -fsSL https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar xzs && \
# install VS Code Go tools for use with gopls as per https://github.com/golang/vscode-go/blob/master/docs/tools.md
# also https://github.com/golang/vscode-go/blob/27bbf42a1523cadb19fad21e0f9d7c316b625684/src/goTools.ts#L139
    go get -v \
        github.com/uudashr/gopkgs/cmd/gopkgs@v2 \
        github.com/ramya-rao-a/go-outline \
        github.com/cweill/gotests/gotests \
        github.com/fatih/gomodifytags \
        github.com/josharian/impl \
        github.com/haya14busa/goplay/cmd/goplay \
        github.com/go-delve/delve/cmd/dlv \
        github.com/golangci/golangci-lint/cmd/golangci-lint && \
    GO111MODULE=on go get -v \
        golang.org/x/tools/gopls@v0.7.1 && \
    sudo rm -rf $GOPATH/src $GOPATH/pkg /home/gitpod/.cache/go /home/gitpod/.cache/go-build
# user Go packages
ENV GOPATH=/workspace/go
ENV PATH=/workspace/go/bin:$PATH


### Gitpod user (2) ###
#USER gitpod
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for Gitpod: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls \$HOME/.bashrc.d/*); do source \$i; done"; echo) >> /home/gitpod/.bashrc && \
    (echo; echo "source $HOME/.gvm/scripts/gvm"; echo) >> /home/gitpod/.bashrc 

RUN echo "export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /home/gitpod/.bashrc.d/setenv.sh
RUN curl -L https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh > /home/gitpod/.bashrc.d/bash_git.sh

RUN ["bash", "-c", "bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)"]

# configure git-lfs
RUN sudo git lfs install --system