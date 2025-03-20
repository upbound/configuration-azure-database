import models.io.upbound.azure.v1beta1 as azurev1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "dbs"
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                platformazurev1alpha1.XSQLInstance{
                    metadata = {
                        name = "configuration-azure-database-db-mariadb"
                    }
                    spec = {
                        compositionSelector = {
                            matchLabels = {
                                dbengine = "mariadb"
                            }
                        }
                        parameters = {
                            region = "westus"
                            storageGB = 5
                            version = "10.3"
                            passwordSecretRef = {
                                namespace = "default"
                                name = "psqlsecret"
                                key = "password"
                            }
                            networkRef = {
                                id = "configuration-azure-database"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-mariadb"
                            namespace = "default"
                        }
                    }
                }
                platformazurev1alpha1.XSQLInstance{
                    metadata = {
                        name = "configuration-azure-database-db-postgresql"
                    }
                    spec = {
                        compositionSelector = {
                            matchLabels = {
                                dbengine = "postgres"
                            }
                        }
                        parameters = {
                            region = "westus"
                            storageGB = 5
                            version = "11"
                            passwordSecretRef = {
                                namespace = "default"
                                name = "psqlsecret"
                                key = "password"
                            }
                            networkRef = {
                                id = "configuration-azure-database"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-azure-database-db-conn-postgresql"
                            namespace = "default"
                        }
                    }
                }
                platformazurev1alpha1.XNetwork{
                    metadata = {
                        name = "ref-azure-network"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-azure-database"
                            region = "westus"
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
                        name = "psqlsecret"
                        namespace = "default"
                    }
                }
                # Define the provider configuration
                azurev1beta1.ProviderConfig{
                    metadata.name = "default"
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
