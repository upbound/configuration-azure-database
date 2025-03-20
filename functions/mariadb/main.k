import models.io.upbound.azure.dbformariadb.v1beta1 as dbformariadbv1beta1
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

_items = [
    dbformariadbv1beta1.Database {
        metadata = {
            **_metadata("database")
            name = "upbound"
        }
        spec = {
            **_defaultSpec
            forProvider = {
                charset = "utf8"
                collation = "utf8_general_ci"
                serverNameSelector = {
                    matchControllerRef = True
                }
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
            }
            providerConfigRef = {
                name = oxr.spec.parameters.providerConfigName
            }
        }
    }
    dbformariadbv1beta1.Server {
        metadata = {
            **_metadata("mariadlserver")
            name = "{}-mariadb".format(oxr.spec.parameters.networkRef.id)
        }
        spec = {
            **_defaultSpec
            forProvider = {
                administratorLogin = "xp-admin"
                administratorLoginPasswordSecretRef = {
                    key = oxr.spec.parameters.passwordSecretRef.key
                    name = oxr.spec.parameters.passwordSecretRef.name
                    namespace = oxr.spec.parameters.passwordSecretRef.namespace
                }
                location = oxr.spec.parameters.region
                resourceGroupNameSelector = {
                    matchLabels = {
                        "azure.platform.upbound.io/network-id" = oxr.spec.parameters.networkRef.id
                    }
                }
                skuName = "GP_Gen5_2"
                sslEnforcementEnabled = False
                sslMinimalTlsVersionEnforced = "TLSEnforcementDisabled"
                storageMb = oxr.spec.parameters.storageGB * 1024
                version = oxr.spec.parameters.version
            }
            providerConfigRef = {
                name = oxr.spec.parameters.providerConfigName
            }
            writeConnectionSecretToRef = {
                namespace = oxr.spec.writeConnectionSecretToRef.namespace
                name = "{}-mariadb".format(oxr.metadata.uid)
            }
        }
    }

    dbformariadbv1beta1.VirtualNetworkRule {
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
        if "mariadlserver" in ocds:
            data: {
                username = ocds["mariadlserver"].ConnectionDetails.username
                password = ocds["mariadlserver"].ConnectionDetails.password
                host = base64.encode(ocds["mariadlserver"].Resource?.status?.atProvider?.fqdn)
            }
        else:
            data: {}
    }
]

items = _items
