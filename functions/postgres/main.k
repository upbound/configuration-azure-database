import models.io.upbound.azure.dbforpostgresql.v1beta1 as dbforpostgresqlv1beta1

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
    dbforpostgresqlv1beta1.Server {
        metadata = {
            **_metadata("postgresqlserver")
            name = "{}-postgresql".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                administratorLogin = "psqladmin"
                identity = [
                    { type = "SystemAssigned" }
                ]
                infrastructureEncryptionEnabled = False
                skuName = "GP_Gen5_2"
                sslEnforcementEnabled = False
                sslMinimalTlsVersionEnforced = "TLSEnforcementDisabled"
                location = oxr.spec.parameters.region
                administratorLoginPasswordSecretRef = {
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
            }
            providerConfigRef = {
                name = oxr.spec.parameters.providerConfigName
            }
            writeConnectionSecretToRef = {
                namespace = oxr.spec.writeConnectionSecretToRef.namespace
                name = "{}-postgresql".format(oxr.metadata.uid)
            }
        }
    }
    dbforpostgresqlv1beta1.VirtualNetworkRule {
        metadata = {
            **_metadata("vnetrule")
            name = "{}-sn-rule".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                serverNameSelector = {
                    matchControllerRef = True
                }
                subnetIdSelector = {
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
