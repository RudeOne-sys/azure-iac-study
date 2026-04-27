// modules/compute/virtualMachine.bicep
// Linux VM with managed identity and no public IP

@description('VM name')
@maxLength(15)
param vmName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Subnet ID to attach the NIC to')
param subnetId string

@description('VM size - dev uses smaller SKU to save cost')
param vmSize string = environment == 'prod' ? 'Standard_D2s_v3' : 'Standard_B2s'

@description('Admin username')
param adminUsername string = 'azureadmin'

@description('Admin SSH public key')
@secure()
param adminSshKey string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

var nicName = 'nic-${vmName}'
var osDiskName = 'osdisk-${vmName}'

// Network Interface - connects VM to subnet
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  tags: commonTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  tags: commonTags

  // System-assigned managed identity
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }

    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }

    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: environment == 'prod' ? 'Premium_LRS' : 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

output vmId string = virtualMachine.id
output vmName string = virtualMachine.name
output managedIdentityPrincipalId string = virtualMachine.identity.principalId
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
