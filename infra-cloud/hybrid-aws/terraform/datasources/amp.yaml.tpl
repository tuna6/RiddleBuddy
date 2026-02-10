apiVersion: 1

datasources:
  - name: AMP
    type: prometheus
    access: proxy
    url: https://aps-workspaces.${aws_region}.amazonaws.com/workspaces/${amp_workspace_id}/api/v1
    isDefault: true
    jsonData:
      sigV4Auth: true
      sigV4Region: ${aws_region}
      httpMethod: POST