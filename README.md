Projekt automatyzacji infrastruktury AWS z wykorzystaniem Terraform i GitHub Actions.
📋 Opis
Ten projekt tworzy kompletną infrastrukturę AWS zawierającą:

VPC z publicznymi i prywatnymi podsieciami
EC2 - serwer webowy z Nginx
RDS - baza danych PostgreSQL
Security Groups - odpowiednia konfiguracja bezpieczeństwa
CI/CD - automatyczne wdrożenie przez GitHub Actions

🏗️ Architektura
┌─────────────────────────────────────────────┐
│              AWS VPC (10.0.0.0/16)          │
│                                             │
│  ┌──────────────────┐  ┌─────────────────┐ │
│  │  Public Subnet   │  │ Private Subnet  │ │
│  │                  │  │                 │ │
│  │  ┌───────────┐   │  │  ┌──────────┐  │ │
│  │  │    EC2    │   │  │  │   RDS    │  │ │
│  │  │  (Nginx)  │───┼──┼─▶│PostgreSQL│  │ │
│  │  └───────────┘   │  │  └──────────┘  │ │
│  │       :80        │  │     :5432      │ │
│  └──────────────────┘  └─────────────────┘ │
│           │                                 │
└───────────┼─────────────────────────────────┘
            │
      Internet Gateway
            │
        🌐 Internet
📁 Struktura projektu
aws-terraform-project/
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions CI/CD
├── terraform/
│   ├── main.tf                    # Główna konfiguracja Terraform
│   ├── variables.tf               # Definicje zmiennych
│   ├── outputs.tf                 # Outputy
│   └── terraform.tfvars.example   # Przykładowe wartości zmiennych
├── scripts/
│   └── user_data.sh              # Skrypt inicjalizacyjny EC2
└── README.md