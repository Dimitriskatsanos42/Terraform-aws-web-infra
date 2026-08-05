
# Terraform Cloud Infrastructure Project

Επαγγελματικό, **modular** Terraform project που στήνει web infrastructure στο AWS:

- **VPC** με public/private subnets σε 2 Availability Zones
- **NAT Gateway** για internet access από τα private subnets
- **Application Load Balancer** (public) που δρομολογεί traffic
- **Auto Scaling Group** με EC2 instances (private subnets, ασφαλή)
- **Remote state** στο S3 με locking μέσω DynamoDB
- **CI/CD** με GitHub Actions: `plan` σε κάθε PR, `apply` αυτόματα στο `dev` όταν γίνεται merge στο `main`, και `apply` στο `prod` με manual approval

## Αρχιτεκτονική

```
Internet
   │
   ▼
[ALB - public subnets] ──► [Target Group]
                                 │
                                 ▼
                  [Auto Scaling Group - private subnets]
                          EC2 instances (Apache)
                                 │
                                 ▼
                          [NAT Gateway] ──► Internet (outbound only)
```

## Δομή project

```
.
├── modules/
│   ├── vpc/       # VPC, subnets, routing, NAT
│   ├── alb/       # Load Balancer, Target Group, listener
│   └── ec2/       # Launch Template, Auto Scaling Group
├── environments/
│   ├── dev/       # μικρό sizing, δικό του state
│   └── prod/      # μεγαλύτερο sizing, δικό του state
├── bootstrap/
│   └── bootstrap.sh   # δημιουργεί το S3 bucket + DynamoDB table για state
└── .github/workflows/
    └── terraform.yml  # CI/CD pipeline
```

## Προαπαιτούμενα

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) ρυθμισμένο (`aws configure`)
- Λογαριασμός AWS με δικαιώματα να δημιουργεί VPC/EC2/ALB/S3/DynamoDB

## Βήμα 1: Bootstrap remote state (μία φορά)

```bash
cd bootstrap
chmod +x bootstrap.sh
./bootstrap.sh myapp-terraform-state-<κάτι-μοναδικό> eu-central-1
```

Μετά, ενημέρωσε το `bucket` στα:
- `environments/dev/backend.tf`
- `environments/prod/backend.tf`

## Βήμα 2: Τοπική εκτέλεση (dev)

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

Στο τέλος θα πάρεις `alb_dns_name` — αυτό είναι το URL του website σου.

## Βήμα 3: Καθαρισμός (για να μη χρεώνεσαι)

```bash
terraform destroy
```

## CI/CD με GitHub Actions

1. Ανέβασε το repo στο GitHub.
2. Πήγαινε στο **Settings → Secrets and variables → Actions** και πρόσθεσε:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. (Προαιρετικά αλλά συνιστάται) Στο **Settings → Environments**, δημιούργησε environment `prod` και βάλε "Required reviewers" ώστε το `apply` στο prod να χρειάζεται manual approval.
4. Κάθε Pull Request θα τρέχει αυτόματα `terraform plan`.
5. Κάθε merge στο `main` θα κάνει `apply` στο dev, και μετά (με approval) στο prod.

## Σημαντικές σημειώσεις ασφαλείας

- Ποτέ μην κάνεις commit `.tfstate` ή `.tfvars` με μυστικά (καλύπτεται από `.gitignore`).
- Χρησιμοποίησε IAM user με το ελάχιστο δυνατό δικαίωμα (least privilege), όχι root credentials.
- Σκέψου να χρησιμοποιήσεις [OIDC federation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) αντί για static AWS keys στο GitHub Actions, για ακόμα καλύτερη ασφάλεια.

## Επόμενα βήματα / ιδέες επέκτασης

- HTTPS με ACM certificate + Route53 domain
- WAF μπροστά από το ALB
- CloudWatch alarms + SNS notifications
- Terraform Cloud/Terragrunt για ακόμα καλύτερο περιβαλλοντικό management
- Containerized deployment (ECS/Fargate) αντί για EC2
