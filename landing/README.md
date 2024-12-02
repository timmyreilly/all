# timmyreilly.com landing page deployment



# Ansible

## Deploy Landing Page 
```
cd ./infra/default/modules

source ../../../.env
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID

ansible-playbook deploy_landing.yml -vv --extra-vars "@../my_vars.yml"

```