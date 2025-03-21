import models.io.upbound.azure.dbforpostgresql.v1beta1 as dbforpostgresqlv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: ""
        spec= {
            assertResources: [
                platformazurev1alpha1.XSQLInstance{
                    metadata = {
                        name = "configuration-azure-database-db-postgresql"
                        namespace = "default"
                    }
                    spec = {
                        compositionSelector = {
                            matchLabels = {
                                dbengine = "postgres"
                            }
                        }
                        parameters = {
                            networkRef = {
                                id = "configuration-azure-database"
                            }
                            passwordSecretRef = {
                                key = "password"
                                name = "psqlsecret"
                                namespace = "default"
                            }
                            region = "westus"
                            storageGB = 5
                            version = "11"
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-postgresql"
                            namespace = "default"
                        }
                    }
                }
                dbforpostgresqlv1beta1.Server{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "postgresqlserver"
                        }
                        generateName = "configuration-azure-database-db-postgresql-"
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-postgresql"
                        }
                        name = "configuration-azure-database-postgresql"
                        ownerReferences = [
                            {
                                apiVersion = "azure.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XSQLInstance"
                                name = "configuration-azure-database-db-postgresql"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            administratorLogin = "psqladmin"
                            administratorLoginPasswordSecretRef = {
                                key = "password"
                                name = "psqlsecret"
                                namespace = "default"
                            }
                            identity = [
                                {
                                    $type = "SystemAssigned"
                                }
                            ]
                            infrastructureEncryptionEnabled = False
                            location = "westus"
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            skuName = "GP_Gen5_2"
                            sslEnforcementEnabled = False
                            sslMinimalTlsVersionEnforced = "TLSEnforcementDisabled"
                            storageMb = 5120
                            version = "11"
                        }
                    }
                }
                dbforpostgresqlv1beta1.VirtualNetworkRule{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vnetrule"
                        }
                        generateName = "configuration-azure-database-db-postgresql-"
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-postgresql"
                        }
                        name = "configuration-azure-database-sn-rule"
                        ownerReferences = [
                            {
                                apiVersion = "azure.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XSQLInstance"
                                name = "configuration-azure-database-db-postgresql"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            serverNameSelector = {
                                matchControllerRef = True
                            }
                            subnetIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                        }
                    }
            }
            ]
            compositionPath: "apis/postgresql/composition.yaml"
            xrPath: "examples/postgres-xr.yaml"
            xrdPath: "apis/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
