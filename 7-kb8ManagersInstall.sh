#! /bin/bash

gcloud compute ssh controller-0 -- 'bash -s $4' < kb8Installer.sh &
gcloud compute ssh controller-1 -- 'bash -s $4' < kb8Installer.sh & 
gcloud compute ssh controller-2 -- 'bash -s $4' < kb8Installer.sh &