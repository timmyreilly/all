echo "================================================================================"
echo "Installing Azure CLI"
echo "================================================================================"
if ! command -v az &> /dev/null
then
    echo "az could not be found"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
fi

echo "================================================================================"
echo "Installing Ansible"
echo "================================================================================"
sudo apt install -y software-properties-common libssl-dev libffi-dev 
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

echo "================================================================================"
echo "Using Ansible to perform remaining configuration"
echo "================================================================================"
ansible-galaxy install -r requirements.yml
sudo ansible-playbook ubuntu_setup.yml -vvv