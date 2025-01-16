locals {
    name = "sense"

    # Network
    vpc_id = "vpc-0fb129782439ef273" # ace-healthcare

    subnet_ids = [
        "subnet-0250a2149108261b0", # app-0,
        "subnet-0ed1a47931daad75e", # app-1
    ]

    db_subnet_ids = [
        "subnet-09d55d68e1ccebf0e", # db-0
        "subnet-004c8611827823923", # db-1
    ]

    service_subnets = local.subnet_ids

    chat = {
        image = "975050287646.dkr.ecr.ap-southeast-1.amazonaws.com/ace-healthcare/data-copilot/main:v2.0.5-prd"
    }

    admin = {
        image = "975050287646.dkr.ecr.ap-southeast-1.amazonaws.com/ace-healthcare/data-copilot/admin:v1.1.9-prd"
    }

    rds = {
        subnet_ids = local.db_subnet_ids
    }

    elasticache = {
        vpc_id = local.vpc_id
        subnet_ids = local.db_subnet_ids
    }

    cluster_name = "ace-healthcare-dev-cluster"
    cluster_arn  = "arn:aws:ecs:ap-southeast-1:533267256939:cluster/${local.cluster_name}"

    chat_secret_arn = "arn:aws:secretsmanager:ap-southeast-1:533267256939:secret:ace-healthcare/dev/metabase/test/init-MeJnnY"
    admin_secret_arn = "arn:aws:secretsmanager:ap-southeast-1:533267256939:secret:ace-healthcare/dev/metabase/test/init-MeJnnY"
    metabase_secret_arn = "arn:aws:secretsmanager:ap-southeast-1:533267256939:secret:ace-healthcare/dev/metabase/test/init-MeJnnY"
    langfuse_secret_arn = "arn:aws:secretsmanager:ap-southeast-1:533267256939:secret:ace-healthcare/dev/metabase/test/init-MeJnnY"
    kms_arn = "arn:aws:kms:ap-southeast-1:533267256939:key/4937b34e-ecca-4a20-8e16-6e0eb5e8ccda"
    langfuse_domain_name = "sense-test-langfuse.healthtech.works"
    cognito_domain = "ace-healthcare-dev-metabase.auth.ap-southeast-1.amazoncognito.com"
}

module "ecs_service_chat" {
    source  = "terraform-aws-modules/ecs/aws//modules/service"
    version = "5.8.0"

    name        = "${try(local.name, "sense")}-chat"
    subnet_ids  = try(local.service_subnets, [])
    cluster_arn = try(local.cluster_arn, "")
    enable_execute_command = true

    task_exec_iam_statements = {
        kms = {
            sid       = "KMS"
            actions   = ["kms:Decrypt"]
            resources = [local.kms_arn]
        }
    }

