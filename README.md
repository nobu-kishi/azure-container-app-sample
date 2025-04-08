

```bash
az account show --output table

az role assignment list --assignee "1624f63f-365c-46c9-bdbe-2275820a3f30" --scope /subscriptions/b17158f1-9101-4ce3-9224-19e1561bbd4b --output table
Principal                                             Role    Scope
----------------------------------------------------  ------  ---------------------------------------------------
shore.tf_gmail.com#EXT#@shoretfgmail.onmicrosoft.com  Owner   /subscriptions/b17158f1-9101-4ce3-9224-19e1561bbd4b
```