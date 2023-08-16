locals {
  vpc = {
    cidr_block           = "10.0.0.0/23"
    private_subnet_cidrs = ["10.0.1.0/25", "10.0.1.128/25"]
    availability_zones   = ["us-east-1a", "us-east-1b"]
  }

  sagemaker = {
    jupyter_image_tag = "jupyter-server-3"
    image_arn_prefixes = {
      us-east-1      = "arn:aws:sagemaker:us-east-1:081325390199:image"
      us-east-2      = "arn:aws:sagemaker:us-east-2:429704687514:image"
      us-west-1      = "arn:aws:sagemaker:us-west-1:742091327244:image"
      us-west-2      = "arn:aws:sagemaker:us-west-2:236514542706:image"
      af-south-1     = "arn:aws:sagemaker:af-south-1:559312083959:image"
      ap-east-1      = "arn:aws:sagemaker:ap-east-1:493642496378:image"
      ap-south-1     = "arn:aws:sagemaker:ap-south-1:394103062818:image"
      ap-northeast-2 = "arn:aws:sagemaker:ap-northeast-2:806072073708:image"
      ap-southeast-1 = "arn:aws:sagemaker:ap-southeast-1:492261229750:image"
      ap-southeast-2 = "arn:aws:sagemaker:ap-southeast-2:452832661640:image"
      ap-northeast-1 = "arn:aws:sagemaker:ap-northeast-1:102112518831:image"
      ca-central-1   = "arn:aws:sagemaker:ca-central-1:310906938811:image"
      eu-central-1   = "arn:aws:sagemaker:eu-central-1:936697816551:image"
      eu-west-1      = "arn:aws:sagemaker:eu-west-1:470317259841:image"
      eu-west-2      = "arn:aws:sagemaker:eu-west-2:712779665605:image"
      eu-west-3      = "arn:aws:sagemaker:eu-west-3:615547856133:image"
      eu-north-1     = "arn:aws:sagemaker:eu-north-1:243637512696:image"
      eu-south-1     = "arn:aws:sagemaker:eu-south-1:592751261982:image"
      sa-east-1      = "arn:aws:sagemaker:sa-east-1:782484402741:image"
      cn-north-1     = "arn:aws-cn:sagemaker:cn-north-1:390048526115:image"
      cn-northwest-1 = "arn:aws-cn:sagemaker:cn-northwest-1:390780980154:image"
    }
  }

  sagemaker_image_arn_prefix = lookup(local.sagemaker.image_arn_prefixes, data.aws_region.current.name, "us-east-1")

  sagemaker_image_arn = "${local.sagemaker_image_arn_prefix}/${local.sagemaker.jupyter_image_tag}"
}
