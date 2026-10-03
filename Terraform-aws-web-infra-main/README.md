# AWS Web Infrastructure with Terraform

Terraform setup που στήνει ένα βασικό αλλά ρεαλιστικό web infrastructure στο AWS: load balancer μπροστά, τα instances πίσω σε private subnets, auto scaling ανάλογα με το load, και ξεχωριστά περιβάλλοντα για dev και prod.

Η ιδέα είναι να δείξει τον τυπικό τρόπο που στήνεται infrastructure σε production - modules, remote state, CI/CD - όχι ένα single-file demo.

## Πώς δουλεύει

Το κάθε request περνάει πρώτα από ένα Application Load Balancer, το οποίο βρίσκεται σε public subnets. Το ALB προωθεί το traffic σε ένα Auto Scaling Group με EC2 instances, τα οποία ζουν σε private subnets - δεν έχουν δηλαδή δημόσια IP και δεν είναι προσβάσιμα απευθείας από το internet. Η μόνη τους έξοδος προς τα έξω (π.χ. για updates) γίνεται μέσω ενός NAT Gateway.

Το Auto Scaling Group ανεβάζει ή κατεβάζει τον αριθμό των instances ανάλογα με το load, με min/max/desired capacity που ορίζονται ξεχωριστά ανά environment.

```
                 Internet
                    │
                    ▼
        ┌───────────────────────┐
        │   Load Balancer       │   (public subnets)
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Auto Scaling Group  │   (private subnets)
        │   EC2 instances       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   NAT Gateway          │   (outbound only)
        └───────────────────────┘
```

## Δομή

```
modules/
  vpc/       networking - subnets, routing, NAT gateway
  alb/       load balancer, target group, security group
  ec2/       launch template + auto scaling group

environments/
  dev/       μικρό sizing, δικό του state file
  prod/      μεγαλύτερο sizing, δικό του state file

bootstrap/
  bootstrap.sh   δημιουργεί το S3 bucket και το DynamoDB table που χρειάζεται το remote state
  oidc/          δημιουργεί τον IAM role που χρησιμοποιεί το GitHub Actions αντί για access keys

.github/workflows/
  terraform.yml  CI/CD pipeline
```

Τα modules είναι ξεχωριστά κομμάτια που μπορούν να επαναχρησιμοποιηθούν - το `environments/dev` και το `environments/prod` απλά τα καλούν με διαφορετικές παραμέτρους (μέγεθος VPC, αριθμό instances κλπ).

## Remote state

Το state δεν κρατιέται τοπικά, πάει σε S3 bucket με locking μέσω DynamoDB, ώστε να μπορεί να δουλέψει πάνω του πάνω από ένας άνθρωπος (ή το CI) χωρίς conflicts. Το bucket και το table φτιάχνονται μία φορά με το `bootstrap/bootstrap.sh`.

## Τρέξιμο τοπικά

Χρειάζεται Terraform >= 1.5 και AWS CLI ρυθμισμένο.

```bash
# μία φορά, δημιουργεί το backend για το state
cd bootstrap
./bootstrap.sh <όνομα-bucket> eu-central-1

# μετά ενημέρωσε το bucket name στα environments/dev/backend.tf
# και environments/prod/backend.tf

cd ../environments/dev
terraform init
terraform plan
terraform apply
```

Στο output θα εμφανιστεί το DNS name του load balancer - αυτό είναι το URL της εφαρμογής.

Για να αφαιρέσεις τα πάντα:

```bash
terraform destroy
```

## CI/CD

Το workflow κάνει `terraform plan` σε κάθε pull request, και `apply` αυτόματα στο dev όταν γίνεται merge στο main. Το prod environment έχει ξεχωριστό job που τρέχει μετά, και μπορεί να ρυθμιστεί ώστε να χρειάζεται manual approval πριν προχωρήσει (μέσω GitHub Environments με required reviewers).

Η σύνδεση με το AWS γίνεται μέσω **OIDC federation**, όχι με static access keys. Το GitHub Actions παίρνει προσωρινό token σε κάθε run και υποδύεται έναν IAM role - δεν αποθηκεύεται κανένα μόνιμο credential πουθενά.

Setup (μία φορά):

```bash
cd bootstrap/oidc
terraform init
terraform apply \
  -var="github_org=<το-github-username-σου>" \
  -var="github_repo=aws-vpc-alb-autoscaling-terraform"
```

Το output θα δώσει ένα `role_arn`. Αυτό πάει στο repository ως **variable** (όχι secret, αφού δεν είναι sensitive):

Settings → Secrets and variables → Actions → tab "Variables" → New repository variable
- Name: `AWS_ROLE_ARN`
- Value: το arn που πήρες

Αυτό είναι το μόνο που χρειάζεται - δεν υπάρχουν access keys να διαχειριστείς ή να κάνεις rotate.

## Σημειώσεις

- Τα state files και τα tfvars δεν ανεβαίνουν στο repo (βλέπε `.gitignore`) - μπορεί να περιέχουν sensitive δεδομένα.
- Το CI/CD δεν χρησιμοποιεί static AWS keys, μόνο OIDC role assumption (βλέπε `bootstrap/oidc`). Ο role είναι περιορισμένος ώστε να μπορεί να τον πάρει μόνο workflow από το συγκεκριμένο repo.
- Τα permissions στο `bootstrap/oidc/main.tf` είναι αρκετά ανοιχτά (full access σε EC2/VPC/ELB/ASG/S3/DynamoDB/IAM) για να δουλέψει άμεσα το project. Σε πραγματικό production θα τα περιόριζες περαιτέρω σε συγκεκριμένα resources/ARNs.