    container_definitions = {
        main = {
            essential = true
            image = try(local.chat.image, "")
            port_mappings = [
                {
                    appProtocol   = "http"
                    name          = "streamlit-tcp"
                    containerPort = 8051
                    hostPort      = 8051
                    protocol      = "tcp"
                }
            ]
            environment = [
                {
                    name  = "ACTIVE_COPILOT"
                    value = "metabase"
                },
                {
                    name  = "CHAINLIT_RANDOM_SECRET"
                    value = "true"
                },
                {
                    name  = "CHAINLIT_URL"
                    value = "https://sense-test.healthtech.works"
                },
                {
                    name  = "DEPLOYMENT_MODE",
                    value = "production"
                },
                {
                    name  = "ENVIRONMENT",
                    value = "prd"
                },
                {
                    name  = "LANGFUSE_HOST"
                    value = "http://sense-langfuse:3000"
                },
                {
                    name  = "METABASE_URL"
                    value = "http://sense-metabase:3000"
                },
                {
                    name  = "METABASE_HTTP_TIMEOUT"
                    value = "300"
                },
                {
                    name  = "OPENAI_API_VERSION"
                    value = "2023-09-01-preview"
                },
                {
                    name  = "OPENAI_API_BASE"
                    value = "http://litellm:4000"
                },
                {
                    name  = "OAUTH_COGNITO_CLIENT_ID",
                    value = "7d3dvft8nhglo23ib10fcmtim6"
                },
                {
                    name  = "OAUTH_COGNITO_DOMAIN",
                    value = "ace-healthcare-dev-metabase.auth.ap-southeast-1.amazoncognito.com"
                },
                {
                    name  = "ENABLED_CRON",
                    value = "true"
                },
                {
                    name  = "DEFAULT_LLM",
                    value = "gpt-4o"
                },
                {
                    name  = "RATE_LIMIT_ENABLED",
                    value = "true"
                },
                {
                    name  = "RATE_LIMIT_INTERVAL",
                    value = "300"
                },
                {
                    name  = "RATE_LIMIT_COUNT",
                    value = "16"
                },
                {
                    name  = "DB_WHITELIST_PROVIDER",
                    value = "SenseAdminAuthorizationProvider"
                },
                {
                    name  = "SENSE_ADMIN_BASE_URL",
                    value = "http://sense-admin:8051"
                },
                {
                    name = "LANGFUSE_PUBLIC_KEY",
                    value = "pk-lf-11ca795d-3409-4f20-a013-afcba41f363e"
                }
            ]
            secrets = [
                {
                    name = "CHAINLIT_AUTH_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "CHAINLIT_AUTH_SECRET"
                    )
                },
                {
                    name = "LANGFUSE_SECRET_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "LANGFUSE_SECRET_KEY"
                    )
                },
                {
                    name = "OAUTH_COGNITO_CLIENT_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "AUTH_AWS_COGNITO_CLIENT_SECRET"
                    )
                },
                {
                    name = "METABASE_API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "CHAT_METABASE_API_KEY"
                    )
                },
                {
                    name = "OPENAI_API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "OPENAI_API_KEY"
                    )
                },
                {
                    name = "SENSE_ADMIN_API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.chat_secret_arn,
                        "API_KEY"
                    )
                }
            ]
            readonly_root_filesystem = false
        }
    }

    load_balancer = {
        main = {
            target_group_arn = "arn:aws:elasticloadbalancing:ap-southeast-1:533267256939:targetgroup/althcare-dev-metabase-sense-test/435e304d28904680"
            container_name   = "main"
            container_port   = 8051
        }
    }

    security_group_rules = {
        alb_ingress_8051 = {
            type        = "ingress"
            from_port   = 8051
            to_port     = 8051
            protocol    = "tcp"
            description = "Ingress to 8051"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    service_connect_configuration = {
        namespace = "ace-healthcare"
        service = {
            client_alias = {
                port     = 8051
                dns_name = "${try(local.name, "sense")}-chat"
            }
            port_name      = "streamlit-tcp"
            discovery_name = "${try(local.name, "sense")}-chat"
        }
    }

    volume = []
}

module "ecs_service_admin" {
    source  = "terraform-aws-modules/ecs/aws//modules/service"
    version = "5.8.0"

    name        = "${try(local.name, "sense")}-admin"
    subnet_ids  = try(local.service_subnets, [])
    cluster_arn = try(local.cluster_arn, "")

    task_exec_iam_statements = {
        kms = {
            sid       = "KMS"
            actions   = ["kms:Decrypt"]
            resources = [local.kms_arn]
        }
    }

    container_definitions = {
        main = {
            essential = true
            image = try(local.admin.image, "")
            port_mappings = [
                {
                    name          = "http"
                    containerPort = 8051
                    hostPort      = 8051
                    protocol      = "tcp"
                }
            ]
            environment = [
                {
                    name  = "NODE_ENV"
                    value = "production"
                },
                {
                    name  = "LOG_LEVEL"
                    value = "error"
                },
                {
                    name  = "APP_HOST"
                    value = "0.0.0.0"
                },
                {
                    name  = "APP_PORT"
                    value = "8051"
                },
                {
                    name  = "METABASE_URL"
                    value = "http://sense-metabase:3000"
                },
                {
                    name  = "OAUTH2_CLIENT_ID"
                    value = "7d3dvft8nhglo23ib10fcmtim6"
                },
                {
                    name  = "OAUTH2_AUTH_URL"
                    value = "https://${local.cognito_domain}/oauth2/authorize"
                },
                {
                    name  = "OAUTH2_TOKEN_URL"
                    value = "https://${local.cognito_domain}/oauth2/token"
                },
                {
                    name  = "OAUTH2_LOGOUT_URL"
                    value = "https://${local.cognito_domain}/logout"
                },
                {
                    name  = "OAUTH2_CALLBACK_URL"
                    value = "https://sense-test-admin.healthtech.works/auth/oauth/aws-cognito/callback"
                },
                {
                    name  = "OAUTH2_LOGOUT_CALLBACK_URL"
                    value = "https://sense-test-admin.healthtech.works/auth/oauth/aws-cognito/logout"
                },
                {
                    name  = "OAUTH2_JWKS_URL"
                    value = "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_hL8Y1wWoo/.well-known/jwks.json"
                },
            ]
            secrets = [
                {
                    name = "DATABASE_URL",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "SENSE_ADMIN_DATABASE_URL"
                    )
                },
                {
                    name = "ADMIN_JS_RELATIONS_LICENSE_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "ADMIN_JS_RELATIONS_LICENSE_KEY"
                    )
                },
                {
                    name = "METABASE_API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "METABASE_API_KEY"
                    )
                },
                {
                    name = "COOKIE_PASSWORD",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "COOKIE_PASSWORD"
                    )
                },
                {
                    name = "OAUTH2_CLIENT_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "AUTH_AWS_COGNITO_CLIENT_SECRET"
                    )
                },
                {
                    name = "API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "API_KEY"
                    )
                },
                {
                    name = "REDIS_URL",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "REDIS_URL"
                    )
                },
                {
                    name = "SESSION_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "SESSION_SECRET"
                    )
                },
            ]

            readonly_root_filesystem = false
        }
    }

    service_connect_configuration = {
        namespace = "ace-healthcare"
        service = {
            client_alias = {
                port     = 8051
                dns_name = "${try(local.name, "sense")}-admin"
            }
            port_name      = "http"
            discovery_name = "${try(local.name, "sense")}-admin"
        }
    }

    load_balancer = {
        main = {
            target_group_arn = "arn:aws:elasticloadbalancing:ap-southeast-1:533267256939:targetgroup/re-dev-metabase-sense-test-admin/3c708e9aa2854a11"
            container_name   = "main"
            container_port   = 8051
        }
    }

    security_group_rules = {
        alb_ingress_8051 = {
            type        = "ingress"
            from_port   = 8051
            to_port     = 8051
            protocol    = "tcp"
            description = "Ingress to Sense Admin"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    volume = []
}

module "ecs_task_admin_db_migrate" {
    source  = "terraform-aws-modules/ecs/aws//modules/service"
    version = "5.8.0"

    name        = "${try(local.name, "sense")}-admin-db-migrate"
    subnet_ids  = try(local.service_subnets, [])
    cluster_arn = try(local.cluster_arn, "")

    # Never deploy on its own
    desired_count            = 0
    autoscaling_min_capacity = 0
    autoscaling_max_capacity = 0
    enable_autoscaling       = false

    task_exec_iam_statements = {
        kms = {
            sid       = "KMS"
            actions   = ["kms:Decrypt"]
            resources = [local.kms_arn]
        }
    }

    container_definitions = {
        main = {
            essential = true
            image = try(local.admin.image, "")
            entrypoint = ["npx", "prisma", "migrate", "deploy"]
            environment = [
                {
                    name  = "NODE_ENV"
                    value = "production"
                },
                {
                    name  = "LOG_LEVEL"
                    value = "error"
                },
                {
                    name  = "APP_HOST"
                    value = "0.0.0.0"
                },
                {
                    name  = "APP_PORT"
                    value = "8051"
                },
                {
                    name  = "METABASE_URL"
                    value = "http://sense-metabase:3000"
                },
                {
                    name  = "OAUTH2_CLIENT_ID"
                    value = "7d3dvft8nhglo23ib10fcmtim6"
                },
                {
                    name  = "OAUTH2_AUTH_URL"
                    value = "https://${local.cognito_domain}/oauth2/authorize"
                },
                {
                    name  = "OAUTH2_TOKEN_URL"
                    value = "https://${local.cognito_domain}/oauth2/token"
                },
                {
                    name  = "OAUTH2_LOGOUT_URL"
                    value = "https://${local.cognito_domain}/logout"
                },
                {
                    name  = "OAUTH2_CALLBACK_URL"
                    value = "https://sense-test-admin.healthtech.works/auth/oauth/aws-cognito/callback"
                },
                {
                    name  = "OAUTH2_LOGOUT_CALLBACK_URL"
                    value = "https://sense-test-admin.healthtech.works/auth/oauth/aws-cognito/logout"
                },
                {
                    name  = "OAUTH2_JWKS_URL"
                    value = "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_hL8Y1wWoo/.well-known/jwks.json"
                },
            ]
            secrets = [
                {
                    name = "DATABASE_URL",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "SENSE_ADMIN_DATABASE_URL"
                    )
                },
                {
                    name = "ADMIN_JS_RELATIONS_LICENSE_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "ADMIN_JS_RELATIONS_LICENSE_KEY"
                    )
                },
                {
                    name = "METABASE_API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "METABASE_API_KEY"
                    )
                },
                {
                    name = "COOKIE_PASSWORD",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "COOKIE_PASSWORD"
                    )
                },
                {
                    name = "OAUTH2_CLIENT_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "AUTH_AWS_COGNITO_CLIENT_SECRET"
                    )
                },
                {
                    name = "API_KEY",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "API_KEY"
                    )
                },
                {
                    name = "REDIS_URL",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "REDIS_URL"
                    )
                },
                {
                    name = "SESSION_SECRET",
                    valueFrom = format(
                        "%s:%s::",
                        local.admin_secret_arn,
                        "SESSION_SECRET"
                    )
                },
            ]

            readonly_root_filesystem = false
        }
    }

    service_connect_configuration = {
        namespace = "ace-healthcare"
    }

    security_group_rules = {
        alb_ingress_8051 = {
            type        = "ingress"
            from_port   = 8051
            to_port     = 8051
            protocol    = "tcp"
            description = "Ingress to Sense Admin"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    volume = []
}

module "ecs_service_metabase" {
    source  = "terraform-aws-modules/ecs/aws//modules/service"
    version = "5.8.0"

    name        = "${try(local.name, "sense")}-metabase"
    subnet_ids  = try(local.service_subnets, [])
    cluster_arn = try(local.cluster_arn, "")

    cpu    = 2048
    memory = 4096

    task_exec_iam_statements = {
        kms = {
            sid       = "KMS"
            actions   = ["kms:Decrypt"]
            resources = [local.kms_arn]
        }
    }

    container_definitions = {
        main = {
            essential = true
            image = "975050287646.dkr.ecr.ap-southeast-1.amazonaws.com/ace-healthcare/data-copilot/metabase:v0.49.2"
            port_mappings = [
                {
                    name          = "http"
                    containerPort = 3000
                    hostPort      = 3000
                    protocol      = "tcp"
                }
            ]
            environment = [
                {
                    name  = "MB_DB_TYPE"
                    value = "postgres"
                },
                {
                    name  = "MB_DB_DBNAME"
                    value = "metabase"
                },
                {
                    name  = "MB_DB_PORT"
                    value = module.rds.db_instance_port
                },
                {
                    name  = "MB_DB_HOST"
                    value = module.rds.db_instance_address
                },
                {
                    name  = "MB_DB_USER"
                    value = "metabase"
                },
            ]
            secrets = [
                {
                    name      = "MB_DB_PASS",
                    valueFrom = format(
                        "%s:%s::",
                        local.metabase_secret_arn,
                        "METABASE_DB_PASSWORD"
                    )
                }
            ]
            readonly_root_filesystem = false
        }
    }

    security_group_rules = {
        alb_ingress_3000 = {
            type        = "ingress"
            from_port   = 3000
            to_port     = 3000
            protocol    = "tcp"
            description = "Ingress to Metabase"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    load_balancer = {
        main = {
            target_group_arn = "arn:aws:elasticloadbalancing:ap-southeast-1:533267256939:targetgroup/dev-metabase-sense-test-metabase/1e539991fd19bd6a"
            container_name   = "main"
            container_port   = 3000
        }
    }

    service_connect_configuration = {
        namespace = "ace-healthcare"
        service = {
            client_alias = {
                port     = 3000
                dns_name = "${try(local.name, "sense")}-metabase"
            }
            port_name      = "http"
            discovery_name = "${try(local.name, "sense")}-metabase"
        }
    }

    volume = []
}

module "ecs_service_langfuse" {
    source  = "terraform-aws-modules/ecs/aws//modules/service"
    version = "5.8.0"

    name        = "${try(local.name, "sense")}-langfuse"
    subnet_ids  = try(local.service_subnets, [])
    cluster_arn = try(local.cluster_arn, "")

    task_exec_iam_statements = {
        kms = {
            sid       = "KMS"
            actions   = ["kms:Decrypt"]
            resources = [local.kms_arn]
        }
    }

    container_definitions = {
        main = {
            essential = true
            image = "975050287646.dkr.ecr.ap-southeast-1.amazonaws.com/ace-healthcare/data-copilot/langfuse:2.55.1"
            port_mappings = [
                {
                    name          = "http"
                    hostPort      = 3000
                    containerPort = 3000
                    protocol      = "tcp"
                }
            ]
            environment = [
                {
                    name  = "DATABASE_NAME"
                    value = "langfuse"
                },
                {
                    name  = "DATABASE_HOST"
                    value = module.rds.db_instance_address
                },
                {
                    name      = "DATABASE_USERNAME",
                    value = "langfuse"
                },
                {
                    name  = "NEXTAUTH_URL",
                    value = "https://${local.langfuse_domain_name}/"
                },
                {
                    name  = "HOSTNAME",
                    value = "0.0.0.0"
                },
#                 {
#                   name = "NEXT_PUBLIC_SIGN_UP_DISABLED",
#                   value = "true"
#                 },
                {
                    name  = "AUTH_COGNITO_CLIENT_ID",
                    value = "7d3dvft8nhglo23ib10fcmtim6"
                },
                {
                    name  = "AUTH_COGNITO_ISSUER",
                    value = "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_hL8Y1wWoo"
                },
                {
                    name  = "AUTH_COGNITO_ALLOW_ACCOUNT_LINKING",
                    value = "true"
                },
                {
                    name  = "OPENAI_API_BASE",
                    value = "https://api-llms.healthtech.works/"
                }
            ]
            secrets = [
                {
                    name      = "DATABASE_PASSWORD",
                    valueFrom = format("%s:LANGFUSE_DB_PASSWORD::", local.langfuse_secret_arn)
                },
                {
                    # openssl rand -base64 32 | pbcopy
                    name      = "NEXTAUTH_SECRET",
                    valueFrom = format("%s:NEXTAUTH_SECRET::", local.langfuse_secret_arn)
                },
                {
                    # openssl rand -base64 32 | pbcopy
                    name      = "SALT",
                    valueFrom = format("%s:SALT::", local.langfuse_secret_arn)
                },
                {
                    name      = "AUTH_COGNITO_CLIENT_SECRET",
                    valueFrom = format("%s:AUTH_AWS_COGNITO_CLIENT_SECRET::", local.langfuse_secret_arn)
                },
            ]
            readonly_root_filesystem = false
        }
    }

    load_balancer = {
        main = {
            target_group_arn = "arn:aws:elasticloadbalancing:ap-southeast-1:533267256939:targetgroup/dev-metabase-sense-test-langfuse/3dd6ebc860706a49"
            container_name   = "main"
            container_port   = 3000
        }
    }

    security_group_rules = {
        alb_ingress_3000 = {
            type        = "ingress"
            from_port   = 3000
            to_port     = 3000
            protocol    = "tcp"
            description = "Ingress to Langfuse"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
            type        = "egress"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    service_connect_configuration = {
        namespace = "ace-healthcare"
        service = {
            client_alias = {
                port     = 3000
                dns_name = "${try(local.name, "sense")}-langfuse"
            }
            port_name      = "http"
            discovery_name = "${try(local.name, "sense")}-langfuse"
        }
    }

    volume = []
}

module "rds" {
    source  = "terraform-aws-modules/rds/aws"
    version = "6.3.0"

    identifier        = try(local.name, "sense")
    instance_class    = try(local.rds.instance_class, "db.t4g.micro")
    engine            = try(local.rds.engine, "postgres")
    engine_version    = try(local.rds.engine_version, "16")
    family            = try(local.rds.family, "postgres16")
    allocated_storage = try(local.rds.allocated_storage, 100)
    create_db_subnet_group = try(local.rds.create_db_subnet_group, true)
    subnet_ids        = try(local.rds.subnet_ids, [])
    username = try(local.rds.username, "sense")
    vpc_security_group_ids = [module.rds_security_group.security_group_id]
}

module "rds_security_group" {
    source  = "terraform-aws-modules/security-group/aws"
    version = "5.2.0"

    name        = try(local.name, "sense-rds")
    vpc_id = try(local.elasticache.vpc_id, null)

    ingress_with_source_security_group_id = [
        {
            rule                     = "postgresql-tcp"
            source_security_group_id = module.ecs_service_admin.security_group_id
        },
        {
            rule                     = "postgresql-tcp"
            source_security_group_id = module.ecs_service_metabase.security_group_id
        },
        {
            rule                     = "postgresql-tcp"
            source_security_group_id = module.ecs_service_langfuse.security_group_id
        },
        {
            rule                     = "postgresql-tcp"
            source_security_group_id = module.ecs_task_admin_db_migrate.security_group_id
        },
        {
            rule                     = "postgresql-tcp"
            source_security_group_id = "sg-024fb751cbc92324f" # Debug
        }
    ]
}

module "elasticache" {
    source  = "terraform-aws-modules/elasticache/aws"
    version = "1.2.2"

    cluster_id               = try(local.name, "sense")
    engine                   = try(local.elasticache.engine, "redis")
    create_replication_group = try(local.elasticache.create_replication_group, false)
    vpc_id = try(local.elasticache.vpc_id, [])
    subnet_ids               = try(local.elasticache.subnet_ids, [])
}
