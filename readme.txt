
OctoSAM octo-collect - a web based collection service for OctoSAM Inventory .scan files

Installing octo-collect
=======================

NOTE: this is a sample configuration to get the server running with minimal effort.
Your organization may have different requirements and rules for adding repositories 
to package managers and for running web servers in your network. 

For example, most organizations require https and have policies for certificate handling.
This is outside the scope of this example configuration.
Please consult the openresty / nginx documentation for further information on how to
setup a secure environment.


Installing octo-collect on Windows (for testing only)
=====================================================

NOTE: while it is possible to run openresty on windows using a service wrapper,
we do not recommend this configuration. 
Configuration of openresty as a service under Windows is outside the scope of this example.


- download openresty from http://openresty.org/en/download.html extract the .zip archive to your harddrive

- create an additional directory where you want to store your configuration, for example

    mkdir c:\tools\octo_collect\conf\lua

- copy nginx.conf to c:\tools\octo_collect\conf
- copy octo-collect.lua to c:\tools\octo_collect\conf\lua

- start openresty pointing to your configuration directory (prefix option)

    C:\tools\openresty-1.13.6.2-win64>nginx -p c:\tools\octo_collect

- stop openresty

    C:\scan>taskkill /IM nginx.exe /F


Testing the service
-------------------
    
    C:\Users\Erwin>curl http://localhost:8080
    OctoSAM octo_collect upload server running - 2019-05-06 13:24:06

    C:\scan>curl -F "upload=@7e0dcde6-2282-4024-8c76-0c8df59f4911.scan" http://localhost:8080
    7e0dcde6-2282-4024-8c76-0c8df59f4911.scan thank you!


Octoscan2 configuration for this example:
-----------------------------------------

    UploadInsecure = true
    UploadPlainHttp = true
    UploadHosts = localhost
    UploadPort = 8080
    UploadUrl = /upload/



Installing octo-collect on ubuntu:
==================================

- add the openresty repository to your package manager

    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -

    sudo apt-get -y install software-properties-common

    sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"

- update the package list

    sudo apt-get update

- install openresty

    sudo apt-get install openresty

#
# openresty should be installed an running now, connect with your browser, you should see the openresty start package
#

- use systemctl to start/stop the service

    sudo systemctl stop openresty
    sudo systemctl start openresty


- copy octo-collect.lua     to  /usr/local/openresty/nginx/conf/lua         (you may have to create the lua directory)

- edit nginx.conf to add a location to the server where the octo-collect service should be located:

    location /upload/ {
            client_max_body_size 200M;
            #
            # configure path where the collect module should store uploaded .scan files
            # this directory must exist and must be writable
            # don't forget the trailing slash
            #
            set $octo_collect_store_path "/tmp/";

            # call the octo_collect handler
            content_by_lua_file conf/lua/octo_collect.lua;
        }



Testing the service
-------------------

    curl http://localhost/upload/
    OctoSAM octo_collect upload server running - 2019-05-06 10:36:03

    curl -F "upload=@506fd54d-834c-429a-b018-eed77a888906.scan" http://<your-hostname-or-ip-address>/upload/
    506fd54d-834c-429a-b018-eed77a888906.scan thank you!


Octoscan2 configuration for this example:
-----------------------------------------

UploadInsecure = true
UploadPlainHttp = true
UploadHosts = <your-hostname-or-ip-address>
UploadPort = 80
UploadUrl = /upload/



