terraform {
  backend "s3" {
    bucket = "api-lambda-09112024"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
