{
  "AWSEBDockerrunVersion": 2,
  "volumes": [
    {
      "name": "solr-scripts",
      "host": { "sourcePath": "/var/app/current/solr-scripts" }
    },
    {
      "name": "solr-data",
      "host": { "sourcePath": "/var/app/solr-data" }
    },
    {
      "name": "solr-backup",
      "host": { "sourcePath": "/var/app/solr-backup" }
    }
  ],
  "containerDefinitions": [
    {
      "name": "solr-app",
      "image": "solr:7.5",
      "essential": true,
      "memoryReservation": 3000,
      "portMappings": [
        { "hostPort": 8983, "containerPort": 8983 }
      ],
      "environment": [
        { "name": "SOLR_MODE",       "value": "solrcloud"  },
        { "name": "SOLR_HOME",       "value": "/data/solr" },
        { "name": "INIT_SOLR_HOME",  "value": "yes"        }
      ],
      "readonlyRootFilesystem": false,
      "mountPoints": [
        { "sourceVolume": "awseb-logs-solr-app", "containerPath": "/opt/solr/server/logs"       },
        { "sourceVolume": "solr-data",           "containerPath": "/data/solr"                  },
        { "sourceVolume": "solr-backup",         "containerPath": "/data/backup"                },
        { "sourceVolume": "solr-scripts",        "containerPath": "/docker-entrypoint-initdb.d" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${stack_name}",
            "awslogs-region": "${aws_region}",
            "awslogs-stream-prefix": "solr"
        }
      }
    }
  ]
}
