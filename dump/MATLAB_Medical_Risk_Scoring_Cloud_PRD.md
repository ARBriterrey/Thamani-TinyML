# Product Requirements Document (PRD)

## MATLAB-Based Medical Risk Scoring Cloud Platform

Version: 1.0\
Region: India (Data Residency Required)\
Author: Andhan Rahul Buddhan

------------------------------------------------------------------------

# 1. Executive Summary

This document defines the requirements for a secure, scalable, and
compliant hub-and-spoke medical data processing system. The system
receives raw physiological sensor data from distributed clinical devices
(spokes), processes the data using MATLAB-based algorithms, and
generates a clinically correlated risk score via centralized cloud
infrastructure (hub).

The solution must: - Support parallel data processing - Maintain strict
medical data compliance - Ensure data residency within India - Be
scalable and cost-efficient - Support future regulatory classification
as Software as a Medical Device (SaMD)

------------------------------------------------------------------------

# 2. Problem Statement

Clinical environments generate raw sensor data that requires
computational processing to derive actionable risk scores. Currently,
processing occurs in MATLAB environments that are not scalable,
cloud-native, or production-ready.

We need: - A containerized, deployable processing engine - A secure
ingestion pipeline - Parallel compute capability - Auditability and
compliance readiness

------------------------------------------------------------------------

# 3. Product Goals

1.  Containerize existing MATLAB code.
2.  Enable parallel processing using container-level scaling.
3.  Ensure medical-grade data security.
4.  Deploy in India-based cloud infrastructure.
5.  Maintain cost control while enabling future scale.
6.  Prepare for potential medical regulatory pathways.

------------------------------------------------------------------------

# 4. Functional Requirements

## 4.1 Data Ingestion

-   Accept raw sensor data via secure API (HTTPS, TLS 1.2+).
-   Support JSON and binary payload formats.
-   Validate payload integrity.
-   Log ingestion metadata.

## 4.2 Processing Engine

-   MATLAB code compiled using MATLAB Compiler.
-   Deployed via MATLAB Runtime (MCR).
-   Executable packaged inside Docker container.
-   Stateless processing model.
-   Output: structured risk score JSON.

## 4.3 Parallel Processing

-   Each incoming job queued.
-   Worker containers scale horizontally.
-   Orchestration via Kubernetes or AWS ECS.
-   Auto-scaling based on queue depth.

## 4.4 Data Storage

-   Encrypted at rest (AES-256).
-   Region-locked to India.
-   Separate storage for:
    -   Raw data
    -   Processed results
    -   Logs

## 4.5 Reporting Layer

-   REST API for retrieving processed results.
-   Role-based access control.
-   Audit logging enabled.

------------------------------------------------------------------------

# 5. Non-Functional Requirements

## 5.1 Security

-   TLS encryption in transit.
-   Encryption at rest.
-   Role-Based Access Control (RBAC).
-   Zero-trust architecture principles.
-   Audit trail retention (minimum 5 years).

## 5.2 Compliance

-   Adherence to India DPDP Act.
-   Data residency locked to Indian region.
-   HIPAA-aligned architecture (if future expansion required).
-   SaMD readiness documentation.

## 5.3 Performance

-   Processing latency target: \< 30 seconds per dataset.
-   System uptime target: 99.5%+.
-   Horizontal scalability.

## 5.4 Reliability

-   Automatic container restart.
-   Health checks.
-   Centralized logging.

------------------------------------------------------------------------

# 6. System Architecture

## 6.1 High-Level Architecture

Sensors (Hospitals)\
→ Secure API Gateway\
→ Message Queue (RabbitMQ / SQS)\
→ Scalable MATLAB Runtime Worker Containers\
→ Encrypted Database\
→ Clinical Dashboard / API

## 6.2 Deployment Options

### Option A: India-Based Cloud (Recommended)

-   AWS Mumbai
-   Azure India Central
-   GCP Mumbai

### Option B: On-Prem Hospital Deployment

-   Docker runtime within hospital network
-   Local compute cluster

------------------------------------------------------------------------

# 7. Licensing Requirements

## Required Licenses

-   MATLAB Developer License
-   MATLAB Compiler License

## Not Required

-   Per-server MATLAB license
-   MATLAB Runtime license (free for deployment)

## Optional

-   Parallel Computing Toolbox (not recommended initially)
-   MATLAB Parallel Server (enterprise only)

------------------------------------------------------------------------

# 8. Cost Estimates

## One-Time Costs (Approximate)

-   MATLAB Licenses: ₹2L -- ₹5L
-   DevOps Setup: ₹1.5L -- ₹5L
-   Compliance Consultation: ₹2L -- ₹10L

Estimated Initial Investment: ₹3L -- ₹15L (lean to enterprise)

## Monthly Recurring Costs

-   Compute Instances: ₹10k -- ₹40k
-   Storage: ₹3k -- ₹10k
-   Load Balancer: ₹2k -- ₹5k
-   Monitoring: ₹2k -- ₹5k

Estimated Monthly: ₹20k -- ₹60k (scales with load)

------------------------------------------------------------------------

# 9. Regulatory Considerations

This system may qualify as Software as a Medical Device (SaMD) if:

-   Risk score influences clinical decision-making.
-   Used for diagnostic or prognostic support.

Future requirements may include: - Clinical validation studies - ISO
13485 compliance - CDSCO registration - Risk management documentation

------------------------------------------------------------------------

# 10. Future Roadmap

Phase 1: - Containerization and MVP deployment.

Phase 2: - Auto-scaling and performance optimization.

Phase 3: - Regulatory documentation preparation.

Phase 4: - Potential migration from MATLAB to Python for cost
optimization.

------------------------------------------------------------------------

# 11. Risks

-   Regulatory reclassification risk.
-   Vendor lock-in to MATLAB ecosystem.
-   Cloud cost escalation with high usage.
-   Data breach liability exposure.

Mitigation: - Modular architecture. - Replaceable compute layer. -
Strong encryption and logging. - Periodic compliance audits.

------------------------------------------------------------------------

# 12. Success Metrics

-   Successful parallel processing under load.
-   \< 30s average compute latency.
-   99.5% uptime.
-   Zero compliance violations.
-   Cost per processed dataset within target budget.

------------------------------------------------------------------------

# End of Document
