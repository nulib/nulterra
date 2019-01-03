{
  "AWSEBDockerrunVersion": 2,
  "containerDefinitions": [
    {
      "name": "zookeeper-app",
      "image": "nulib/zookeeper-exhibitor:latest",
      "essential": true,
      "memoryReservation": 3000,
      "portMappings": [
        { "hostPort": 8181, "containerPort": 8181 },
        { "hostPort": 2181, "containerPort": 2181 },
        { "hostPort": 2888, "containerPort": 2888 },
        { "hostPort": 3888, "containerPort": 3888 }
      ],
      "readonlyRootFilesystem": false,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${stack_name}",
            "awslogs-region": "${aws_region}",
            "awslogs-stream-prefix": "zk"
        }
      }
    }
  ]
}
