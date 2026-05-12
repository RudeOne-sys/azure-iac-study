// deployments/managementGroups.bicep
// Management Group hierarchy for ALZ structure
// Deployed at tenant scope

targetScope = 'tenant'

@description('Tenant ID')
param tenantId string

@description('Prefix for management group names')
param mgPrefix string = 'mg'

// Root management groups
resource platformMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-platform'
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: tenantId
      }
    }
  }
}

resource landingZonesMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-landingzones'
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: tenantId
      }
    }
  }
}

resource sandboxMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-sandbox'
  properties: {
    displayName: 'Sandbox'
    details: {
      parent: {
        id: tenantId
      }
    }
  }
}

// Platform child management groups
resource connectivityMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-connectivity'
  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

resource managementMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-management'
  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

resource identityMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-identity'
  properties: {
    displayName: 'Identity'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

// Landing Zone child management groups
resource corpMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-corp'
  properties: {
    displayName: 'Corp'
    details: {
      parent: {
        id: landingZonesMg.id
      }
    }
  }
}

resource onlineMg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: '${mgPrefix}-online'
  properties: {
    displayName: 'Online'
    details: {
      parent: {
        id: landingZonesMg.id
      }
    }
  }
}

// Outputs
output platformMgId string = platformMg.id
output landingZonesMgId string = landingZonesMg.id
output connectivityMgId string = connectivityMg.id
output managementMgId string = managementMg.id
output identityMgId string = identityMg.id
output corpMgId string = corpMg.id
output onlineMgId string = onlineMg.id
