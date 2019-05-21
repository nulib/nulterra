[
 {
   "logConfiguration": {
     "logDriver": "awslogs",
     "options": {
       "awslogs-group": "/ecs/${task_name}",
       "awslogs-region": "${region}",
       "awslogs-stream-prefix": "ecs"
     }
   },
   "cpu": 2000,
   "environment": [{
     "name": "queueUrl",
     "value": "${queue_url}"
   }],
   "memoryReservation": 8000,
   "image": "${image_name}",
   "name": "app"
 }
]