{
  "AWSEBDockerrunVersion": 2,
  "volumes": [
    {
      "name": "arch-working",
      "host": { "sourcePath": "/var/app/arch-working" }
    },
    {
      "name": "arch-derivatives",
      "host": { "sourcePath": "/var/app/arch-derivatives" }
    }
  ],
  "containerDefinitions": [
    {
      "name": "arch-app",
      "image": "${app_image}",
      "essential": true,
      "memoryReservation": 3000,
      "portMappings": [
        { "hostPort": 80, "containerPort": 3000 }
      ],
      "environment": [
        { "name": "BUNDLE_WITH",                                             "value": "aws:postgres" },
        { "name": "BUNDLE_WITHOUT",                                          "value": "development:test" },
        { "name": "DISABLE_REDIS_CLUSTER",                                   "value": "true" },
	      { "name": "MAGICK_MEMORY_LIMIT",                                     "value": "1073741824" },
        { "name": "MAGICK_TMPDIR",                                           "value": "/tmp" },
        { "name": "RAILS_GROUPS",                                            "value": "aws" },
        { "name": "RAILS_SERVE_STATIC_FILES",                                "value": "true" },
	      { "name": "RAILS_SKIP_ASSET_COMPILATION",                            "value": "false" },
        { "name": "RAILS_SKIP_MIGRATIONS",                                   "value": "false" },
        { "name": "SETTINGS__ACTIVE_JOB__QUEUE_ADAPTER",                     "value": "active_elastic_job" },
        { "name": "SETTINGS__EMAIL__MAILER",                                 "value": "aws_sdk" },
        { "name": "SETTINGS__FFMPEG__PATH",                                  "value": "/usr/local/bin/ffmpeg" },
        { "name": "SETTINGS__FITS__PATH",                                    "value": "/usr/local/fits/fits.sh" },
        { "name": "SETTINGS__GROUPS__SYSTEM_GROUPS",                         "value": "administrator,group_manager,manager" },
        { "name": "SETTINGS__NAME",                                          "value": "arch" },
        { "name": "SETTINGS__DERIVATIVES_PATH",                              "value": "/var/arch-derivatives" },
        { "name": "SETTINGS__WORKING_PATH",                                  "value": "/var/arch-working/work" },
        { "name": "SETTINGS__SOLR__COLLECTION_OPTIONS__REPLICATION_FACTOR",  "value": "3" },
        { "name": "SETTINGS__SOLR__COLLECTION_OPTIONS__RULE",                "value": "shard:*,replica:<2,cores:<5~" },
        { "name": "TMPDIR",                                                  "value": "/var/arch-working/temp" }
      ],
      "readonlyRootFilesystem": false,
      "mountPoints": [
        { "sourceVolume": "awseb-logs-arch-app",  "containerPath": "/home/app/current/log"  },
        { "sourceVolume": "arch-working",         "containerPath": "/var/arch-working"     },
        { "sourceVolume": "arch-derivatives",     "containerPath": "/var/arch-derivatives" }
      ]
    }
  ]
}
