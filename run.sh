#!/bin/bash

docker run -h ca -it \
        --rm \
        --name ca \
        --env CA_DEFAULT_countryName="PL" \
        --env CA_DEFAULT_stateOrProvinceName="Pomorskie" \
        --env CA_DEFAULT_localityName="Gdańsk" \
        --env CA_DEFAULT_organizationName="GardenSoft S.A." \
        --env CA_DEFAULT_organizationalUnitName="PRK" \
        --env CA_DEFAULT_commonName="GardenSoft  S.A PRK (%s) CA" \
        --env CA_DEFAULT_emailAddress="jaroslaw.ogrodnik@wp.pl" \
        --volume $(pwd)/ca:/home/ca \
        --volume $(pwd)/assets/conf:/etc/docker-ca \
        my/ca

: