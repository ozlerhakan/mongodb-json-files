#!/usr/bin/env bash

# Default parameters value
DOCKER=0
SMALL=0
URI=mongodb://localhost

usage() {
    echo "Usage: ./import.sh [-h|-help] [-d|--docker] [-s|--small] [-u URI|-u=URI|--uri URI|--uri=URI]"
    echo
    echo "OPTIONS:"
    echo -e "  -d, --docker\t starts a MongoDB docker container on port 27017 with --rm option."
    echo -e "  -s, --small\t only imports the smallest datasets for a fast loading."
    echo -e "  -u, --uri\t MongoDB Cluster URI. Can contain user:password if --auth is activated."
    echo -e "\t\t Compatible with \"mongodb://\" and \"mongodb://srv\" connection strings."
    echo -e "  -h, --help\t prints the help."
    echo
    echo "EXAMPLES:"
    echo "  ./import.sh"
    echo "  ./import.sh -h"
    echo "  ./import.sh --help"
    echo "  ./import.sh --docker"
    echo "  ./import.sh --small"
    echo "  ./import.sh -s"
    echo "  ./import.sh -d"
    echo "  ./import.sh -u=mongodb+srv://user:password@freecluster-abcde.mongodb.net"
    echo "  ./import.sh --docker --small --uri mongodb://127.0.0.1"
    echo "  ./import.sh -d -s --uri mongodb://127.0.0.1"
    echo "  ./import.sh -d -s --uri=mongodb://127.0.0.1"
    echo "  ./import.sh -ds --uri mongodb://127.0.0.1"
    echo "  ./import.sh -ds -u mongodb://127.0.0.1"
    echo "  ./import.sh -ds -u=mongodb://127.0.0.1"
    echo "  ./import.sh -dsu mongodb://127.0.0.1"
    echo "  ./import.sh -dsu=mongodb://127.0.0.1"
    echo "  ./import.sh -sd --uri mongodb://127.0.0.1"
    echo "  ./import.sh -sd -u mongodb://127.0.0.1"
    echo "  ./import.sh -sd -u=mongodb://127.0.0.1"
    echo "  ./import.sh -sdu mongodb://127.0.0.1"
    echo "  ./import.sh -sdu=mongodb://127.0.0.1"
    exit 1
}

echo_error() {
    echo -e "\033[0;31m$1\033[0m"
}

argument_parsing() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                usage
                exit 0
            ;;
            -d | --docker)
                DOCKER=1
            ;;
            -s | --small)
                SMALL=1
            ;;
            -ds | -sd)
                DOCKER=1
                SMALL=1
            ;;
            -u | --uri)
                shift
                URI="$1"
            ;;
            -dsu | -sdu)
                shift
                DOCKER=1
                SMALL=1
                URI="$1"
            ;;
            -u=* | --uri=*)
                URI="${1#*=}"
            ;;
            -dsu=* | -sdu=*)
                DOCKER=1
                SMALL=1
                URI="${1#*=}"
            ;;
            *)
                echo_error "Unknown option '$1'"
                usage
            ;;
        esac
        shift
    done
}

start_mongodb_docker() {
    if [[ ${DOCKER} -eq 1 ]]; then
        echo "Starting MongoDB in Docker on port 27017..."
        docker run --rm -d -p 27017:27017 --name mongo mongo:latest
        sleep 3
        echo "Done."
    fi
}

import_small_datasets() {
    cd datasets

    unzip tweets.zip
    mongorestore --drop --uri ${URI}
    rm -rf dump

    wget -qO- http://media.mongodb.org/zips.json | mongoimport --drop -c zips --uri ${URI}/samples

    unzip palbum.zip
    mongoimport --drop -c images --uri ${URI}/sample-pictures palbum/images.json
    mongoimport --drop -c albums --uri ${URI}/sample-pictures palbum/albums.json
    rm -rf palbum

    mongoimport --drop -c grades --uri ${URI}/sample-school grades.json
    mongoimport --drop -c students --uri ${URI}/sample-school students.json
    mongoimport --drop -c profiles --uri ${URI}/samples profiles.json
    mongoimport --drop -c products --uri ${URI}/samples products.json
    mongoimport --drop -c countries-small --uri ${URI}/samples countries-small.json
    mongoimport --drop -c countries-big --uri ${URI}/samples countries-big.json
    mongoimport --drop -c restaurants --uri ${URI}/samples restaurant.json
    mongoimport --drop -c covers --uri ${URI}/sample-library covers.json
    mongoimport --drop -c books --uri ${URI}/sample-library books.json

    cd ..
}

import_big_datasets() {
    if [[ ${SMALL} -eq 0 ]]; then
        cd datasets

        unzip people-bson.zip -d dump
        mongorestore --gzip --drop --uri ${URI}
        rm -rf dump

        mongoimport --drop -c city_inspections --uri ${URI}/samples city_inspections.json
        mongoimport --drop -c companies --uri ${URI}/samples companies.json

        wget https://dl.dropbox.com/s/p75zp1karqg6nnn/stocks.zip
        unzip stocks.zip
        mongorestore --drop --uri ${URI}
        rm -rf dump stocks.zip

        wget -qO- https://dl.dropbox.com/s/gxbsj271j5pevec/trades.json | mongoimport --drop -c trades --uri ${URI}/samples

        wget https://dl.dropbox.com/s/nfnvx6pggmvw5vt/enron.zip
        unrar x enron.zip
        mongorestore --drop --uri ${URI}
        rm -rf dump enron.zip

        cd ..
    fi
}

argument_parsing $@
start_mongodb_docker
import_small_datasets
import_big_datasets
