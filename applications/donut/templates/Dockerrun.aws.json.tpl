{
  "AWSEBDockerrunVersion": 2,
  "volumes": [
    {
      "name": "donut-working",
      "host": { "sourcePath": "/var/app/donut-working" }
    },
    {
      "name": "donut-derivatives",
      "host": { "sourcePath": "/var/app/donut-derivatives" }
    }
  ],
  "containerDefinitions": [
    {
      "name": "donut-app",
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
        { "name": "SETTINGS__FFMPEG__PATH",                                  "value": "/usr/local/bin/ffmpeg" },
        { "name": "SETTINGS__FITS__PATH",                                    "value": "/usr/local/fits/fits.sh" },
        { "name": "SETTINGS__GROUPS__SYSTEM_GROUPS",                         "value": "administrator,group_manager,manager" },
        { "name": "SETTINGS__NAME",                                          "value": "donut" },
        { "name": "SETTINGS__UPLOAD_PATH",                                   "value": "/var/donut-working/temp" },
        { "name": "SETTINGS__DERIVATIVES_PATH",                              "value": "/var/donut-derivatives" },
        { "name": "SETTINGS__WORKING_PATH",                                  "value": "/var/donut-working/work" },
        { "name": "SETTINGS__SOLR__COLLECTION_OPTIONS__REPLICATION_FACTOR",  "value": "3" },
        { "name": "SETTINGS__SOLR__COLLECTION_OPTIONS__RULE",                "value": "shard:*,replica:<2,cores:<5~" },
        { "name": "TMPDIR",                                                  "value": "/var/donut-working/temp" }
      ],
      "readonlyRootFilesystem": false,
      "mountPoints": [
        { "sourceVolume": "awseb-logs-donut-app",  "containerPath": "/home/app/current/log"  },
        { "sourceVolume": "donut-working",         "containerPath": "/var/donut-working"     },
        { "sourceVolume": "donut-derivatives",     "containerPath": "/var/donut-derivatives" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${stack_name}",
            "awslogs-region": "${aws_region}",
            "awslogs-stream-prefix": "donut"
        }
      }
    }
  ]
}
