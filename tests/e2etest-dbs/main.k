import models.io.upbound.azurem.v1beta1 as azurev1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "dbs"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready"]
            manifests: [
                platformazurev1alpha1.SQLInstance{
                    metadata = {
                        namespace = "default"
                        name = "configuration-azure-database-db-mysql"
                    }
                    spec = {
                        crossplane.compositionSelector = {
                            matchLabels = {
                                dbengine = "mysql"
                            }
                        }
                        parameters = {
                            region = "westeurope"
                            storageGB = 20
                            version = "10.3"
                            passwordSecretRef = {
                                name = "psqlsecret"
                                key = "password"
                            }
                            networkRef = {
                                id = "configuration-azure-database-mysql"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-mysql"
                        }
                    }
                }
                platformazurev1alpha1.SQLInstance{
                    metadata = {
                        namespace = "default"
                        name = "configuration-azure-database-db-postgresql"
                    }
                    spec = {
                        crossplane.compositionSelector = {
                            matchLabels = {
                                dbengine = "postgres"
                            }
                        }
                        parameters = {
                            region = "westeurope"
                            storageGB = 32
                            version = "16"
                            passwordSecretRef = {
                                name = "psqlsecret"
                                key = "password"
                            }
                            networkRef = {
                                id = "configuration-azure-database-postgresql"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-postgresql"
                        }
                    }
                }
                platformazurev1alpha1.Network{
                    metadata = {
                        namespace = "default"
                        name = "ref-azure-network-postgresql"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-azure-database-postgresql"
                            region = "westeurope"
                            addressRange = "10.0.0.0/16"
                            generalSubnetRange = "10.0.1.0/24"
                            databaseSubnets = [
                                {
                                    addressRange = "10.0.2.0/24"
                                    serviceType = "postgres"
                                }
                            ]
                        }
                    }
                }
                platformazurev1alpha1.Network{
                    metadata = {
                        namespace = "default"
                        name = "ref-azure-network-mysql"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-azure-database-mysql"
                            region = "westeurope"
                            addressRange = "10.0.0.0/16"
                            generalSubnetRange = "10.0.1.0/24"
                            databaseSubnets = [
                                {
                                    addressRange = "10.0.3.0/24"
                                    serviceType = "mysql"
                                }
                            ]
                        }
                    }
                }
            ]
            extraResources = [
                {
                    apiVersion = "v1"
                    data = {
                        password = "dXBiMHVuZHIwY2s1ITMxMzM3"
                    }
                    kind = "Secret"
                    metadata = {
                        namespace = "default"
                        name = "psqlsecret"
                        namespace = "default"
                    }
                }
                # Define the provider configuration
                azurev1beta1.ProviderConfig{
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Upbound"
                        }
                        clientID = "bcf40abd-283c-494b-b186-03d6c864be51"
                        tenantID = "b9925bc4-8383-4c37-b9d2-fa456d1bb1c7"
                        subscriptionID = "038f2b7c-3265-43b8-8624-c9ad5da610a8"
                    }
                }

            ]

            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items= _items
