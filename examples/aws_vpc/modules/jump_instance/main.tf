resource "aws_instance" "jump_instance" {
  ami                  = var.ami
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  key_name             = aws_key_pair.jump_instance_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.jump_instance_profile.name
  user_data_base64     = filebase64("${path.module}/assets/setup.sh")
  tags                 = var.tags
}

resource "aws_iam_instance_profile" "jump_instance_profile" {
  name = "jump_instance_profile"
  role = aws_iam_role.jump_instance_iam_role.name
}

resource "aws_iam_role" "jump_instance_iam_role" {
  name               = "jump_instance_iam_role"
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

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.jump_instance_iam_role.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_key_pair" "jump_instance_key_pair" {
  key_name_prefix = "jump_instance_"
  public_key      = var.ssh_public_key
  tags            = var.tags
}
