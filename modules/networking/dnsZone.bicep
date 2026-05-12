// modules/networking/dnsZone.bicep
// Public DNS Zone for internet-facing name resolution

@description('DNS zone name - must be a valid domain name')
param zoneName string

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('A records to create in the zone')
param aRecords array = []

@description('CNAME records to create in the zone')
param cnameRecords array = []

@description('TXT records for domain verification')
param txtRecords array = []

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Public DNS Zone
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: zoneName
  location: 'global'
  tags: commonTags
  properties: {
    zoneType: 'Public'
  }
}

// A Records
resource aRecordSet 'Microsoft.Network/dnsZones/A@2018-05-01' = [for record in aRecords: {
  parent: dnsZone
  name: record.name
  properties: {
    TTL: record.ttl
    ARecords: [
      {
        ipv4Address: record.ipAddress
      }
    ]
  }
}]

// CNAME Records
resource cnameRecordSet 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = [for record in cnameRecords: {
  parent: dnsZone
  name: record.name
  properties: {
    TTL: record.ttl
    CNAMERecord: {
      cname: record.cname
    }
  }
}]

// TXT Records
resource txtRecordSet 'Microsoft.Network/dnsZones/TXT@2018-05-01' = [for record in txtRecords: {
  parent: dnsZone
  name: record.name
  properties: {
    TTL: record.ttl
    TXTRecords: [
      {
        value: [record.value]
      }
    ]
  }
}]

output zoneId string = dnsZone.id
output zoneName string = dnsZone.name
output nameServers array = dnsZone.properties.nameServers
