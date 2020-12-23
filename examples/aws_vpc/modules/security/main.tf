resource "aws_iam_role" "keepalived_instance_role" {
  name               = "keepalived_instance_role"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "keepalived_instance_role_policy" {
  role   = aws_iam_role.keepalived_instance_role.id
  policy = data.aws_iam_policy_document.keepalived_role_policy.json
}

data "aws_iam_policy_document" "keepalived_role_policy" {
  statement {
    actions = [
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:ReplaceRoute",
    ]
    resources = [
      "arn:aws:ec2:ap-northeast-1:${var.keepalived_route_table_owner_id}:route-table/${var.keepalived_route_table_id}"
    ]
  }
}
