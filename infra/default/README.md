## Example Usage

## Single Module

```
source ../../../.env
```

```
$ cd ../default/modules
$ ansible-playbook groundedness.yml -vv --extra-vars "@../my_vars.yml"

$ ansible-playbook front_door_and_dns_timmyreillycom.yml -vv --extra-vars "@../my_vars.yml"
```


# From Dev Machine: 
Verify Environment
```
$ ansible-playbook check-env-param
```


Create Instrastructure and verify
```
$ ansible-playbook default/build_infrastructure.yml -vv --extra-vars "@default/extra_vars.yml"

ansible-playbook default/build_infrastructure.yml -vv --extra-vars "@default/my_vars.yml"

```
or wire it your own way

```
$ ansible-playbook default/build_infrastructure.yml -vv --extra-vars '{"resource_group_name":"tim-rg-d", "vnet_name":"vnet-d", "subnet_address_spaces":"[\"10.191.1.0/24\",\"10.191.2.0/24\"]", "location":"westus", "module_id":"", "vnet_address_space":"[\"10.191.0.0/16\"]" }'
```

Upgrade Existing Network

```
$ ansible-playbook default/build_infrastructure.yml -vv --extra-vars '{"resource_group_name":"tim-rg-d", "vnet_name":"vnet-d", "subnet_address_spaces":"[\"10.191.1.0/24\",\"10.191.2.0/24\"]", "location":"westus", "module_id":""EXISTING_MODULE_ID"", "vnet_address_space":"[\"10.191.0.0/16\"]" }'
```