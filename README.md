# Installing Odoo 17.0 Enterprise local

## Quick Installation

Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) 

Copy dump.sql to initial_data/

Copy everything from in the `filestore` folder to etc/odoo/

Clone custom Addon Repository into etc/addons

run

``` bash
docker-compose up -d
```

odoo should be available at

`localhost:10017`