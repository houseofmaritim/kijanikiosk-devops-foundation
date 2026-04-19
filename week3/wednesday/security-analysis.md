# Security Analysis: kk-api.service

## systemd-analyze security scores

| Stage | Score |
|-------|-------|
| Baseline (no hardening directives) | 4.0 |
| After adding all directives | 1.4 |
| Final score (after removing MemoryDenyWriteExecute) | 1.4 |

## Directives Added and Their Effect

### SystemCallFilter=@system-service
Restricts the kernel syscalls the process can invoke to only those needed
for a typical service. At the kernel level this uses seccomp-bpf to intercept
every syscall and reject ones not on the allowlist before they execute. This
blocks syscalls used in exploitation techniques like ret2libc attacks that
pivot into ptrace or mmap to inject shellcode.

### RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
Limits which socket families the process can create. Even if an attacker
achieves code execution inside the service, they cannot open raw sockets
(AF_PACKET) or netlink sockets (AF_NETLINK) which are commonly used for
network reconnaissance and privilege escalation via kernel interfaces.

### LockPersonality=true
Prevents the process from changing its execution domain via the personality()
syscall. Attackers can use execution domain switching to bypass ASLR on
32-bit compatibility layers or to confuse security tooling that tracks
process behavior by domain.

### ProtectProc=invisible
Mounts /proc so the service can only see its own processes. Without this,
a compromised service can read /proc/<pid>/environ of other processes,
leaking environment variables including secrets and tokens from other
services running on the same host.

### RestrictNamespaces=true
Prevents the service from creating any new Linux namespaces. Namespace
creation is a key primitive in container escape techniques — an attacker
who can create a user namespace can often escalate to root within it.

### SystemCallArchitectures=native
Prevents the service from executing syscalls using a different ABI
(e.g. 32-bit syscalls on a 64-bit system). Mixed-ABI syscall confusion
has been used to bypass seccomp filters that only check one ABI.

## Directives Investigated but Rejected

### MemoryDenyWriteExecute=true
**What it prevents:** Blocks creation of memory regions that are both
writable and executable. This defeats JIT spray attacks where an attacker
writes shellcode into a JIT-compiled buffer and redirects execution into it.

**Why rejected:** Node.js uses a JIT compiler (V8) that requires writable
and executable memory pages to function. With this directive enabled,
kk-api.service crashed immediately on startup with a SIGTRAP core dump.
The service cannot run with this directive. A non-JIT runtime would not
have this constraint.

### PrivateNetwork=true
**What it prevents:** Gives the service a completely isolated network
namespace with no network access whatsoever.

**Why rejected:** kk-api is an API server that must accept incoming
connections on port 3000 and connect to the database. PrivateNetwork=true
would make the service entirely unreachable, which defeats its purpose.
RestrictAddressFamilies= is used instead to limit which socket types
can be created without removing network access entirely.
