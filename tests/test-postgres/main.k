import models.io.upbound.azure.dbforpostgresql.v1beta2 as dbforpostgresqlv1beta2
import models.io.upbound.azure.dbforpostgresql.v1beta1 as dbforpostgresqlv1beta1
import models.io.upbound.azure.network.v1beta2 as networkv1beta2
import models.io.upbound.azure.network.v1beta1 as networkv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "pg-flexibleserver"
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
                            storageGB = 32
                            version = "11"
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-postgresql"
                            namespace = "default"
                        }
                    }
                }
                networkv1beta2.PrivateDNSZone {
                    metadata = {
                        annotations = {
                            "crossplane.io/external-name" = "configuration-azure-database.postgres.database.azure.com"
                        }
                        name = "configuration-azure-database-postgresql"
                        labels = {
                            "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                        }
                    }
                    spec = {
                        forProvider = {
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                        }
                    }
                }
                networkv1beta1.PrivateDNSZoneVirtualNetworkLink {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "privatednszonevnetlink"
                        }
                        name = "configuration-azure-database-postgresql"
                    }
                    spec = {
                        forProvider = {
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            privateDnsZoneNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            virtualNetworkIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                        }
                    }
                }
                dbforpostgresqlv1beta2.FlexibleServer{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "postgresqlserver"
                        }
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-postgresql"
                        }
                        name = "configuration-azure-database-postgresql"
                    }
                    spec = {
                        forProvider = {
                            administratorLogin = "psqladmin"
                            administratorPasswordSecretRef = {
                                key = "password"
                                name = "psqlsecret"
                                namespace = "default"
                            }
                            location = "westus"
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            skuName = "GP_Standard_D4s_v3"
                            storageMb = 32768
                            version = "11"
                            delegatedSubnetIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                    "azure.platform.upbound.io/subnet-service-type" = "postgres"
                                }
                            }
                            publicNetworkAccessEnabled = False
                            privateDnsZoneIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                        }
                    }
                }
                dbforpostgresqlv1beta1.FlexibleServerDatabase{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "database"
                        }
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-postgresql"
                        }
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
