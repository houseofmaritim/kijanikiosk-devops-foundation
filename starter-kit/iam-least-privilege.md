# Design a role or policy for a specific application task

```

IAM — Identity and Access Management

Answers
Who are you?,
What are you allowed to do?,
What are you NOT allowed to do?

Users - A User is an individual person with their own login credentials
Roles - A Role is an identity given to an application or service — not a human
Policies - A Policy is a document that defines exactly what is allowed or denied

Least Privilege - Give every user or application only the minimum permissions needed to do their job nothing more.

```


# Why IAM Matters for KijaniKiosk

```
App gets hacked

Without IAM — attacker accesses everything: databases, files, all customer data
With IAM — attacker can only access what that one app was allowed to touch


Developer makes a mistake

Without IAM — could accidentally delete the entire database
With IAM — can only affect what their role permits


New team member joins

Without IAM — has access to everything from day one
With IAM — gets only the permissions their role requires
```