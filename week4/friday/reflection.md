## Reflection

**1. At what point did two requirements conflict, and what did you learn?**

The conflict appeared between Requirement 2 (ProtectSystem=strict on 
kk-payments) and Requirement 4 (Ansible writing the EnvironmentFile for 
that service). ProtectSystem=strict makes /etc read-only for the service 
process. The first instinct was to place the environment file under /etc/, 
which is the conventional location — but the service would silently fail 
to read it at runtime because strict mode blocks that path. The fix was 
to place the EnvironmentFile under /opt/kijanikiosk/config/, which is 
explicitly listed in ReadWritePaths. The lesson: hardening directives do 
not just affect attackers, they affect your own automation. Every 
restriction has to be tested end-to-end, not just verified in isolation.

**2. Rewrite one sentence from the hardening document for Tendo instead of Nia.**

Original (for Nia): "The payments service can only write to its designated 
directory, so a compromised service cannot modify system files or other 
services' configuration."

Rewritten (for Tendo): "ProtectSystem=strict mounts /usr, /boot, and /etc 
read-only in the service's mount namespace, and ReadWritePaths=/opt/kijanikiosk 
carves out the single writable exception — limiting post-exploitation lateral 
movement to that subtree."

What is lost in the Tendo version: a non-engineer cannot picture what 
"mount namespace" or "subtree" means, so the risk does not land emotionally. 
What is gained: Tendo can verify the claim by reading the unit file directly, 
and the exact directive names remove any ambiguity about what is actually 
configured.

**3. What is the single most fragile handoff in the pipeline?**

The handoff between Terraform outputting IPs and Ansible using them. 
pipeline.sh extracts the IPs immediately after terraform apply returns, 
but GCP VMs are not SSH-ready at the moment the API reports them as 
running — the boot sequence (cloud-init, sshd startup) takes another 
30 to 90 seconds. The wait_for_ssh loop in pipeline.sh handles this in 
the test environment, but in a production environment with a different 
base image, a slower machine type, or a custom startup script, the 
timeout could be too short or the SSH port could be non-standard. To 
make this handoff robust I would need to know: the expected cloud-init 
completion time for the target image, whether a custom startup script 
runs before sshd, and whether port 22 is the actual SSH port or whether 
it has been changed by a prior hardening baseline.
