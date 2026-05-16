# Create Json policy for assuming role
data "aws_iam_policy_document" "vpc_logs_assume_role" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["aws_vpc_logs.amazonaws.com"]
    }

  }
}

# The role 
resource "aws_iam_role" "flowlogs_role" {
  name               = "vpc_logs_role"
  assume_role_policy = data.aws_iam_policy_document.vpc_logs_assume_role.json
}

# Create the permission policy that will be used the role
data "aws_iam_policy_document" "vpc_flowlogs_permissions" {
  statement {
    sid    = "2"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGrouops",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/logs/*"]
  }
}

resource "aws_iam_policy" "vpc_logs_policy" {
  name   = "vpc_logs_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.vpc_flowlogs_permissions.json
}

# The destination. The log group where the logs will be sent
resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "/aws/vpc/logs"
  tags = var.common_tags
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
