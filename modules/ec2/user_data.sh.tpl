#!/bin/bash
dnf install -y httpd
systemctl enable httpd
systemctl start httpd

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="el">
<head>
  <meta charset="UTF-8">
  <title>${project_name}</title>
  <style>
    body { font-family: sans-serif; background: #0f172a; color: #e2e8f0; text-align: center; padding-top: 15%; }
    h1 { color: #38bdf8; }
  </style>
</head>
<body>
  <h1>${project_name}</h1>
  <p>Server: $(hostname)</p>
  <p>Deployed με Terraform 🚀</p>
</body>
</html>
EOF
