console.log('Loading function');

var AWS = require('aws-sdk');

exports.handler = function(event, context) {
  console.log('event=%j', event);

  get_instance_ids(event, context);
};

function get_instance_ids(event, context) {
  if (event.detail) {
    var asgName = event.detail.AutoScalingGroupName;
  } else {
    var asgName = event.ResourceProperties.ZookeeperASGName;
  }

  var autoscaling = new AWS.AutoScaling();
  var asgParams = {
    AutoScalingGroupNames: [asgName],
    MaxRecords: 1
  };
  autoscaling.describeAutoScalingGroups(asgParams, function(err, data) {
    if (err) {
      console.log(err, err.stack);
    } else {
      var instances = data.AutoScalingGroups[0].Instances
      var instanceIds = instances.map(function (instance) {
         return instance.InstanceId;
      });
      console.log(instanceIds);
      get_instance_ips(event, context, instanceIds)
    }
  });
}

function get_instance_ips(event, context, instanceIds) {
    var ec2 = new AWS.EC2();
    var ec2Params = {
      InstanceIds: instanceIds
    };
    ec2.describeInstances(ec2Params, function(err, data) {
      if (err) {
        console.log(err, err.stack);
      } else {
        var reservations = data.Reservations;
        var instances = reservations.map(function (reservation) {
          return reservation.Instances;
        });
        var instanceIps = instances.map(function (instance) {
          return instance[0].PrivateIpAddress;
        });
        console.log(instanceIps);
        upsert_hostedzone(event, context, instanceIps)
      }
    });
}

function upsert_hostedzone(event, context, instanceIps) {
    var route53 = new AWS.Route53();

    if (event.RequestType == 'Delete') {
      var actionChange = "DELETE"
    } else {
      var actionChange = "UPSERT"
    }

    var resourceRecords = instanceIps.map(function (ip) {
        return { "Value": ip };
    });
    var r53Params = {
      ChangeBatch: {
        Changes: [
          {
            Action: actionChange,
            ResourceRecordSet: {
              Name: process.env.RecordSetName,
              Type: "A",
              ResourceRecords: resourceRecords,
              TTL: 300
            }
          }
        ],
        Comment: "RoundRobin record for zookeeper hosts"
      },
      HostedZoneId: process.env.HostedZoneId
    };
    route53.changeResourceRecordSets(r53Params, function(err, data) {
      if (err) {
        console.log(err, err.stack);
      } else {
        console.log(data);
      }
    });
}
