{
  "AWSEBDockerrunVersion": 2,
  "volumes": [],
  "containerDefinitions": [
    {
      "name": "avr-app",
      "image": "${app_image}",
      "essential": true,
      "memoryReservation": 3000,
      "portMappings": [
        { "hostPort": 80, "containerPort": 3000 }
      ],
      "environment": [
        { "name": "BUNDLE_WITH",                                            "value": "aws:postgres:zoom:ezid" },
        { "name": "BUNDLE_WITHOUT",                                         "value": "development:test" },
        { "name": "DISABLE_REDIS_CLUSTER",                                  "value": "'true'" },
        { "name": "RAILS_GROUPS",                                           "value": "'aws'" },
        { "name": "RAILS_SERVE_STATIC_FILES",                               "value": "'true'" },
        { "name": "SETTINGS__ACTIVE_JOB__QUEUE_ADAPTER",                    "value": "active_elastic_job" },
        { "name": "SETTINGS__FFMPEG__PATH",                                 "value": "/usr/local/bin/ffmpeg" },
        { "name": "SETTINGS__GROUPS__SYSTEM_GROUPS",                        "value": "administrator,group_manager,manager" },
        { "name": "SETTINGS__ENCODING__ENGINE_ADAPTER",                     "value": "elastic_transcoder" },
        { "name": "SETTINGS__MEDIAINFO__PATH",                              "value": "/usr/bin/mediainfo" },
        { "name": "SETTINGS__NAME",                                         "value": "avalon" },
        { "name": "SETTINGS__STREAMING__SERVER",                            "value": "aws" },
        { "name": "SETTINGS__BIB_RETRIEVER__PROTOCOL",                      "value": "z39.50" },
        { "name": "SETTINGS__BIB_RETRIEVER__HOST",                          "value": "na02.alma.exlibrisgroup.com" },
        { "name": "SETTINGS__BIB_RETRIEVER__PORT",                          "value": "1921" },
        { "name": "SETTINGS__BIB_RETRIEVER__DATABASE",                      "value": "01NWU_INST" },
        { "name": "SETTINGS__BIB_RETRIEVER__ATTRIBUTE",                     "value": "12" },
        { "name": "SETTINGS__CONTROLLED_VOCABULARY__PATH",                  "value": "config/nu_vocab.yml" }
      ],
      "readonlyRootFilesystem": false,
      "mountPoints": [
        { "sourceVolume": "awseb-logs-avr-app",  "containerPath": "/home/app/current/log"  }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${stack_name}",
            "awslogs-region": "${aws_region}",
            "awslogs-stream-prefix": "avr"
        }
      }
    }
  ]
}
