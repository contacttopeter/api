#!/bin/bash
cd ~
sa=$(whoami)
rm -rf actions-runner
mkdir actions-runner && cd actions-runner
curl -s https://api.github.com/repos/actions/runner/releases/latest | grep "browser_download_url.*actions-runner-linux-x64" | cut -d : -f 2,3 | tr -d \" | wget -qi -
tar xzf ./actions-runner-linux-x64*.tar.gz
response=$(curl -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token ${1}" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/orgs/contacttopeter/actions/runners/registration-token)
registration_token=$(jq -r '.token' <<< "$response")
./config.sh --url https://github.com/contacttopeter --token $registration_token --runnergroup api --replace --name `hostname` --labels api,${2},self-hosted,x64,Linux,${3} --unattended
sudo ./svc.sh install $sa
sudo ./svc.sh start
sudo ./svc.sh status
