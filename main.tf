provider "aws" {
  region = "ap-southeast-1"
}

# Create CodeCommit Repository
resource "aws_codecommit_repository" "repo" {
  repository_name = "my-app-repo"
  description     = "CodeCommit repository for my app"
}

# Create S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "my-app-codepipeline-artifacts"
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodePipeline Setup
resource "aws_codepipeline" "pipeline" {
  name     = "my-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = aws_codecommit_repository.repo.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }
}

# CodeBuild Project
resource "aws_codebuild_project" "build_project" {
  name          = "my-app-build"
  build_timeout = 30
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec.yml") # Add buildspec.yml
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  service_role = aws_iam_role.codepipeline_role.arn
}

# ECR Repository
resource "aws_ecr_repository" "repo" {
  name = "my-app-ecr"
}
