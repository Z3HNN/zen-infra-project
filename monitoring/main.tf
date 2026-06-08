terraform {
    required_providers{
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
 }
}


variable "region" {
    description = "region"
    type = string
    default = "us-east-1"
}

variable "project_name" {
    description = "Namespaces all resources"
    type = string
    default = "zen-infra-project"
}

provider "aws" {
    region = var.region
}

##EC2

#Variables

variable "instance_id" {
    description = "EC2 instance ID"
    type = string
}

#Resources

resource "aws_sns_topic" "alerts" {
    name = "${var.project_name}-alerts"

    tags = {
        Name = "${var.project_name}-alerts"
    }
}

resource "aws_sns_topic_subscription" "email" {
    topic_arn = aws_sns_topic.alerts.arn
    protocol = "email"
    endpoint = "z3hndolphin@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
    alarm_name = "${var.project_name}-high-cpu"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 120
    statistic = "Average"
    threshold = 80
    alarm_actions = [aws_sns_topic.alerts.arn]
    dimensions = {
        InstanceId = var.instance_id
    }
    }

    ##OUTPUTS

    output "sns_topic_alarm" {
        description = "SNS topic ARN for alerts"
        value = aws_sns_topic.alerts.arn
    }