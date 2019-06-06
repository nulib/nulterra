{
  "AWSEBDockerrunVersion": 2,
  "volumes": [
    {
      "name": "fcrepo-data",
      "host": { "sourcePath": "/var/app/fcrepo-data" }
    }
  ],
  "containerDefinitions": [
    {
      "name": "fcrepo-app",
      "image": "${image}",
      "memoryReservation": 3000,
      "portMappings": [
        { "hostPort": 8080, "containerPort": 8080 }
      ],
      "environment": [
        { "name": "MODESHAPE_CONFIG", "value": "classpath:/config/jdbc-postgresql-s3/repository.json" }
      ],
      "readonlyRootFilesystem": false,
      "mountPoints": [
        { "sourceVolume": "fcrepo-data", "containerPath": "/data" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${stack_name}",
            "awslogs-region": "${aws_region}",
            "awslogs-stream-prefix": "fcrepo"
        }
      }
    }
  ]
}
