## About This Repository
This project is an effort to streamline installing commonly-used development tools on a macOS workstation without making too many assumptions about the needs of specific developers. Pull requests welcome!

### Set Up Your macOS Laptop or Desktop
```
curl --silent https://raw.githubusercontent.com/smartb-energy/workstation/master/setup.sh?a=$(date +%s) |  bash
```
Alternatively, you can create a shell function to make it easier to perform an setup update any time you want:
```
echo '
setup () 
{ 
    curl --silent "https://raw.githubusercontent.com/smartb-energy/workstation/master/setup.sh?a=$(date +%s)" | bash
}' >> ~/.bash_profile
```
