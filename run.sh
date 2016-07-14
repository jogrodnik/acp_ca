#!/bin/bash

docker run -h ca -it \
        --rm \
        --name ca \
        --env CA_DEFAULT_countryName="PL" \
        --env CA_DEFAULT_stateOrProvinceName="Pomorskie" \
        --env CA_DEFAULT_localityName="Gdynia" \
        --env CA_DEFAULT_organizationName="Asseco Poland S.A." \
        --env CA_DEFAULT_organizationalUnitName="PRK" \
        --env CA_DEFAULT_commonName="Asseco Poland S.A PRK (%s) CA" \
        --env CA_DEFAULT_emailAddress="jaroslaw.ogrodnik@asseco.pl" \
        --volume $(pwd)/ca:/home/ca \
        --volume $(pwd)/assets/conf:/etc/docker-ca \
        my/ca

: