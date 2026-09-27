# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A small Terraform learning project that builds AWS networking as a foundation for ECS. There is no application code, test suite, or CI — only flat `.tf` files in the repo root (single root module, no child modules). State is local (no backend configured).

## Commands

```bash
terraform init              # install providers (hashicorp/aws ~> 6.0; Terraform >= 1.3)
terraform fmt -recursive    # format
terraform validate          # static check
terraform plan -out=tfplan  # `**_plan` is gitignored, so name plan files e.g. `dev_plan`, not `tfplan`
terraform apply
terraform destroy
```

AWS auth uses the named profile in `var.running_profile` (default `admin-sso`, an SSO profile), so run `aws sso login --profile admin-sso` first, or override with `-var running_profile=<profile>`.

## Architecture

The layout is conventional: `terraform.tf` (provider/versions), `variables.tf`, `main.tf` (resources), `output.tf`.

`main.tf` currently defines a VPC, two public and two private subnets, an internet gateway, and a public route table associated with the public subnets. The private subnets have no route table, NAT gateway, or egress yet. No ECS resources exist yet.

Things that span files and are easy to miss:

- **Subnets are index-paired with AZs.** Both subnet resources use `count = length(<cidrs>)` and pick `var.azs[count.index]`. The `azs`, `public_subnet_cidrs`, and `private_subnet_cidrs` lists must stay aligned and at least as long as the CIDR lists, or `plan` fails with an index error.
- **Region is hardcoded in the provider block** (`terraform.tf` uses `"eu-west-2"`), so `var.aws_region` is declared but unused. The default `azs` are also `eu-west-2` zones. Changing region means editing both.
- **Every resource is tagged** with `Name = "${var.project_name}-<thing>"` and `Creator = var.creator_tag`; subnets also get a `Tier` tag (`public`/`private`). Follow this for new resources.
- `var.ec2_instance_type` is declared but not yet used by any resource.
- `.gitignore` excludes `.terraform/`, all `*.hcl` files (including `.terraform.lock.hcl`, so the provider lock file is not committed), and `*_plan` files.
