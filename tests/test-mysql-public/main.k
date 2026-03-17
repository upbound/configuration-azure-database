import models.io.upbound.azurem.dbformysql.v1beta1 as dbformysqlv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

# Contract test: validates that enabling publicNetworkAccess on SQLInstance renders
# a FlexibleServer with publicNetworkAccess=Enabled and the expected FirewallRule.
# The default firewall rule (0.0.0.0-0.0.0.0) allows Azure services to connect,
# enabling provider-sql to reach the MySQL FlexibleServer.

_NETWORK_ID = "configuration-azure-database"
_XR_NAME = "configuration-azure-database-db-mysql-public"

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "mysql-flexibleserver-public"
        spec = {
            assertResources: [
                platformazurev1alpha1.SQLInstance{
                    metadata = {
                        name = _XR_NAME
                        namespace = "default"
                    }
                    status = {
                        endpoint = "configuration-azure-database-mysql.mysql.database.azure.com"
                        port = "3306"
                    }
                    spec = {
                        crossplane.compositionSelector = {
                            matchLabels = {dbengine = "mysql"}
                        }
                        parameters = {
                            networkRef = {id = _NETWORK_ID}
                            passwordSecretRef = {key = "password", name = "psqlsecret"}
                            region = "westus"
                            storageGB = 20
                            version = "8.0"
                            publicNetworkAccess = "Enabled"
                            firewallRules = [
                                {name = "allow-azure-services", startIpAddress = "0.0.0.0", endIpAddress = "0.0.0.0"}
                            ]
                        }
                        writeConnectionSecretToRef = {
                            name = "{}-db-conn-mysql-public".format(_NETWORK_ID)
                        }
                    }
                }
                dbformysqlv1beta1.FlexibleServer {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "mysqlserver"
                        }
                        labels = {
                            "crossplane.io/composite" = _XR_NAME
                        }
                        name = "{}-mysql".format(_NETWORK_ID)
                    }
                    spec = {
                        forProvider = {
                            administratorLogin = "mysqladmin"
                            skuName = "GP_Standard_D2ds_v4"
                            location = "westus"
                            administratorPasswordSecretRef = {
                                key = "password"
                                name = "psqlsecret"
                            }
                            backupRetentionDays = 7
                            storage.sizeGb = 20
                            resourceGroupNameSelector = {
                                matchLabels = {"azure.platform.upbound.io/network-id" = _NETWORK_ID}
                            }
                            publicNetworkAccess = "Enabled"
                        }
                    }
                }
                dbformysqlv1beta1.FlexibleServerFirewallRule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "firewallrule-allow-azure-services"
                        }
                        name = "{}-mysql-allow-azure-services".format(_NETWORK_ID)
                    }
                    spec = {
                        forProvider = {
                            startIpAddress = "0.0.0.0"
                            endIpAddress = "0.0.0.0"
                            serverNameSelector = {
                                matchControllerRef = True
                            }
                            resourceGroupNameSelector = {
                                matchLabels = {"azure.platform.upbound.io/network-id" = _NETWORK_ID}
                            }
                        }
                    }
                }
                dbformysqlv1beta1.FlexibleDatabase {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "database"
                        }
                        labels = {
                            "crossplane.io/composite" = _XR_NAME
                        }
                        name = "upbound"
                    }
                    spec = {
                        forProvider = {
                            charset = "utf8mb4"
                            collation = "utf8mb4_unicode_ci"
                            resourceGroupNameSelector = {
                                matchLabels = {"azure.platform.upbound.io/network-id" = _NETWORK_ID}
                            }
                            serverNameSelector = {
                                matchControllerRef = True
                            }
                        }
                    }
                }
            ]
            observedResources = [
                dbformysqlv1beta1.FlexibleServer {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "mysqlserver"
                        }
                        name = "{}-mysql".format(_NETWORK_ID)
                    }
                    spec.forProvider.location = "westus"
                    status.atProvider.fqdn = "configuration-azure-database-mysql.mysql.database.azure.com"
                }
            ]
            compositionPath: "apis/mysql/composition.yaml"
            xrPath: "examples/mysql-xr-public.yaml"
            xrdPath: "apis/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items = _items
