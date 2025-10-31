# Dockerfile
ARG ODOO_VERSION=17.0-20251021
FROM odoo:${ODOO_VERSION}

# Verzeichnis für Enterprise-Addons im Image
ENV ODOO_ENTERPRISE_DIR=/mnt/odoo-enterprise-addons

USER root

# Installiere nur noch gosu (git, openssh-client etc. nicht mehr zwingend für Addon-Handling hier)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gosu \
        nano \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# --- Enterprise Addons (kopiert vom lokalen Host) ---
RUN mkdir -p ${ODOO_ENTERPRISE_DIR}
COPY ./enterprise-17.0 ${ODOO_ENTERPRISE_DIR}/
RUN chown -R odoo:odoo ${ODOO_ENTERPRISE_DIR}

# Die privaten Addons werden jetzt über den Volume-Mount ./addons:/mnt/extra-addons bereitgestellt

USER odoo