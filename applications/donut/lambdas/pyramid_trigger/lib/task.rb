require 'aws-sdk-ecs'
require 'aws-sdk-ec2'
require 'open-uri'

class Task
  attr_reader :ecs, :vpc_id, :family, :version

  def initialize
    @ecs = Aws::ECS::Client.new
    @vpc_id = ENV['VpcId']
    @family, @version = ENV['TaskArn'].split(/[\/:]/).last(2)
  end

  def task_running?
    response = ecs.list_tasks(family: family)
    !response.to_h[:task_arns].empty?
  end

  def run_task
    ecs.run_task(
      cluster: 'default',
      task_definition: "#{family}:#{version}",
      launch_type: 'FARGATE',
      started_by: 'donut',
      network_configuration: {
        awsvpc_configuration: {
          subnets: subnets,
          security_groups: security_groups,
          assign_public_ip: 'DISABLED'
        }
      }
    )
  end

  def vpc
    @vpc ||= Aws::EC2::Vpc.new(vpc_id)
  end

  def security_groups
    @security_groups ||= [
      vpc.security_groups.find { |sg| sg.group_name == 'default' }.id
    ]
  end

  def subnets
    @subnets ||= vpc.subnets.select do |subnet|
      subnet.tags.find { |t| t.key == 'Name' }.value =~ /private/
    end.collect(&:id)
  end
end
