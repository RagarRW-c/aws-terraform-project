## arch.

+---------------------------------------------+
| AWS VPC (10.0.0.0/16)                      | 
| +------------------+   +-----------------+ | 
| | Public Subnet    |   | Private Subnet  | | 
| |   +-----------+  |   | +----------+    | | 
| |   |   EC2     |--+--▶|  RDS      |    | |  
| |   | (Nginx)   |  |   |PostgreSQL|    | |   
| |   +-----------+  |   +----------+    | |   
| +------------------+   +-----------------+ | 
+---------------------------------------------+

aws-terraform-project/
├── .github/
│ └── workflows/
│ └── terraform.yml # GitHub Actions CI/CD
├── terraform/
│ ├── main.tf # Główna konfiguracja Terraform
│ ├── variables.tf # Definicje zmiennych
│ ├── outputs.tf # Outputy
│ └── terraform.tfvars.example # Przykładowe wartości zmiennych
├── scripts/
│ └── user_data.sh # Skrypt inicjalizacyjny EC2
└── README.md