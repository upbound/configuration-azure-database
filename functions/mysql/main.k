import models.io.upbound.azurem.dbformysql.v1beta1 as dbformysqlv1beta1
import models.io.upbound.azurem.network.v1beta1 as networkv1beta1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1
import models.io.k8s.api.core.v1 as corev1

import base64

schema DefaultSpec:
    managementPolicies: [str]
    providerConfigRef: {str:str}
    forProvider: {str:str}

oxr = platformazurev1alpha1.SQLInstance {**option("params").oxr}
ocds = option("params").ocds # observed composed resources

_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

# spec defaults
_defaultSpec = DefaultSpec {
    managementPolicies = oxr.spec.parameters.managementPolicies or ["*"]
    providerConfigRef = {
        kind = "ProviderConfig"
        name = oxr.spec.parameters.providerConfigName or "default"
    }
    forProvider = {}
}

assert 20 <= oxr.spec.parameters.storageGB <= 16384, "storageGB supported values for MySQL FlexibleServer are between 20 and 16384"

_items = [
    networkv1beta1.PrivateDNSZone {
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
    dbformysqlv1beta1.FlexibleServer {
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
    corev1.Secret {
        metadata = {
            name = oxr.spec?.writeConnectionSecretToRef?.name
            namespace = oxr.metadata.namespace
            annotations = {
                "krm.kcl.dev/composition-resource-name" = "connection-secret"
                if "mysqlserver" in ocds:
                    "krm.kcl.dev/ready" = "True"
            }
        }
        if "mysqlserver" in ocds:
            data = {
                username = base64.encode(ocds["mysqlserver"].Resource?.spec?.forProvider?.administratorLogin)
                password = ocds["mysqlserver"].ConnectionDetails["attribute.administrator_password"]
                host = base64.encode(ocds["mysqlserver"].Resource?.status?.atProvider?.fqdn)
                port = base64.encode("3306")
            }
    }
]

items = _items
