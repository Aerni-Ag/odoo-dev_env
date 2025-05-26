# Installing Odoo 17.0 Enterprise local

## Quick Installation

Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) 

run

``` bash
docker-compose build
```

to create folder struktur

Copy dump.sql to db_data/ 

Copy everything from in the `filestore` folder to etc/odoo/

Clone custom Addon Repositories into etc/addons

run

``` bash
docker-compose up -d
```

odoo should be available at

`localhost:10017`