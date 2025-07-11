import models.io.upbound.azure.dbformysql.v1beta2 as dbformysqlv1beta2
import models.io.upbound.azure.dbformysql.v1beta1 as dbformysqlv1beta1
import models.io.upbound.azure.network.v1beta2 as networkv1beta2
import models.io.upbound.azure.network.v1beta1 as networkv1beta1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

import base64

schema DefaultSpec:
    deletionPolicy: str
    providerConfigRef: {str:str}
    forProvider: {str:str}

oxr = platformazurev1alpha1.XSQLInstance {**option("params").oxr}
ocds = option("params").ocds # observed composed resources

_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

# spec defaults
_defaultSpec = DefaultSpec {
    deletionPolicy = oxr.spec.parameters.deletionPolicy or "Delete"
    providerConfigRef = {
        name = oxr.spec.parameters.providerConfigName or "default"
    }
    forProvider = {}
}

assert 20 <= oxr.spec.parameters.storageGB <= 16384, "storageGB supported values for MySQL FlexibleServer are between 20 and 16384"

_items = [
    networkv1beta2.PrivateDNSZone {
        metadata = {
            **_metadata("privatednszone")
            name = "{}-mysql".format(oxr.spec.parameters.networkRef.id)
            annotations = {
                "crossplane.io/external-name" = "{}.mysql.database.azure.com".format(oxr.spec.parameters.networkRef.id)
            }
            labels = {
                "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
            }
        }
        spec = {
            **_defaultSpec
            forProvider = {
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
        }
    }
    networkv1beta1.PrivateDNSZoneVirtualNetworkLink {
        metadata = {
            **_metadata("privatednszonevnetlink")
            name = "{}-mysql".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                privateDnsZoneNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                virtualNetworkIdSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
        }
    }
    dbformysqlv1beta2.FlexibleServer {
        metadata = {
            **_metadata("mysqlserver")
            name = "{}-mysql".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                administratorLogin = "mysqladmin"
                skuName = "GP_Standard_D2ds_v4"
                location = oxr.spec.parameters.region
                administratorPasswordSecretRef = {
                    key = oxr.spec.parameters.passwordSecretRef.key
                    name = oxr.spec.parameters.passwordSecretRef.name
                    namespace = oxr.spec.parameters.passwordSecretRef.namespace
                }
                backupRetentionDays = 7
                storage.sizeGb = oxr.spec.parameters.storageGB
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                delegatedSubnetIdSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                        "azure.platform.upbound.io/subnet-service-type" = "mysql"
                    }
                }
                privateDnsZoneIdSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
            writeConnectionSecretToRef = {
                namespace = oxr.spec.writeConnectionSecretToRef.namespace
                name = "{}-mysql".format(oxr.metadata.uid)
            }
        }
    }

    dbformysqlv1beta1.FlexibleDatabase {
        metadata = {
            **_metadata("database")
            name = "upbound"
        }
        spec = {
            **_defaultSpec
            forProvider = {
                charset = "utf8mb4"
                collation = "utf8mb4_unicode_ci"
                serverNameSelector = {
                    matchControllerRef = True
                }
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
        }
    }
    {
        apiVersion: "meta.krm.kcl.dev/v1alpha1"
        kind: "CompositeConnectionDetails"
        if "mysqlserver" in ocds:
            data: {
                username = base64.encode(ocds["mysqlserver"].Resource?.spec?.forProvider?.administratorLogin)
                password = ocds["mysqlserver"].ConnectionDetails["attribute.administrator_password"]
                host = base64.encode(ocds["mysqlserver"].Resource?.status?.atProvider?.fqdn)
            }
        else:
            data: {}
    }
]

items = _items
