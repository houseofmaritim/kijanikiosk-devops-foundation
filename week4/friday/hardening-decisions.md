# KijaniKiosk Hardening Decisions: Executive Report

## Introduction
Nia, this document outlines the strategic security decisions made during the construction of the KijaniKiosk infrastructure pipeline. Our goal was to move away from "tribal knowledge" and toward a fully auditable, automated system.

## The Security Control Table
| Control | What it does | Risk Mitigated |
| :--- | :--- | :--- |
| **Modular Server Blueprints** | Uses a single template for all three servers. | Prevents "Configuration Drift" where one server is less secure than others. |
| **Remote State Encryption** | Stores the system's "map" in a secure vault. | Prevents unauthorized users from seeing our network layout. |
| **Least Privilege Accounts** | The app runs as a restricted user (`kk-payments`). | Prevents a hacked app from taking over the entire server. |
| **Automated Log Rotation** | Periodically archives and cleans up system records. | Prevents system crashes from running out of storage. |
| **Strict System Guardrails** | Makes core OS files read-only for the application. | Prevents viruses from modifying the server software. |
| **Digital Border Control** | Only allows traffic on ports 22 and 80. | Blocks entry points for automated hacking bots. |
| **Identity-Based Access** | Uses unique SSH keys rather than passwords. | Makes password-guessing attacks impossible. |
| **Deterministic Deployment** | Ensures testing and production are identical. | Eliminates human error during server setup. |

## Conclusion
This infrastructure provides a high level of defense-in-depth. However, it is important to note that this does not protect against flaws in the application code itself.
