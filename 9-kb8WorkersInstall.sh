#! /bin/bash

gcloud compute ssh worker-0 -- 'bash -s $4' < kb8WorkersInstaller.sh &
gcloud compute ssh worker-1 -- 'bash -s $4' < kb8WorkersInstaller.sh & 
gcloud compute ssh worker-2 -- 'bash -s $4' < kb8WorkersInstaller.sh &