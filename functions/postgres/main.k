import models.io.upbound.azure.dbforpostgresql.v1beta2 as dbforpostgresqlv1beta2
import models.io.upbound.azure.dbforpostgresql.v1beta1 as dbforpostgresqlv1beta1
import models.io.upbound.azure.network.v1beta2 as networkv1beta2
import models.io.upbound.azure.network.v1beta1 as networkv1beta1

import base64

oxr = option("params").oxr # observed composite resource
ocds = option("params").ocds # observed composed resources

schema DefaultSpec:
    deletionPolicy: str
    providerConfigRef: {str:str}
    forProvider: {str:str}

_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}

# spec defaults
_defaultSpec = DefaultSpec {
    deletionPolicy = oxr.spec.parameters.deletionPolicy or "Delete"
    providerConfigRef = {
        name = oxr.spec.parameters.providerConfigName or "default"
    }
    forProvider = {}
}

_items = [
    networkv1beta2.PrivateDNSZone {
        metadata = {
            **_metadata("privatednszone")
            name = "{}-postgresql".format(oxr.spec.parameters.networkRef.id)
            annotations = {
                "crossplane.io/external-name" = "{}.postgres.database.azure.com".format(oxr.spec.parameters.networkRef.id)
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
            name = "{}-postgresql".format(oxr.spec.parameters.networkRef.id)
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
    dbforpostgresqlv1beta2.FlexibleServer {
        metadata = {
            **_metadata("postgresqlserver")
            name = "{}-postgresql".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                administratorLogin = "psqladmin"
                autoGeneratePassword = True
                skuName = "GP_Standard_D4s_v3"
                location = oxr.spec.parameters.region
                administratorPasswordSecretRef= {
                    key = oxr.spec.parameters.passwordSecretRef.key
                    name = oxr.spec.parameters.passwordSecretRef.name
                    namespace = oxr.spec.parameters.passwordSecretRef.namespace
                }
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                storageMb = oxr.spec.parameters.storageGB * 1024
                version = oxr.spec.parameters.version
                delegatedSubnetIdSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                        "azure.platform.upbound.io/subnet-service-type" = "postgresql"
                    }
                }
                publicNetworkAccessEnabled = False
                privateDnsZoneIdSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
            writeConnectionSecretToRef = {
                namespace = oxr.spec.writeConnectionSecretToRef.namespace
                name = "{}-postgresql".format(oxr.metadata.uid)
            }
        }
    }
    dbforpostgresqlv1beta1.FlexibleServerDatabase{
        metadata = {
            **_metadata("database")
            name = "upbound"
        }
        spec = {
            forProvider = {
                charset = "utf8"
                collation = "en_US.utf8"
                serverIdSelector = {
                    matchControllerRef = True
                }
            }
        }
    }
    {
        apiVersion: "meta.krm.kcl.dev/v1alpha1"
        kind: "CompositeConnectionDetails"
        if "postgresqlserver" in ocds:
            data: {
                username = ocds["postgresqlserver"].ConnectionDetails.username
                password = ocds["postgresqlserver"].ConnectionDetails.password
                host = base64.encode(ocds["postgresqlserver"].Resource?.status?.atProvider?.fqdn)
            }
        else:
            data: {}
    }
]

items = _items
