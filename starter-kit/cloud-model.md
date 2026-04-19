# Q. EXPLAIN WHETHER THE SYSTEM USES IAAS, PAAS or SAAS

## IAAS

```
IAAS the cloud provider supplies the basic computing infrastructure such as virtual machines, networking, and storage.

The engineering team is responsible for configuring and maintaining everything that runs on those machines.

```

## PAAS

```
Platform as a Service shifts a significant portion of infrastructure management to the cloud provider.

Instead of configuring servers directly, engineers deploy applications onto a managed runtime platform.

```

## SAAS

```
Software as a Service provides fully managed applications delivered through a web interface or API.

Users do not build or maintain the underlying infrastructure or application platform. Instead, they configure the software to support their workflow.

```
# Who Manages What

```

                    IaaS          PaaS          SaaS
                      
Your Application     YOU          YOU          THEM
Your Data            YOU          YOU          THEM
Runtime/Language     YOU          THEM         THEM
Operating System     YOU          THEM         THEM
Virtual Machine      YOU          THEM         THEM
Physical Server      THEM         THEM         THEM
Data Centre          THEM         THEM         THEM

```
# What I Wwould use for KijaniKiosk : A Hybrid IaaS + PaaS Approach
```
App Servers(IaaS) — Custom code needs custom control
Database  (PaaS) — Let the cloud manage backups and patching
File Storage  (PaaS) — Solved problem, no need to reinvent it
Load Balancer  (PaaS) — Reliable, scalable, zero maintenance
Email/SMS  (SaaS) — Completely outside KijaniKiosk's core business

```

