import models.io.upbound.azure.dbformysql.v1beta2 as dbformysqlv1beta2
import models.io.upbound.azure.dbformysql.v1beta1 as dbformysqlv1beta1
import models.io.upbound.azure.network.v1beta2 as networkv1beta2
import models.io.upbound.azure.network.v1beta1 as networkv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "mysql-flexibleserver"
        spec= {
            assertResources: [
                platformazurev1alpha1.XSQLInstance{
                    metadata = {
                        name = "configuration-azure-database-db-mysql"
                        namespace = "default"
                    }
                    spec = {
                        compositionSelector = {
                            matchLabels = {
                                dbengine = "mysql"
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
                            storageGB = 20
                            version = "8.0"
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-mysql"
                            namespace = "default"
                        }
                    }
                }
                networkv1beta2.PrivateDNSZone {
                    metadata = {
                        annotations = {
                            "crossplane.io/external-name" = "configuration-azure-database.mysql.database.azure.com"
                        }
                        name = "configuration-azure-database-mysql"
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
                        name = "configuration-azure-database-mysql"
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
                dbformysqlv1beta2.FlexibleServer {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "mysqlserver"
                        }
                        generateName = "configuration-azure-database-db-mysql-"
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-mysql"
                        }
                        name = "configuration-azure-database-mysql"
                    }
                    spec = {
                        forProvider = {
                            administratorLogin = "mysqladmin"
                            skuName = "GP_Standard_D2ds_v4"
                            location = "westus"
                            administratorPasswordSecretRef = {
                                key = "password"
                                name = "psqlsecret"
                                namespace = "default"
                            }
                            backupRetentionDays = 7
                            storage.sizeGb = 20
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            delegatedSubnetIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                    "azure.platform.upbound.io/subnet-service-type" = "mysql"
                                }
                            }
                            privateDnsZoneIdSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
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
                            "crossplane.io/composite" = "configuration-azure-database-db-mysql"
                        }
                        name = "upbound"
                    }
                    spec = {
                        forProvider = {
                            charset = "utf8mb4"
                            collation = "utf8mb4_unicode_ci"
                            resourceGroupNameSelector = {
                                matchLabels = {
                                    "azure.platform.upbound.io/network-id" = "configuration-azure-database"
                                }
                            }
                            serverNameSelector = {
                                matchControllerRef = True
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/mysql/composition.yaml"
            xrPath: "examples/mysql-xr.yaml"
            xrdPath: "apis/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
