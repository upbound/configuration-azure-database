import models.io.upbound.azure.dbformariadb.v1beta1 as dbformariadbv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "mariadb"
        spec= {
            assertResources: [
                platformazurev1alpha1.XSQLInstance{
                    metadata = {
                        name = "configuration-azure-database-db-mariadb"
                    }
                    spec = {
                        parameters = {
                            storageGB = 5
                            version = "10.3"
                            passwordSecretRef = {
                              namespace = "default"
                              name = "psqlsecret"
                              key = "password"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-mariadb"
                            namespace = "default"
                        }
                    }
                }

                dbformariadbv1beta1.Database{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "database"
                        }
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-mariadb"
                        }
                        name = "upbound"
                        ownerReferences = [
                            {
                                apiVersion = "azure.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XSQLInstance"
                                name = "configuration-azure-database-db-mariadb"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            charset = "utf8"
                            collation = "utf8_general_ci"
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
                dbformariadbv1beta1.Server{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "mariadlserver"
                        }
                        generateName = "configuration-azure-database-db-mariadb-"
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-mariadb"
                        }
                        name = "configuration-azure-database-mariadb"
                        ownerReferences = [
                            {
                                apiVersion = "azure.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XSQLInstance"
                                name = "configuration-azure-database-db-mariadb"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            administratorLogin = "xp-admin"
                            administratorLoginPasswordSecretRef = {
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
                            skuName = "GP_Gen5_2"
                            sslEnforcementEnabled = False
                            sslMinimalTlsVersionEnforced = "TLSEnforcementDisabled"
                            storageMb = 5120
                            version = "10.3"
                        }
                    }
                }
                dbformariadbv1beta1.VirtualNetworkRule{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vnetrule"
                        }
                        generateName = "configuration-azure-database-db-mariadb-"
                        labels = {
                            "crossplane.io/composite" = "configuration-azure-database-db-mariadb"
                        }
                        name = "configuration-azure-database-sn-rule"
                        ownerReferences = [
                            {
                                apiVersion = "azure.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XSQLInstance"
                                name = "configuration-azure-database-db-mariadb"
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
            compositionPath: "apis/mariadb/composition.yaml"
            xrPath: "examples/mariadb-xr.yaml"
            xrdPath: "apis/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
