# ticket-env-platform

Ticket-driven Azure test environments, run by hand with plain Terraform commands.
One tfvars file per ticket, one state blob per ticket.

## Layout
- root (main.tf, variable.tf, output.tf): wires the modules and holds the ticket guard
- modules/Ticket-module: resource group and tags (once per ticket)
- modules/NW-NSG: VNet, subnet, NSG and catalog-driven service rules (once per ticket)
- modules/VM: VM, NIC, public IP and the management rule (once per VM)
- tickets/: one tfvars per ticket (real ones are gitignored)

## First-time setup
1. Copy backend.tf.example to backend.tf and set your backend resource group.
2. Put your real office IPs in `office_ips` in variable.tf (the default is a dummy address).
3. Edit the allowed regions list in variable.tf (validation on `ticket.location`).

## Daily use (PowerShell, project root)
    $env:ARM_ACCESS_KEY = "<storage key>"      # this terminal only, never in a file
    $t = "296108"                              # set once, use everywhere below
    terraform init -reconfigure "-backend-config=key=$t.tfstate"
    terraform validate
    terraform plan  "-var-file=tickets/$t.tfvars"
    terraform apply "-var-file=tickets/$t.tfvars"
    terraform output
    terraform destroy "-var-file=tickets/$t.tfvars"

Switching ticket = new `$t` and a new `init -reconfigure`. Never use `-migrate-state`.
Add a VM = add a block under `vms`. Remove a VM = delete its block; the plan must show only that VM's
4 resources (public IP, NIC, VM, rule) being destroyed.

## Naming
Lowercase `<type>-<ticket>-<vm role>`: vm-111111-web, nic-111111-web, pip-111111-web, allow-mgmt-111111-web.
Shared: vnet-111111, snet-111111, nsg-111111. Resource group stays `Ticket-111111`.
The `vms` key is the role only (web, db), never the ticket number. It is also the Windows computer name.
Names cannot change in place: renaming after a ticket is deployed rebuilds it.

## Ticket guard (wrong file or wrong state)
On first apply the state records the ticket id and region (terraform_data.ticket_binding). Afterwards:
- a tfvars file with a different `ticket.id` than the state fails the plan
- a different `ticket.location` fails the plan (a region cannot be moved)
This stops "right state, wrong file" from silently destroying a deployment. It cannot protect against
a brand-new empty state key for a ticket that already exists in Azure: that fails with "already exists".

## Region down or no capacity
- Regions are an allowlist in variable.tf (lowercase). A new ticket can pick any allowed region.
- An existing ticket cannot change region. If its region is down, wait and re-run plan or destroy later,
  or destroy it and create the ticket again in another region.
- A failed apply is safe to re-run; it continues from the saved state.
- Check size availability first: az vm list-skus -l <region> --size Standard_D2as_v5 -o table

## Expected plan sizes
- Base only (no VMs, access = []): 7 (RG, VNet, subnet, NSG, association, plus 2 guard records)
- Each service in `access`: +1 rule
- Each VM: +4 (public IP, NIC, VM, management rule)
- sample-111111 (https, web, db): 16

## Adding a new resource type (storage, app service, AKS)
1. New folder modules/<name> with main.tf, variable.tf, output.tf.
2. Inputs: ticket id, resource group name, location (from module.RG), plus its own settings.
3. A map for it in the ticket file (empty by default), a variable in root, a module call with `for_each`.
4. Names include the map key. Add one resource type at a time and check the plan shows only the new resources.

## Known gaps
- Windows image SKU `win11-26h2-pro` is not verified:
  az vm image list-skus -l centralindia -p MicrosoftWindowsDesktop -f Windows-11 -o table
- Management rule destination is "*": on a shared subnet one VM's rule also opens its port to the other VMs.
- Backend uses the storage key for now. With AD approval: delete ARM_ACCESS_KEY, add `use_azuread_auth = true`
  to the backend block, give your group Storage Blob Data Contributor.
- Not built: Git, CI/CD, destroy by deleting a file, weekly sweep, multi-subscription slices.
