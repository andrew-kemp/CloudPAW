param reference_privateEndpoints_0_20702994974933575_outputs_networkInterfaceId_value object

resource privatelink_file_core_windows_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: string('privatelink.file.core.windows.net')
  location: 'global'
  tags: {}
  properties: {}
}

resource privatelink_file_core_windows_net_subscriptions_c2c6a139_16f1_46fd_bcac_60bd2bed8c2f_resourceGroups_cPAW_providers_Microsoft_Network_virtualNetworks_cPAW_vNet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${string('privatelink.file.core.windows.net')}/${uniqueString(string('/subscriptions/c2c6a139-16f1-46fd-bcac-60bd2bed8c2f/resourceGroups/cPAW/providers/Microsoft.Network/virtualNetworks/cPAW-vNet'))}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: string('/subscriptions/c2c6a139-16f1-46fd-bcac-60bd2bed8c2f/resourceGroups/cPAW/providers/Microsoft.Network/virtualNetworks/cPAW-vNet')
    }
    registrationEnabled: false
  }
  dependsOn: [
    privatelink_file_core_windows_net
  ]
}

module EndpointDnsRecords_0_6908106489573504 'https://storage.hosting.portal.azure.net/storage/Content/5.13.393.1962/DeploymentTemplates/PrivateDnsForPrivateEndpoint.json' = {
  name: 'EndpointDnsRecords-0.6908106489573504'
  params: {
    privateDnsName: string('privatelink.file.core.windows.net')
    privateEndpointNicResourceId: reference_privateEndpoints_0_20702994974933575_outputs_networkInterfaceId_value.outputs.networkInterfaceId.value
    nicRecordsTemplateUri: 'https://storage.hosting.portal.azure.net/storage/Content/5.13.393.1962/DeploymentTemplates/PrivateDnsForPrivateEndpointNic.json'
    ipConfigRecordsTemplateUri: 'https://storage.hosting.portal.azure.net/storage/Content/5.13.393.1962/DeploymentTemplates/PrivateDnsForPrivateEndpointIpConfig.json'
    uniqueId: '0.6908106489573504'
    existingRecords: {}
  }
  dependsOn: [
    privatelink_file_core_windows_net
  ]
}
