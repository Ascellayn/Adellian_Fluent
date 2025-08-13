#!/bin/bash
cd /home/ascellayn/Workspace/GitHub/Adellian_Fluent
./parse-sass.sh
./install.sh
GTK_DEBUG=interactive thunar
#GTK_DEBUG=interactive awf-gtk3
