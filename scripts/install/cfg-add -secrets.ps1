

New-SECSecret -Force -Name 'boo' -SecretString "{`"username`":`"bob`",`"password`":`"abc123xyz456`"}"

$secrets = @{
  'sitecore-adminpassword'                                = 'Z4J887C8aXi9'
  'sitecore-collection-shardmapmanager-database-password' = 'Z4J887C8aXi9'
  'sitecore-collection-shardmapmanager-database-username' = 'administrator'
  'sitecore-core-database-password'                       = 'Z4J887C8aXi9'
  'sitecore-core-database-username'                       = 'administrator'
  'sitecore-database-elastic-pool-name'                   = ''
  'sitecore-databasepassword'                             = 'Z4J887C8aXi9'
  'sitecore-databaseservername'                           = 'Z4J887C8aXi9'
  'sitecore-databaseusername'                             = 'administrator'
  'sitecore-exm-master-database-password'                 = 'Z4J887C8aXi9'
  'sitecore-exm-master-database-username'                 = 'administrator'
  'sitecore-forms-database-password'                      = 'Z4J887C8aXi9'
  'sitecore-forms-database-username'                      = 'administrator'
  'sitecore-identitycertificate'                          = ''
  'sitecore-identitycertificatepassword'                  = 'Z4J887C8aXi9'
  'sitecore-identitysecret'                               = 'Z4J887C8aXi9'
  'sitecore-license'                                      = ''
  'sitecore-marketing-automation-database-password'       = 'Z4J887C8aXi9'
  'sitecore-marketing-automation-database-username'       = 'administrator'
  'sitecore-master-database-password'                     = 'Z4J887C8aXi9'
  'sitecore-master-database-username'                     = 'administrator'
  'sitecore-messaging-database-password'                  = 'Z4J887C8aXi9'
  'sitecore-messaging-database-username'                  = 'administrator'
  'sitecore-processing-engine-storage-database-password'  = 'Z4J887C8aXi9'
  'sitecore-processing-engine-storage-database-username'  = 'administrator'
  'sitecore-processing-engine-tasks-database-password'    = 'Z4J887C8aXi9'
  'sitecore-processing-engine-tasks-database-username'    = 'administrator'
  'sitecore-processing-pools-database-password'           = 'Z4J887C8aXi9'
  'sitecore-processing-pools-database-username'           = 'administrator'
  'sitecore-processing-tasks-database-password'           = 'Z4J887C8aXi9'
  'sitecore-processing-tasks-database-username'           = 'administrator'
  'sitecore-reference-data-database-password'             = 'Z4J887C8aXi9'
  'sitecore-reference-data-database-username'             = 'administrator'
  'sitecore-reporting-database-password'                  = 'Z4J887C8aXi9'
  'sitecore-reporting-database-username'                  = 'administrator'
  'sitecore-reportingapikey'                              = ''
  'sitecore-solr-connection-string-xdb'                   = ''
  'sitecore-solr-connection-string'                       = ''
  'sitecore-telerikencryptionkey'                         = ''
  'sitecore-web-database-password'                        = 'Z4J887C8aXi9'
  'sitecore-web-database-username'                        = 'administrator'
}

$secrets