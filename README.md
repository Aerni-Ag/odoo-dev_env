# Installing Odoo 17.0 Enterprise local

## Quick Installation

Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) 

run to create folder struktur

``` bash
docker-compose build
```

Copy dump.sql from your dumped datebase to `db_data/` 

Copy everything from your dumped `filestore` to `etc/filestore/odoo/`

Clone/Copy https://github.com/odoo/enterprise/tree/17.0 into `enterprise-17.0`

Clone custom Addon Repositories into `etc/addons`

run

``` bash
docker-compose up -d
```

odoo should be available at

`localhost:10017`