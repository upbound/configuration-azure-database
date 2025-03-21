# Azure Database Configuration

This repository contains an Upbound project, tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed Azure database instances.

## Overview

The core components of a custom API in [Upbound Project](https://docs.upbound.io/learn/control-plane-project/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Configures the Functions Pipeline
- **Embedded Function(s):** Encapsulates the Composition logic and implementation within a self-contained, reusable unit

In this specific configuration, the API contains:

- **an [Azure Database](/apis/xsqlinstances/definition.yaml) custom resource type.**
- **Compositions:** Configured in [/apis/xsqlinstances/composition_postgres.yaml](/apis/xsqlinstances/composition_postgres.yaml) and [/apis/xsqlinstances/composition_mariadb.yaml](/apis/xsqlinstances/composition_mariadb.yaml)
- **Embedded Functions:** The Composition logic is encapsulated within [PostgreSQL function](/functions/postgres/main.k) and [MariaDB function](/functions/mariadb/main.k)

## Testing

The configuration can be tested using:

- `up composition render --xrd=apis/xsqlinstances/definition.yaml apis/xsqlinstances/composition_postgres.yaml examples/sqlinstance/postgres.yaml` to render the PostgreSQL composition
- `up composition render --xrd=apis/xsqlinstances/definition.yaml apis/xsqlinstances/composition_mariadb.yaml examples/sqlinstance/mariadb.yaml` to render the MariaDB composition
- `up test run tests/*` to run composition tests in `tests/test-postgres/` and `tests/test-mariadb/`
- `up test run tests/* --e2e` to run end-to-end tests in `tests/e2etest-dbs/`

## Deployment

- Execute `up project run`
- Alternatively, install the Configuration from the [Upbound Marketplace](https://marketplace.upbound.io/configurations/upbound/configuration-azure-database)
- Check [examples](/examples/) for example XR(Composite Resource)

## Next steps

This repository serves as a foundational step. To enhance the configuration, consider:

1. create new API definitions in this same repo
2. editing the existing API definition to your needs

To learn more about how to build APIs for your managed control planes in Upbound, read the guide on [Upbound's docs](https://docs.upbound.io/).