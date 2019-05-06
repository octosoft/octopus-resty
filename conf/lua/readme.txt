

Installing octo-collect on ubuntu:
==================================

NOTE: this is a sample configuration to get the server running with minimal effort
Your organizations rules for adding repositories to your package manager and for
running web servers in your network may have differentrequirements. 
Check with your network admins and security people.
Consult the openresty / nginx documentation for additional configuration
options.

# 
# install openresty:
# ------------------
#

# add the openresty repository to your package manager

wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -

sudo apt-get -y install software-properties-common

sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"

# update the package list

sudo apt-get update

# install openresty

sudo apt-get install openresty

#
#
# openresty should be installed an running now, connect with your browser, you should see the openresty start package
#
# use systemctl to start/stop the service
#

sudo systemctl stop openresty
sudo systemctl start openresty


# your default configuration is under
/usr/local/openresty/nginx/conf

#
# default configuration for octo-collect:
# copy octo-collect.lua     to  /usr/local/openresty/nginx/conf/lua         (you may have to create the lua directory)
#

# add a location to the server where the octo-collect service should be located:

    location /upload/ {
            client_max_body_size 200M;
            #
            # configure path where the collect module should store uploaded .scan files
            # this directory must exist and must be writable
            # don't forget the trailing slash
            #
            set $octo_collect_store_path "/tmp/";

            # call the ocot_collect handler
            content_by_lua_file conf/lua/octo_collect.lua;
        }


#
# test the service:
#

curl http://localhost/upload/
OctoSAM octo_collect upload server running - 2019-05-06 10:36:03

C:\scan>curl -F "upload=@506fd54d-834c-429a-b018-eed77a888906.scan" http://10.0.0.112/upload/
506fd54d-834c-429a-b018-eed77a888906.scan thank you!


# Octoscan2 configuration for this example:
UploadInsecure = true
UploadPlainHttp = true
UploadHosts = 10.0.0.112
UploadPort = 80
UploadUrl = /upload/



