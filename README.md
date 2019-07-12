# coSNPs version 1.1

## Introduction:

coSNPs is a software that can detect the coexistence of multiple SNPs in each single SMRT long read with higher accuracy using local realignment. 

By assigning the positions and their mutated nucleotides, coSNPs can realign the reads to the original and mutated version of referential sequence and determine the nucleotide of the position of interest. The realignment part is done by [blasr](https://github.com/PacificBiosciences/blasr), a software dedicates to align SMRT sequencing data to the referencial genome.

## Install coSNPs:

We recommend running the analysis within docker container:

1. Install [docker](https://docs.docker.com/)

2. Download the GitHub repository

   ```bash
   mkdir -p ~/Documents/GitHub
   cd ~/Documents/GitHub
   git clone https://github.com/zhliUU/Applied_Bioinformatics_Xdrop.git
   # Change the directory to the downloaded git folder
   cd ./Applied_Bioinformatics_Xdrop
   ```

3. Build docker image and start container:

   ```bash
   # Inside the Docker folder
   cd Docker
   # Build an image called "cosnps_image" defined in ./Dockerfile, don't forget the "." in the end
   ## To customize the docker image (different PATH, pre-installed software version), edit th Dockerfile
   docker build --tag=cosnps_image .
   # Start a container called "cosnps_container" in background (-d)
   ## Container's folder: "/home/Connected" will be connected to local folder: "~/Documents/GitHub", 
   ## Move the input data to the GitHub folder to share the data between local environment and the docker container environment
   ## "docker run" can be considered as starting a new container 
   sudo docker run -d \
   -v ~/Documents/GitHub:/home/Connected --name cosnps_container \
   -it cosnps_image
   # Execute an interactive bash shell on the container
   sudo docker exec -i -t cosnps_container /bin/bash
   # In the interactive bash shell, run coSNPs help function
   coSNPs_main.sh -h
   ```

## Run coSNPs

coSNPs require 3 inputs, the notation of the chromosome should be consistent (only chrX or only X):

1. Reads mapped to a referenced genome and saved as **BAM** format

2. Input **mutations positions** and **alternative genotype**, example:

   ```bash
   #cat /home/Connected/Applied_Bioinformatics_Xdrop/Testing/input2POS_test.txt
   chr17:7578263	A
   chr17:7579312	T
   ```

3. [Reference genome](https://github.com/zhliUU/Applied_Bioinformatics_Xdrop/tree/Deliverable/RefGenome), come with both hg19 and hg38 in the RefGenome folder

#### Example run with given testing data:

***the order of the 3 input files should be: 1.BAM 2.Positions 3.ReferenceGenome**

```bash
# Run with testing data in the repository
cd /home/Connected/Applied_Bioinformatics_Xdrop/Testing
# Run coSNPs with given demo data, the input should be in the following order: BAM, Positions, Ref_genome
coSNPs_main.sh chr17.bam input2POS_test.txt ../RefGenome/ref_hg19_chr17.fasta -g
```

#### Example run results:

1. resultT1.txt: alignment results (number of mapped bp) at each position for each read that cover all mutated positions.
2. resultT2.txt: summary of the number of read and frequency of different genotype, where 0 stands for referential and 1 stands for mutated nucleotide.
3. (resultT3.txt): same as resultT2.txt but provide header, only given when the run with `-g` tag.
4. General results printed in the terminal:

```bash
Number of long reads input:
3360
Number of selected long reads:
81
Number of reads containing all Pos and pass the numMatch threshold:
65 resultT1.txt
Number of reads left for summarizing:
53
Summary:
If return an error, make sure the python libraries installed to the python version list below!
2.7.16 |Anaconda, Inc.| (default, Mar 14 2019, 21:00:58) 
[GCC 7.3.0]
  ID    Count    Frequency  chr17:7578263,chr17:7579312
----  -------  -----------  -----------------------------
   1        1    0.0188679  0		0
   2       19    0.358491   0		1
   3       32    0.603774   1		0
   4        1    0.0188679  1		1
```

## Parameters, customise

```bash
-h|--help  help function
-g|--graphic  print better table using python:tabulate library, graphical output(future development)
-w|--window [int] set the half window size of the sequences for realignment, default value is 50 bp
-f|--filter [0-1] set the threshold of misaligned percentage for removing bad alignments, default value 0.8
-o|--output prefix the output

Default: Run script with default window size 50bp (length 101bp) and filter Threshold 0.8
```

## Exit, kill and remove docker container

The docker container will be running in the background, and user are not allowed to start a new container with the same name as an old existing one, even though the the old container is not up and running.

```bash
# To exit the interactie bash shell, the container will still run in the background
exit

# In the local environment
###Managing docker containers###
# To check the running docker container
docker ps
# To check all containers
docker container ls -a
# To kill the container running in the background:
docker container kill cosnps_container
# To remove the container before 
docker rm cosnps_container

###Managing docker images###
# To check all images
docker images
# To remove the docker image to release storage or before rebuilding the image
docker image rm cosnps_image
```

## Install coSNPs locally:

To run coSNPs without docker, make sure the correct softwares and packages are installed, and add the main folder in the PATH

#### softwares:

| Software | Version | Build       |
| -------- | ------- | ----------- |
| bedtools | 2.28.0  | hdf88d34_0  |
| samtools | 1.9     | h8571acd_11 |
| blasr    | 5.3.3   | h707fff8_0  |
| Python   | 2.7.16  |             |

#### Python Packages:

Python 2.7.16 :: Anaconda, Inc.

| Python packages | Version | Build          |
| --------------- | ------- | -------------- |
| numpy           | 1.16.4  | py27h7e9f1db_0 |
| tabulate        | 0.8.3   | py_0           |
| sys             | default | default        |

#### 